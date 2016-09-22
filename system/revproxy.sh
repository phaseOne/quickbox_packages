#!/bin/bash
# Update installed apps to new reverse proxy configurations

MASTER=$(cat /srv/rutorrent/home/db/master.txt)

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

function _couchpotato() {
  if [[ ! -f /etc/apache2/sites-enabled/couchpotato.conf ]]; then
    service couchpotato@${MASTER} stop
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

function _plexpy() {
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
}
if [[ -f /install/.sickrage.lock ]]; then _sickrage; fi
if [[ -f /install/.couchpotato.lock ]]; then _couchpotato; fi