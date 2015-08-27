{% set os_ = salt['grains.get']('os', '') %}
{% set os_major_release = salt['grains.get']('osmajorrelease', '') %}
{% set distro = salt['grains.get']('oscodename', '')  %}

{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}
{% set repo_key = 'SALTSTACK-EL5-GPG-KEY.pub' %}


get-key:
  cmd.run:
    - name: wget https://repo.saltstack.com/yum/rhel{{ os_major_release }}/{{ repo_key }} ; rpm --import {{ repo_key }} ; rm -f {{ repo_key }}

add-repository:
  file.managed:
    - name: /etc/yum.repos.d/saltstack.repo
    - makedirs: True
    - contents: |
        ####################
        # Enable SaltStack's package repository
        [saltstack-repo]
        name=SaltStack repo for RHEL/CentOS $releasever
        baseurl=https://repo.saltstack.com/yum/rhel$releasever
        enabled=1
        gpgcheck=1
        gpgkey=https://repo.saltstack.com/yum/rhel$releasever/{{ repo_key }}
    - require:
      - cmd: get-key

update-package-database:
  module.run:
    - name: pkg.refresh_db
    - require:
      - file: add-repository

update-package-database-backup:
  cmd.run:
    - name: yum -y makecache
    - onfail:
      - module: update-package-database

upgrade-packages:
  pkg.uptodate:
    - name: uptodate
    - require:
      - module: update-package-database

install-salt:
  pkg.installed:
    - name: salt-pkgs
    - pkgs: {{ pkgs }}
    - require:
      - pkg: upgrade-packages
