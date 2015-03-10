{%- set seafile = salt['pillar.get']('seafile', {}) %}
{%- set seafile_version = seafile.get('version', '4.0.6') %}
{%- set seafile_src = seafile.get('src', '0aa19fd2c69cc774ad716f30586f98bd') %}
{%- set seafile_email = seafile.get('email', 'seafile@localhost.local') %}
{%- set seafile_password = seafile.get('password', 'seafile') %}


include:
  - nginx

seafile_auth:
    group.present:
        - name: seafile
        - system: True
    user.present:
        - name: seafile
        - gid_from_name: True
        - shell: /bin/bash
        - home: /var/seafile
        - system: True
        - require:
          - group: seafile_auth
    file.directory:
        - names:
            - /var/log/seafile
            - /opt/seafile-data
            - /opt/seafile
        - user: seafile
        - group: seafile
        - require:
          - user: seafile

seafile_pkgs:
  pkg.installed:
    - pkgs:
      - python-pillow
      - python-flup

seafile_source:
  archive.extracted:
    - name: /opt/seafile
    - archive_user: seafile_auth
    - source: "https://bitbucket.org/haiwen/seafile/downloads/seafile-server_{{ seafile_version }}_x86-64.tar.gz"
    - source_hash: 'md5={{ seafile_src }}'
    - archive_format: tar
    - if_missing: /opt/seafile/seafile-server-{{ seafile_version }}
    - require:
      - file: seafile_auth
  file.directory:
    - name: /opt/seafile/seafile-server-{{ seafile_version }}
    - user: seafile
    - recurse:
      - user
    - require:
      - archive: seafile_source

seafile_answers:
  file.managed:
    - name: /opt/seafile/seafile-server-{{ seafile_version }}/seafile_answers.txt
    - user: seafile
    - mode: 500
    - contents: |
        use_root=no
        use_existing_ccnet=yes
        use_existing_seafile=yes
        skip_welcome=yes
        skip_confok=yes
        skip_seahubwelcome=yes
        skip_seahubok=yes
        server_name=seafile
        ip_or_domain=127.0.0.1
        server_port=10001
        seafile_server_port=12001
        fileserver_port=8082
        seafile_data_dir=/opt/seafile-data
        seahub_admin_email="{{ seafile_email }}"
        seahub_admin_passwd={{ seafile_password }}
        seahub_admin_passwd_again={{ seafile_password }}
    - require:
      - file: seafile_source

seafile_setup:
  file.managed:
    - name: /opt/seafile/seafile-server-{{ seafile_version }}/setup-seafile.sh
    - source: salt://seafile/files/setup-seafile.sh
    - mode: 555
    - require:
      - archive: seafile_source
  cmd.run:
    - name: './setup-seafile.sh seafile_answers.txt'
    - cwd: /opt/seafile/seafile-server-{{ seafile_version }}/
    - user: seafile
    - creates: /opt/seafile/seafile-server-latest
    - require:
      - file: seafile_setup
      - file: seafile_answers


seafile_config:
  file.managed:
    - name: /etc/sysconfig/seafile
    - contents: |
        user=seafile
        seafile_dir=/opt/seafile
        script_path=${seafile_dir}/seafile-server-latest
        seafile_init_log=/var/log/seafile/seafile.init.log
        seahub_init_log=/var/log/seafile/seahub.init.log
        fastcgi=true
        fastcgi_port=8000



seafile_ccnet:
  ini.options_present:
    - name: /opt/seafile/ccnet/ccnet.conf
    - sections:
        General:
          SERVICE_URL: 'http://{{ salt['network.ip_addrs']()|first() }}'
    - require:
      - cmd: seafile_setup



seafile_settings:
  ini.options_present:
    - name: /opt/seafile/seahub_settings.py
    - sections:
        DEFAULT_IMPLICIT:
          FILE_SERVER_ROOT: '"http://{{ salt['network.ip_addrs']()|first() }}/seafhttp"'
    - require:
      - cmd: seafile_setup


seahub_setup:
  file.managed:
    - name: /opt/seafile/seafile-server-latest/check_init_admin.py
    - mode: 555
    - user: seafile
    - source: salt://seafile/files/check_init_admin.py
    - require:
      - cmd: seafile_setup


seafile_service:
  file.managed:
    - name: /etc/init.d/seafile
    - mode: 555
    - source: salt://seafile/files/seafile-init
  service.running:
    - name: seafile
    - enable: True
    - provider: service
    - require:
      - file: seafile_service
      - file: seafile_config
      - pkg: seafile_pkgs
      - ini: seafile_ccnet
      - ini: seafile_settings
      - file: seahub_setup

seahub_service:
  file.managed:
    - name: /etc/init.d/seahub
    - mode: 555
    - source: salt://seafile/files/seahub-init
  service.running:
    - name: seahub
    - enable: True
    - provider: service
    - require:
      - service: seafile_service
      - file: seahub_service

seafile_nginx:
  file.managed:
    - name: /etc/nginx/conf.d/seafile.conf
    - source: salt://seafile/files/seahub.conf
    - watch_in:
      - service: nginx
