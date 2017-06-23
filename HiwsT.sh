#!/bin/bash

# Installation apache2, php, rtorrent, rutorrent, WebMin
# testée sur ubuntu et debian server vps Ovh
# et sur kimsufi. A tester sur autres hébergeurs
# https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-


##################################################
#     variables install paquets Ubuntu/Debian
##################################################
#  Debian
# liste sans serveur http
paquetsWebD="mc aptitude autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php5 php5-cli php5-dev php5-fpm php5-curl php5-geoip php5-mcrypt php5-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoD="xmlrpc-api-utils libtorrent14 rtorrent"

sourceMediaD="deb http://www.deb-multimedia.org jessie main non-free"
paquetsMediaD="mediainfo ffmpeg"

# Ubuntu
# liste sans serveur http
paquetsWebU="mc aptitude autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php7.0 php7.0-cli php7.0-dev php7.0-fpm php7.0-curl php-geoip php7.0-mcrypt php7.0-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoU="xmlrpc-api-utils libtorrent19 rtorrent"

paquetsMediaU="mediainfo ffmpeg"

#------------------------------------------------------------------------------
readonly HOSTNAME=$(hostname -f)
readonly REPWEB="/var/www/html"
readonly REPAPA2="/etc/apache2"
readonly REPLANCE=$(echo `pwd`)
REPUL=""    # repertoire user Linux dans __creauser
readonly PORT_SCGI=5000  # port 1er Utilisateur
readonly PLANCHER=20001  # bas fourchette port ssh
readonly ECHELLE=65534  # ht de la fourchette
readonly miniDispoRoot=334495744   # 319 Go minimum pour alerete place \
readonly miniDispoHome=313524224   # 299 Go disponible sur disque
readonly serveurHttp="apache2"
# dialog param --backtitle --aspect --colors
readonly TITRE="HiwsT : Installation rtorrent - ruTorrent"
readonly RATIO=12
readonly R="\Z1"
readonly BK="\Z0"  # black
readonly G="\Z2"
readonly Y="\Z3"
readonly BL="\Z4"  # blue
readonly W="\Z7"
readonly BO="\Zb"  # bold
readonly I="\Zr"   # vidéo inversée
readonly N="\Zn"   # retour à la normale

######################################
#       Fonctions utilitaires
######################################

__trap() {  # pour exit supprime NOPASSWD et info.php
	if [ -e $REPWEB/info.php ]; then rm $REPWEB/info.php; fi
}

__ouinonBox() {    # param : titre, texte  sortie $__ouinonBox oui : 0 ou non : 1
	CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}"  --yesno "
${2}" 0 0 )
	choix=$("${CMD[@]}" 2>&1 >/dev/tty)
	__ouinonBox=$?
}    #  fin ouinon

__messageBox() {   # param : titre texte
			CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --msgbox "${2}" 0 0)
			choix=$("${CMD[@]}" 2>&1 >/dev/tty)
}

__infoBox() {   # param : titre sleep texte
			CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --sleep ${2} --infobox "${3}" 0 0)
			choix=$("${CMD[@]}" 2>&1 >/dev/tty)
}

__msgErreurBox() {
	__messageBox "$R Message d'erreur $N" "

`cat /tmp/hiwst.log`
	$R
Consulter le wiki sur github $N
https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal

Le message d'erreur est enregistré dans $I/tmp/trace$N"
	__ouinonBox "Erreur" "
Voulez-vous continuer malgré tout ?"
	if [[ $__ouinonBox -ne 0 ]]; then exit 1; fi
}  # fin messageErreur

__saisieTexteBox() {   # param : titre, texte
	until [[ 1 -eq 2 ]]; do
		CMD=(dialog --aspect $RATIO --colors --nocancel --backtitle "$TITRE" --title "${1}" --max-input 15 --inputbox "${2}" 0 0)
		__saisieTexteBox=$("${CMD[@]}" 2>&1 >/dev/tty)
		if [ $? == 1 ]; then return 1; fi
		if [[ "$__saisieTexteBox" =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
			__saisieTexteBox=$(echo $__saisieTexteBox | tr '[:upper:]' '[:lower:]')
			break
		else
			__infoBox "Vérification saisie" 3 "
Uniquement des caractères alphanumériques
Entre 2 et 15 caractères"
		fi
	done
}

__saisiePwBox() {  # param : titre, texte, nbr de ligne sous boite
  local pw=1""; local pw2=""; local codeSortie=""; local reponse=""
	until [[ 1 -eq 2 ]]; do
		CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --insecure --nocancel --passwordform "${2}" 0 0 ${3} "Mot de passe : " 2 4 "" 2 25 25 25 "Resaisissez : " 4 4 "" 4 25 25 25 )
		reponse=$("${CMD[@]}" 2>&1 >/dev/tty)
		if [[ "$reponse" =~ .*[[:space:]].*[[:space:]].* ]] || \
		[[ "$reponse" =~ [\\] ]]; then
      __infoBox "${1}" 2 "
Le mot de passe ne peut pas contenir d'espace ou de \\."
    else
	    pw1=$(echo $reponse | awk -F" " '{ print $1 }')
	    pw2=$(echo $reponse | awk -F" " '{ print $2 }')
			case $pw1 in
				"" )
					__infoBox "${1}" 2 "
Le mot de passe ne peut pas être vide."
				;;
				$pw2 )
					__saisiePwBox=$pw1
					break
				;;
				* )
					__infoBox "${1}" 2 "
Les 2 saisies ne sont pas identiques."
				;;
			esac
		fi
	done
}

__textBox() {   # $1 titre  $2 fichier à lire  $3 texte baseline
  CMD=(dialog --backtitle "$TITRE" --exit-label "Suite de l'installation" --title "${1}" --hline "${3}" --textbox  "${2}" 0 0)
	("${CMD[@]}" 2>&1 >/dev/tty)
}

__cmd() {
  local msgErreur
  $*
  err=$?
  if [[ $err -ne 0 ]]; then
    msgErreur="$BO$R$*$N \nerreur N° $R$err$N"
		echo "------------------" >> /tmp/hiwst.log
    echo -e $msgErreur" " >> /tmp/hiwst.log
		tail --lines=16 /tmp/trace >> /tmp/hiwst.log
    echo "------------------" >> /tmp/hiwst.log
    tail --lines=16 /tmp/trace
		__msgErreurBox
		:>/tmp/hiwst.log  # ràz
    return 1
  else
		:>/tmp/hiwst.log
    return 0
  fi
}
__serviceapache2restart() {
	service apache2 restart
	__cmd "service apache2 status"
}   #  fin __serviceapache2restart()


###############################################################
#                Début du script                              #
###############################################################

# root ?

if [[ $(id -u) -ne 0 ]]; then
	echo
	echo "Ce script nécessite d'être exécuté avec sudo."
	echo
	exit 1
fi
clear

#########################################
## localisation et infos système        #
#########################################

# Complèter la localisation (vps)
lang=$(cat /etc/locale.gen | egrep ^[a-z].*UTF-8$ | awk -F" " '{print $1 }')
export LANGUAGE=$lang
export LANG=$lang
export LC_ALL=$lang
update-locale LANGUAGE=$lang
update-locale LANG=$lang
update-locale LC_ALL=$lang
dpkg-reconfigure --frontend=noninteractive locales
locale-gen

# installe dialog si pas installé
apt-get update
which dialog &>/dev/null
if [ $? -ne 0 ]; then
	apt-get install -yq dialog
fi
# installe lsb_release si pas installé
which lsb_release &>/dev/null
if [ $? -ne 0 ]; then
	apt-get install -yq lsb-release
fi
# installe sudo si pas installé
which sudo &>/dev/null
if [ $? -ne 0 ]; then
	apt-get install -yq sudo
fi


arch=$(uname -m)
interface=ifconfig | grep "Ethernet" | awk -F" " '{ print $1 }'
# pas tjs eth0 ... ou interface=$(ip -o -4 addr | grep $IP | awk '{print $2}')
# ou ip -o -4 link | grep ether (ou BROADCAST)
# 2: eth0: <BROADCAST,MULTI ... link/ether fa:1 ...
readonly IP=$(ifconfig $interface 2>/dev/null | grep 'inet ad' | awk -F: '{ printf $2 }' | awk '{ printf $1 }')
distrib=$(cat /etc/issue | awk -F"\\" '{ print $1 }')
nameDistrib=$(lsb_release -si)  # Debian ou Ubuntu
os_version=$(lsb_release -sr)   # 18 , 8.041 ...
os_version_M=$(echo $os_version | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')  # version majeur
description=$(lsb_release -sd)     #  nom de code
user=$(id -un)       #  root avec user sudo

# espace dispo
homeDispo=$(df | grep /home | awk -F" " '{ print $4 }')
rootDispo=$(df | grep  /$ | awk -F" " '{ print $4 }')
if [ -z "$homeDispo" ]; then
	info="Vous n'avez pas de partition /home"
else
  info="Votre partition /home a $(( $homeDispo/1024/1024 )) Go de libre."
fi

# portSSH aléatoire
RANDOM=$$  # N° processus du script
portSSH=0   #   initialise 20000 65535
while [ $portSSH -le $PLANCHER ]; do
  portSSH=$RANDOM
  let "portSSH %= $ECHELLE"  # Ramène $portSSH dans $ECHELLE.
done

# ubuntu / debian et bonne version ?

if [ $nameDistrib == "Debian" -a $os_version_M -gt 8 -o $nameDistrib == "Ubuntu" -a $os_version_M -gt 16 ]; then
	__ouinonBox "Vérification distribution" "
	Vous utilisez $description
	Ce script est prévu pour fonctionner sur un serveur Debian 8.xx ou Ubuntu 16.xx
	Vous risquez d'avoir des problèmes de version à l'installation
	Voulez-vous continuer ?"
	if [[ $__ouinonBox -ne 0 ]]; then	exit 1; fi
fi

if [ $nameDistrib == "Debian" -a $os_version_M -lt 8 -o $nameDistrib == "Ubuntu" -a $os_version_M -lt 16 ]; then
	__messageBox "Vérification distribution" "

	Vous utilisez $description
	Ce script fonctionne sur un serveur Debian 8.xx ou Ubuntu 16.xx"
	exit 1
fi

if [ $nameDistrib != "Debian" -a $nameDistrib != "Ubuntu" ]; then
	__messageBox "Vérification distribution" "

	Vous utilisez $description
	Ce script fonctionne sur un serveur Debian 8.xx ou Ubuntu 16.xx"
	exit 1
fi

# Vérif serveur hhtp
service apache2 restart &> /dev/null
service nginx restart &> /dev/null
service apache2 status &> /dev/null; serveurHttpA=$?
service nginx status &> /dev/null; serveurHttpN=$?
service apache2 stop &> /dev/null
service nginx stop &> /dev/null

if [[ $serveurHttpN -eq 0 ]] && [[ $serveurHttpA -eq 0 ]]; then
	__ouinonBox "Serveur http" "
Vous avez apache2$BO ET$N nginx d'installés !?
Si vous continuez ce script, la configuration existante va être remplacée par celle du script (apache2)"
	if [[ $__ouinonBox -eq 1 ]]; then exit 1; fi
elif [[ $serveurHttpA -eq 0 ]]; then
	__ouinonBox "Serveur http" "
Vous avez apache2 d'installer,
Si vous continuez ce script, la configuration existante va être remplacée par celle du script"
	if [[ $__ouinonBox -eq 1 ]]; then exit 1; fi
elif [[ $serveurHttpN -eq 0 ]]; then
	__ouinonBox "Serveur http" "
Vous avez nginx d'installer,
Si vous continuez ce script, la configuration existante va être remplacée par celle du script (apache2)"
	if [[ $__ouinonBox -eq 1 ]]; then exit 1; fi
fi
#--------------------------------------------------------------


#############################
#    Partie interactive
#    ID, PW, questions
#############################

__messageBox "$R Avertissement $N" "

                              									$I ATTENTION !!! $N

 L'utilisation de ce script doit se faire sur un serveur, tel que livré par votre hébergeur.

$R Une installation quelconque risque d'être endommagée par ce script !!!
 Ne jamais exécuter ce script sur un serveur en production."

__messageBox "Votre système" " $BO

Distribution :$N $description $BO
Architecture :$N $arch $BO
Votre IP     :$N $IP $BO
Le script tourne sous :$N $user
$BO
Durée du script :$N environ 10mn

Place disponible sur les partitions du disques$BO
Votre partition root (/) a $(( $rootDispo/1024/1024 )) Go de libre.
$info"  # $info valeur suivant $homeDispo cf. # espace dispo

if [ -z "$homeDispo" ]; then  # /
 	if [ $rootDispo -lt $miniDispoRoot ]; then
		__infoBox "Avertissement" 4 "
$BO $R
ATTENTION $N

Seulement $R$(( $rootDispo/1024/1024 )) Go$N, sur / pour stocker les fichiers téléchargés"
	fi
else  # /home
 	if [ $homeDispo -lt $miniDispoHome ];then
		__infoBox "Avertissement" 4 "
$BO $R
ATTENTION $N

Seulement $R$(( $homeDispo/1024/1024 )) Go$N, sur /home pour stocker les fichiers téléchargés"
	fi
fi

# utilisateur linux
__saisieTexteBox "Utilisateur Linux" "
Vous devez créer un utilisateur spécifique
Choisir un nom d'utilisateur linux$R
(ni espace ni \)$N : "
userLinux=$__saisieTexteBox
egrep "^$userLinux:" /etc/passwd >/dev/null
if [[ $? -eq 0 ]]; then
	__infoBox "Utilisateur Linux" 3 "
$userLinux existe déjà, choisir un autre nom"
else
	__saisiePwBox "Utilisateur Linux" "
Mot de passe pour l'utilisateur $userLinux :" 4
	pwLinux=$__saisiePwBox
fi
# Rutorrent user
__saisieTexteBox "Utilisateur ruTorrent" "

Il est préférable de choisir un nom différent de celui de
l'utilisateur Linux
Choisir un nom d'utilisateur ruTorrent$R (ni espace ni \)$N : "
userRuto=$__saisieTexteBox
__saisiePwBox "Utilisateur ruTorrent" "
Mot de passe pour l'utilisateur $userRuto :" 4
pwRuto=$__saisiePwBox

#  webmin
__ouinonBox "Webmin" "
Souhaitez-vous installer Webmin ?"
installWebMin=$__ouinonBox

# port ssh
__ouinonBox "Sécurisation ssh/sftp" "
Dans le but de sécuriser SSH et SFTP il est proposé de changer le port standard (22) et d'interdire root.
 $R
C'est une mesure de sécurité fortement recommandée.$N

L'utilisateur sera $userLinux et le port aléatoire $portSSH$BO ou un port désigné par vous.$N
Souhaitez-vous appliquer cette modification ?"
changePort=$__ouinonBox
if [ $changePort -eq 0 ]; then
	choix=0
	until [ $choix -le $ECHELLE -a $choix -ge $PLANCHER ]; do
	  CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "Port ssh/sftp" --max-input 5 --nocancel --inputbox "
Le port aléatoire proposé est $I$portSSH$N $BO
Vous pouvez le modifier entre $PLANCHER et $ECHELLE$N" 0 0 $portSSH)
	  choix=$("${CMD[@]}" 2>&1 >/dev/tty)
	done
	portSSH=$choix
	userSSH=$userLinux
else
	portSSH=22
	userSSH="root"
fi


#  Récapitulatif
cat << EOF > $REPUL/RecapInstall.txt

Ces informations seront utilisables seulement après la bonne exécution du script.

Distribution    : $description
Architecture    : $arch
Votre IP        : $IP
Votre host name : $HOSTNAME

`if [ -z "$homeDispo" ]
then
	echo "Vous n'avez pas de partition /home."
else
	echo "Votre partition /home a $(( $homeDispo/1024/1024 )) Go de libre."
fi`
Votre partition root (/) a $(( $rootDispo/1024/1024 )) Go de libre.
Votre serveur http est $serveurHttp

Nom de votre utilisateur accès SSH et SFTP : $userSSH
Port pour SSh : $portSSH

Nom de votre utilisateur Linux : $userLinux

Nom de votre utilisateur ruTorrent          : $userRuto
Mot de passe de votre utilisateur ruTorrent : $pwRuto

`if [[ $installWebMin -ne 0 ]]
then
	echo "Vous ne souhaitez pas installer WebMin"
else
	echo "Vous souhaitez installer WebMin"
	echo "L'utilisateur sera "root" avec son mot de passe"
fi`
EOF

__textBox "Récapitulatif de  l'installation" $REPUL/RecapInstall.txt
__ouinonBox "Installation" "Voulez-vous commencer l'installation ?"
if [ $__ouinonBox -ne 0 ]; then exit 0; fi


############################################
#            Début de la fin
############################################

clear
## gestion des erreurs stderr par __cmd()
:>/tmp/trace
:>/tmp/hiwst.log
exec 2>/tmp/trace
echo
echo
echo
echo "*************************************************"
echo "|                 Installation                  |"
echo "*************************************************"
echo
echo
echo
echo "***********************************************"
echo "|              Update système                 |"
echo "|     Configuration de l'utilisateur linux    |"
echo "|          Installation des paquets           |"
echo "***********************************************"
sleep 1
echo

# upgrade
__cmd "apt-get update -yq"
__cmd "apt-get upgrade -yq"
echo "****************************"
echo "|  Mise à jour effectuée   |"
echo "****************************"
sleep 1

##############################
#  Création de linux user    #
##############################
pwCrypt=$(perl -e 'print crypt($ARGV[0], "pwLinux")' $pwLinux)
useradd -m -G adm,dip,plugdev,www-data,sudo -p $pwCrypt $userLinux
if [[ $? -ne 0 ]]; then
	__infoBox "Utilisateur Linux" 3 "
Impossible de créer un utilisateur linux"
	exit 1
fi
sed -i "1 a\bash" /home/$userLinux/.profile  #ubuntu ok, debian ok après reboot
echo $userLinux > $REPLANCE/firstusers
readonly REPUL="/home/$userLinux"
trap "__trap" EXIT # supprime nopasswd et info.php en cas d'exit
__cmd "usermod -aG www-data $userLinux"

## config mc (installé dans apacheinstall)
# config mc user
mkdir -p $REPUL/.config/mc/
cp $REPLANCE/fichiers-conf/mc_panels.ini $REPUL/.config/mc/panels.ini
chown R $userLinux:$userLinux $REPUL/.config/
# config mc root
mkdir -p /root/.config/mc/
cp $REPLANCE/fichiers-conf/mc_panels.ini /root/.config/mc/panels.ini

echo
echo "********************************"
echo "|    Utilisateur linux créé    |"
echo "********************************"
sleep 1
echo

############################################
#      Installation du serveur http        #
############################################
	service nginx stop &> /dev/null
	. $REPLANCE/insert/apacheinstall.sh

############################################
#           installation rtorrent          #
############################################
# téléchargement rtorrent libtorrent xmlrpc
if [[ $nameDistrib == "Debian" ]]; then
	paquets=$paquetsRtoD
else
	paquets=$paquetsRtoU
fi
__cmd "apt-get install -yq $paquets"

echo
echo "****************************************"
echo "|    Paquets rtorrent et libtorrent    |"
echo "|              et xmlrpc               |"
echo "****************************************"
echo
sleep 1


# configuration rtorrent
cp $REPLANCE/fichiers-conf/rto_rtorrent.rc $REPUL/.rtorrent.rc
sed -i 's/<username>/'$userLinux'/g' $REPUL/.rtorrent.rc

mkdir -p $REPUL/downloads/watch
mkdir -p $REPUL/downloads/.session
chown -R $userLinux:$userLinux $REPUL/downloads
echo
echo "*********************************************************"
echo "|   .rtorrent.rc configuré pour l'utilisateur linux     |"
echo "*********************************************************"
sleep 1

# mettre rtorrent en deamon / screen
cp $REPLANCE/fichiers-conf/rto_rtorrent.conf /etc/init/$userLinux-rtorrent.conf
chmod u+rwx,g+rwx,o+rx  /etc/init/$userLinux-rtorrent.conf
sed -i 's/<username>/'$userLinux'/g' /etc/init/$userLinux-rtorrent.conf
#-----------------------------------------------------------------
cp $REPLANCE/fichiers-conf/rto_rtorrentd.sh /etc/init.d/rtorrentd.sh
chmod u+rwx,g+rwx,o+rx  /etc/init.d/rtorrentd.sh
sed -i 's/<username>/'$userLinux'/g' /etc/init.d/rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc4.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc5.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc6.d/K01rtorrentd.sh
systemctl daemon-reload
service rtorrentd start
#-----------------------------------------------------------------
sleep 1
sortie=`pgrep rtorrent`
if [ -n "$sortie" ]
then
	echo "*************************************************"
	echo "|  rtorrent en daemon fonctionne correctement   |"
	echo "*************************************************"
	sleep 1
else
	__cmd "ps aux | grep -e '^$userLinux.*rtorrent$'"
fi


############################################
#        installation de rutorrent         #
############################################

# création de userRuto dans apacheinstall.sh
# Modifier la configuration du site par défaut (pour rutorrent) dans apacheinstall.sh

# téléchargement
mkdir $REPWEB/source
cd $REPWEB/source
__cmd "wget https://github.com/Novik/ruTorrent/archive/master.zip"
unzip -o master.zip
mv -f ruTorrent-master $REPWEB/rutorrent
chown -R www-data:www-data $REPWEB/rutorrent

# fichier de config config.php générique ( modif dans conf/user/nonuser/)
mv $REPWEB/rutorrent/conf/config.php $REPWEB/rutorrent/conf/config.php.old
cp $REPLANCE/fichiers-conf/ruto_config.php $REPWEB/rutorrent/conf/config.php
chown -R www-data:www-data $REPWEB/rutorrent
chmod -R 755 $REPWEB/rutorrent

# modif .htaccess dans /rutorrent  le passwd paramétré dans sites-available
echo -e 'Options All -Indexes\n<Files .htaccess>\norder allow,deny\ndeny from all\n</Files>' > $REPWEB/rutorrent/.htaccess

# modif du thème de rutorrent
mkdir -p $REPWEB/rutorrent/share/users/$userRuto/torrents
mkdir $REPWEB/rutorrent/share/users/$userRuto/settings
chown -R www-data:www-data $REPWEB/rutorrent/share/users/$userRuto
chmod -R 777 $REPWEB/rutorrent/share/users/$userRuto

echo 'O:6:"rTheme":2:{s:4:"hash";s:9:"theme.dat";s:7:"current";s:8:"Oblivion";}' > $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat
chmod u+rwx,g+rx,o+rx $REPWEB/rutorrent/share/users/$userRuto
chmod 666 $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat
chown www-data:www-data $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat

echo
echo "*******************************************"
echo "|    ruTorrent installé et configuré      |"
echo "*******************************************"
sleep 1

# installation de mediainfo et ffmpeg
if [[ $nameDistrib == "Debian" ]]; then
	chmod 777 /etc/apt/sources.list
	echo $sourceMediaD >> /etc/apt/sources.list
	chmod 644 /etc/apt/sources.list
	apt-get update -yq
	__cmd "apt-get install -yq --force-yes deb-multimedia-keyring"
	apt-get update -yq
	__cmd "apt-get install -y --force-yes $paquetsMediaD"
else
	__cmd "apt-get install -yq --force-yes $paquetsMediaU"
fi
echo
echo "****************************************"
echo "|    mediainfo et ffmpeg installés     |"
echo "****************************************"
sleep 1

## plugins rutorrent
mkdir $REPWEB/rutorrent/plugins/conf

cp $REPLANCE/fichiers-conf/ruto_plugins.ini $REPWEB/rutorrent/plugins/conf/plugins.ini

# création de conf/users/userRuto en prévision du multiusers
mkdir -p $REPWEB/rutorrent/conf/users/$userRuto
cp $REPWEB/rutorrent/conf/access.ini $REPWEB/rutorrent/conf/plugins.ini $REPWEB/rutorrent/conf/users/$userRuto
cp $REPLANCE/fichiers-conf/ruto_multi_config.php $REPWEB/rutorrent/conf/users/$userRuto/config.php

sed -i -e 's/<port>/'$PORT_SCGI'/' -e 's/<username>/'$userLinux'/' $REPWEB/rutorrent/conf/users/$userRuto/config.php

chown -R www-data:www-data $REPWEB/rutorrent/conf

# Ajouter le plugin log-off

cd $REPWEB/rutorrent/plugins
__cmd "wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rutorrent-logoff/logoff-1.3.tar.gz"
tar -zxf logoff-1.3.tar.gz

# action pro Qwant
sed -i "s|\(\$logoffURL.*\)|\$logoffURL = \"https://www.qwant.com/\";|" $REPWEB/rutorrent/plugins/logoff/conf.php
sed -i "s|\(\$allowSwitch.*\)|\$allowSwitch = \"$userRuto\";|" $REPWEB/rutorrent/plugins/logoff/conf.php
echo -e "\n;;\n        [logoff]\n        enabled = yes" >> $REPWEB/rutorrent/plugins/conf/plugins.ini

chown -R www-data:www-data $REPWEB/rutorrent/plugins/logoff
echo
echo "********************************************"
echo "|       Plugins ruTorrent installés        |"
echo "********************************************"
sleep 1

headTest=`curl -Is http://$IP/rutorrent/| head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
if [[ "$headTest" == Unauthorized* ]]
then
	echo
	echo "****************************"
	echo "|  ruTorrent fonctionne    |"
	echo "****************************"
	sleep 1
else
	echo "curl -Is http://$IP/rutorrent/| head -n 1 renvoie $headTest" >> /tmp/hiwst.log
	__msgErreurBox
fi

#######################################################
#             installation de WebMin                  #
#######################################################

if [[ $installWebMin -eq 0 ]]
then
. $REPLANCE/insert/webmininstall.sh
fi   # Webmin

########################################
#            sécuriser ssh             #
########################################
#  des choses à faire de tte façon
. $REPLANCE/insert/sshsecuinstall.sh


## copie les scripts dans home
cp -r  $REPLANCE $REPUL/HiwsT
chown -R $userLinux:$userLinux $REPUL/HiwsT

## complète firstusers
echo $userRuto >> $REPUL/HiwsT/firstusers
chown root:root $REPUL/HiwsT/firstusers
chmod 400 $REPUL/HiwsT/firstusers  # r-- --- ---

## copie dans $REPUL/HiwsT les fichiers log et trace
cp -t $REPUL/HiwsT /tmp/hiwst.log /tmp/trace
rm -r $REPLANCE



########################################
#            générique de fin          #
########################################

cat << EOF > $REPUL/HiwsT/RecapInstall.txt

Votre système

	Distribution    : $description
	Architecture    : $arch
	Votre IP        : $IP
	Votre host name : $HOSTNAME

	Nom de votre utilisateur Linux : $userLinux

Pour accéder à ruTorrent :
	http(s)://$IP/rutorrent   ID : $userRuto  PW : $pwRuto
	ou http(s)://$HOSTNAME/rutorrent
	En https accepter la connexion non sécurisée et
	l'exception pour ce certificat !

`if [[ $installWebMin -eq 0 ]]; then
	echo "Pour accéder à WebMin :"
	echo -e "\thttps://$IP:10000"
	echo -e "\tou https://$HOSTNAME:10000"
	echo -e "\tID : root  PW : votre mot de passe root"
	echo -e "\tAccepter la connexion non sécurisée et"
	echo -e "\tl'exception pour ce certificat !"
	echo " "
fi`
En cas de problème concernant strictement ce script, vous pouvez aller
Consulter le wiki : https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki
et poster sur https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/issues

`if [[ $changePort -eq 0 ]]; then   # ssh sécurisé
	echo "************************************************"
	echo "|     ATTENTION le port standard et root       |"
	echo "|     n'ont plus d'accès en SSH et SFTP        |"
	echo "************************************************"
	echo
	echo "Pour accéder à votre serveur en ssh :"
	echo "Depuis linux, sur une console :"
	echo -e "\tssh -p$portSSH  $userLinux@$IP"
	echo "Depuis windows utiliser PuTTY"

	echo "Pour accéder aux fichiers via SFTP :"
	echo -e "\tHôte      : $IP (ou $HOSTNAME)"
	echo -e "\tPort      : $portSSH"
	echo -e "\tProtocole : SFTP-SSH File Transfer Peotocol"
	echo -e "\tAuthentification : normale"
	echo -e "\tIdentifiant      : $userLinux"
	echo -e "\tVotre mot de passe pour $userLinux"
else   # ssh n'est pas sécurisé
	echo "Pour accéder à votre serveur en ssh :"
	echo "Depuis linux, sur une console :"
	echo -e "\tssh root@$IP"
	echo -e "\tSur la console du serveur 'su $userLinux'"
	echo "Depuis windows utiliser PuTTY"
	echo " "
	echo "Pour accéder aux fichiers via SFTP :"
	echo -e "\tHôte      : $IP (ou $HOSTNAME)"
	echo -e "\tPort      : 22"
	echo -e "\tProtocole : SFTP-SSH File Transfer Protocol"
	echo -e "\tAuthentification : normale"
	echo -e "\tIdentifiant      : root"
fi  # ssh pas sécurisé/ sécurisé`
EOF

# efface la récap 1ère version
rm $REPUL/RecapInstall.txt
chmod 400 $REPUL/HiwsT/RecapInstall.txt
__textBox "Récapitulatif de  l'installation" $REPUL/HiwsT/RecapInstall.txt "Informations sauvegardées dans le fichier RecapInstall.txt"
__ouinonBox "Fin d'installation" "Utiliser HiwsT-util.sh pour toutes modifications
Il peut être nécessaire de rebooter pour que tout fonctionne à 100%.
Voulez-vous rebooter votre serveur maintenat ?"
if [ $__ouinonBox -eq 0 ]; then
	__ouinonBox "Fin d'installation" "Reboot :
Etes-vous sûr ?"
	if [ $__ouinonBox -eq 0 ]; then rm -r $REPLANCE; sleep 1; reboot; fi
fi
clear
echo
echo "Au revoir"
echo
rm -r $REPLANCE
