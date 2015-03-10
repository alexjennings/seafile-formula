nginx:
  pkg.installed:
    - name: nginx
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://nginx/files/nginx.conf
    - require:
      - pkg: nginx
    - watch_in:
      - service: nginx
  service.running:
    - name: nginx
    - require:
      - pkg: nginx
