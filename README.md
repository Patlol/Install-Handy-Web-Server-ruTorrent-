# HiwsT
Handy Install a Web Server with ruTorrent --HwsT--  
_ruTorrent multiuser and Apache2_  

### We no longer offer Cakebox and nginx:
### * :warning: Cakebox is DEPRECATED :warning: <a href="https://github.com/cakebox/cakebox">see here</a> and <a href="https://github.com/cakebox/cakebox/issues/216">here</a> :warning:  

Install on Debian 8 and 9 or Ubuntu 16 server
- apache
- php
- rtorrent
 - librtorrent
 - xmlrpc
- <a href="https://github.com/Novik/ruTorrent/">ruTorrent</a> multiuser
 - mediainfo
 - ffmpeg
- <a href="http://www.webmin.com/">WebMin</a>

![COPIE D'ÉCRAN](https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/png/Capture2017-07-02_01:07:57.png) ![COPIE D'ÉCRAN](https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/png/Capture2017-07-02_01:08:15.png)
# HiwsT-util
With this utility you can  
- Create other ruTorrent users and thus share your server.  
 - Creating a linux user and a rutorrent user  
 - Security ruTorrent with password
 - Block the new user has his /home/download from rutorrent  
 - Block the new user has his /home from sftp  
 - Prohibits new user access via ssh  
- Delete user Linux / ruTorrent and its directories
- Change passwords Linux / ruTorrent
- Add a firewall (ufw)
- Add Let's Encrypt certificate
  - Takes the domain name into apache, ownCloud
  - Creates a certificate with Lets Encrypt / certbot
  - Modifies the certificate on the WebMin server
  - Adds a cron task to renew certificate
- Add a VPN (openVPN)
  - Install / uninstall
  - Creates / remove new user
- Add ownCloud ~~10.0.2~~ **10.0.3** (optionally with Audioplayer and External storage)
  - With app external storage (for torrents downloaded) and Audioplayer
- Add phpMyAdmin
- Perform a system diagnosis  

![copie d'écran](https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/png/Capture2017-07-02_01:03:30.png)

Please read <a href="https://github.com/Patlol/Install-Handy-Web-Server-ruTorrent-/wiki/Home">Wiki</a> in french  
Please read <a href="https://github.com/Patlol/Install-Handy-Web-Server-ruTorrent-/wiki/Home-en">Wiki</a> in english

Feedback is welcome. Issues and pull requests can be submitted via GitHub. Fork unrestrained
