#!/bin/bash
# Update installed apps to new reverse proxy configurations

MASTER=$(cat /srv/rutorrent/home/db/master.txt)

function _couchpotato() {
  if [[ ! -f /etc/apache2/sites-enabled/couchpotato.conf ]]; then
    service couchpotato@${MASTER} stop
    sed -i "/host = .*/d" /home/"${MASTER}"/.couchpotato/settings.conf
    sed -i "s/url_base.*/url_base = couchpotato\nhost = localhost/g" /home/"${MASTER}"/.couchpotato/settings.conf

    cat > /etc/apache2/sites-enabled/couchpotato.conf <<EOF
<Location /couchpotato>
ProxyPass http://localhost:5050/couchpotato
ProxyPassReverse http://localhost:5050/couchpotato
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${MASTER}
</Location>
EOF
    chown www-data: /etc/apache2/sites-enabled/couchpotato.conf
    service apache2 restart
  fi
}

function _jackett() {
  if [[ ! -f /etc/apache2/sites-enabled/jackett.conf ]]; then
    systemctl stop jackett@${MASTER}
    sed -i "s/\"AllowExternal.*/\"AllowExternal\": false,/g" /home/"${MASTER}"/.config/Jackett/ServerConfig.json
    sed -i "s/\"BasePathOverride.*/\"BasePathOverride\": \"\/jackett\"/g" /home/"${MASTER}"/.config/Jackett/ServerConfig.json

cat > /etc/apache2/sites-enabled/jackett.conf <<EOF
<Location /jackett>
ProxyPass http://localhost:9117/jackett
ProxyPassReverse http://localhost:9117/jackett
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${MASTER}
</Location>
EOF
    chown www-data: /etc/apache2/sites-enabled/jackett.conf
    service apache2 restart
    service jackett@${MASTER} start
  fi
}

function _plexpy() {
  if [[ ! -f /etc/apache2/sites-enabled/plexpy.conf ]]; then
  service plexpy stop
  sed -i "s/http_root.*/http_root = \"plexpy\"/g" /opt/plexpy/config.ini
  sed -i "s/http_host.*/http_host = localhost/g" /opt/plexpy/config.ini

  cat > /etc/apache2/sites-enabled/plexpy.conf <<EOF
  <Location /plexpy>
  ProxyPass http://localhost:8181/plexpy
  ProxyPassReverse http://localhost:8181/plexpy
  AuthType Digest
  AuthName "rutorrent"
  AuthUserFile '/etc/htpasswd'
  Require user ${MASTER}
  </Location>
EOF
  chown www-data: /etc/apache2/sites-enabled/plexpy.conf
  service apache2 restart
  service plexpy restart
  fi
}

function _plexrequsets() {
  if [[ ! -f /etc/apache2/sites-enabled/plexrequests.conf ]]; then
  cat > /etc/apache2/sites-enabled/plexrequests.conf <<EOF
<Location /plexrequests>
ProxyPass http://localhost:3000/plexrequests
ProxyPassReverse http://localhost:3000/plexrequests
Require all granted
</Location>
EOF
  chown www-data: /etc/apache2/sites-enabled/plexrequests.conf
  service apache2 restart
  fi
}

function _sickrage() {
  if [[ ! -f /etc/apache2/sites-enabled/sickrage.conf ]]; then
    service sickrage@${MASTER} stop
    sed -i "s/web_root.*/web_root = \"sickrage\"/g" /home/"${MASTER}"/.sickrage/config.ini
    sed -i "s/web_host.*/web_host = localhost/g" /home/"${MASTER}"/.sickrage/config.ini
    cat > /etc/apache2/sites-enabled/sickrage.conf <<EOF
<Location /sickrage>
  ProxyPass http://localhost:8081/sickrage
  ProxyPassReverse http://localhost:8081/sickrage
  AuthType Digest
  AuthName "rutorrent"
  AuthUserFile '/etc/htpasswd'
  Require user ${MASTER}
</Location>
EOF
    chown www-data: /etc/apache2/sites-enabled/sickrage.conf
    service apache2 restart
    service sickrage@${MASTER} start
  fi
}
function _sonarr() {
  if [[ ! -f /etc/apache2/sites-enabled/sonarr.conf ]]; then
    systemctl stop sonarr@${MASTER}
    sed -i "s/<UrlBase>.*/<UrlBase>sonarr<\/UrlBase>/g" /home/${MASTER}/.config/NzbDrone/config.xml
    sed -i "s/<BindAddress>.*/<BindAddress>localhost<\/BindAddress>/g" /home/${MASTER}/.config/NzbDrone/config.xml
    cat > /etc/apache2/sites-enabled/sonarr.conf <<EOF
<Location /sonarr>
ProxyPass http://localhost:8989/sonarr
ProxyPassReverse http://localhost:8989/sonarr
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${MASTER}
</Location>
EOF
    chown www-data: /etc/apache2/sites-enabled/sonarr.conf
    service apache2 restart
    systemctl start sonarr@${MASTER}
  fi
}
if [[ -f /install/.sickrage.lock ]]; then _sickrage; fi
if [[ -f /install/.couchpotato.lock ]]; then _couchpotato; fi
if [[ -f /install/.plexpy.lock ]]; then _plexpy; fi
if [[ -f /install/.plexrequests.lock ]]; then _plexrequsets; fi
