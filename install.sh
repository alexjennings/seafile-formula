#!/bin/sh
set -e

if [ "$(whoami)" != "root" ]; then
    echoerror "Salt requires root privileges to install. Please re-run this script as root."
    exit 1
fi

if yum list installed "salt-minion" >/dev/null 2>&1; then
   echo "salt installed"
 else
   echo "salt not installed"
   exit 1
fi

if [ -d /srv/salt ]; then
    echo "moving old salt dir"
    mv /srv/salt /srv/salt.old
fi

if [ -f /etc/salt/minion ]; then
    echo "moving old minion config"
    mv /etc/salt/minion /etc/salt/minion.old
fi



mkdir /tmp/seafileinstall
cd /tmp/seafileinstall
curl -o seafile-formula-master.tar.gz https://codeload.github.com/alexjennings/seafile-formula/tar.gz/master
tar xvf seafile-formula-master.tar.gz
cp -r seafile-formula-master/salt /srv
cp seafile-formula-master/minion /etc/salt/minion
service salt-minion restart
salt-call state.highstate
