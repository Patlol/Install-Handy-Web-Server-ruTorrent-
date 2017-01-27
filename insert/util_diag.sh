
echo
lsb_release -a
echo
echo "-------------------------------------------------------------------------------"
echo "RAM : "
echo "-----"
free -h
echo
echo "-------------------------------------------------------------------------------"
echo "Disques :"
echo "---------"
df -h
echo
echo "-------------------------------------------------------------------------------"
echo "ports :"
echo "-------"
netstat -lntup
echo
echo "-------------------------------------------------------------------------------"
if [[ $serveurHttp == "apache2" ]]; then
  echo "apache2 :"
  echo "---------"
  service apache2 status
  echo
else
  echo "nginx :"
  echo "-------"
  service nginx status
  echo
fi
echo "-------------------------------------------------------------------------------"
echo "sshd :"
echo "------"
service sshd status
echo
echo "-------------------------------------------------------------------------------"
echo "rtorrentd :"
echo "-----------"
service rtorrentd status
echo
ps aux | grep '.torrent$'
echo
echo "-------------------------------------------------------------------------------"
echo "Utilisateurs :"
echo "--------------"
. $REPLANCE/insert/util_listeusers.sh