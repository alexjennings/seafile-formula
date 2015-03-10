Credentials
============

Username: seafile@localhost.com
Password: seafile


Example Pillar
==============
seafile:
  version: '4.0.6'
  src: '0aa19fd2c69cc774ad716f30586f98bd' # MD5 checksum of seafile archive
  email: 'seafile@localhost.local' # Must be in the form user@domain.com
  password: 'seafile'


Scripted Salt Installation
===========================
Run this one-liner to grab this repo, clear any old salt states and install seafile.

```
curl -L https://raw.githubusercontent.com/alexjennings/seafile-formula/master/install.sh | sudo sh -s --
```
