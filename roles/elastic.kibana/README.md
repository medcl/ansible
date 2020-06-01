kibana role
=========
[![License](https://img.shields.io/badge/license-Apache-green.svg?style=flat)](https://raw.githubusercontent.com/lean-delivery/ansible-role-kibana/master/LICENSE)
[![Build Status](https://travis-ci.org/lean-delivery/ansible-role-kibana.svg?branch=master)](https://travis-ci.org/lean-delivery/ansible-role-kibana)
[![Build Status](https://gitlab.com/lean-delivery/ansible-role-kibana/badges/master/build.svg)](https://gitlab.com/lean-delivery/ansible-role-kibana/pipelines)
[![Galaxy](https://img.shields.io/badge/galaxy-lean__delivery.kibana-blue.svg)](https://galaxy.ansible.com/lean_delivery/kibana)
![Ansible](https://img.shields.io/ansible/role/d/29387.svg)
![Ansible](https://img.shields.io/badge/dynamic/json.svg?label=min_ansible_version&url=https%3A%2F%2Fgalaxy.ansible.com%2Fapi%2Fv1%2Froles%2F29387%2F&query=$.min_ansible_version)

## Summary

This Ansible role has the following features:

 - Install kibana
 - Binds kibana to preinstalled elasticsearch host

Requirements
------------

 - Version of the ansible for installation: 2.5
 - **Supported OS**:  
   - EL
     - 6
     - 7
   - Ubuntu
     - 16.04
     - 18.04
   - Debian
     - 8
     - 9

## Role Variables

- defaults
  - `elastic_branch`  
  Used to select main kibana version to be installed (6.x or higher for current stable versions). By default this variable is set to `6`. So, `6.x` version is installed by default. You can override this by setting this variable in playbook or inventory.
  - `kibana_version`
  Sets specific kibana version. If you need the exact version to be installed - set this variable to the desired value. `6.2.4` for example. By default this variable is set to `6.x` which means last stable version to be installed.
  - `es_use_oss_version`
  Variable to use an alternative package, `kibana-oss`, which contains only features that are available under the Apache 2.0 license. `X-Pack` options are not included in package. Default value is `False`. Set to `True` if you need to install only OSS package version without `X-Pack` features.
  - `kibana_host`
  Specifies the address to which the Kibana server will bind. IP addresses and host names are both valid values. The default is 'localhost', which usually means remote machines will not be able to connect. To allow connections from remote users, set this parameter to a non-loopback address.
  - `kibana_port`
  Specifies the port to use for Kibana. Default value is `5601`.
  - `elasticsearch_host` and `elasticsearch_port`
  Variables are necessary for Kibana to be able to communicate to running Elasticsearch server. Please set proper values of these variables according to your infrastructure. Default values are `localhost` and `9200`.
  - `kibana_elasticsearch_url`
  Address using by Kibana to connect to `elasticsearch` service. In simple cases it's set automatically using `elasticsearch_host` and `elasticsearch_port` values. If it's not enough in more complex environment, you can redefine `kibana_elasticsearch_url` to set the correct url value directly.
  - `kibana_conf_dir`
  Path to kibana config directory. Default value is `/etc/kibana`.
  - `kibana_pid_dir`
  Path to the directory containing pid for running kibana service. Default value is `/var/run/kibana`.
  - `kibana_log_dir`
  Kibana log storage directory. Default value is `/var/log/kibana`.
  - `kibana_data_dir`
  The location of the data files written to disk by Kibana and its plugins. Default value is `/var/lib/kibana`.
  - `kibana_config`
  All Kibana configuration parameters are supported. This is achieved using a configuration map parameter `kibana_config` which is serialized into the `kibana.yml` file.
  - `kibana_user` and `kibana_group`
  Credentials used to run Kibana service. Default values set by package scenarios to `kibana`. Change only if necessary.
  - `elastic_gpg_key`
  GPG key for repositories. Default value is `https://artifacts.elastic.co/GPG-KEY-elasticsearch`.
  - `es_apt_url`
  Address of APT repository with Elastic stack packages. Default is external address provided by Elastic: `deb https://artifacts.elastic.co/packages/{{ es_repo_name }}/apt stable main`. Redefine in case of alternate repository is required.
  - `es_yum_url`
  Address of YUM repository with Elastic stack packages. Default is external address provided by Elastic: `https://artifacts.elastic.co/packages/{{ es_repo_name }}/yum`. Redefine in case of alternate repository is required.
  - `es_repo_file`
  Local file name of Elastic stack repository configuration. Default is `elastic-{{ es_major_version }}`

## Some examples of the installing current role

`ansible-galaxy install lean_delivery.kibana`

Example Playbook
----------------

### Installing kibana 6.x version:
```yaml
- name: Install kibana
  hosts: kibana-host
  vars:
    elastic_branch: 6
    kibana_host: localhost
  roles:
     - role: lean_delivery.kibana
```

### Installing kibana 6.x version with disabled xpack security feature:
```yaml
- name: Install kibana
  hosts: kibana-host
  vars:
    elastic_branch: 6
    kibana_host: localhost
    kibana_config:
      xpack.security.enabled: False
  roles:
     - role: lean_delivery.kibana
```

License
-------

Apache2

Author Information
------------------

authors:
  - Lean Delivery <team@lean-delivery.com>
