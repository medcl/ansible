
# Medcl's Curated Ansible Toolkit

- Elastic Stack, Safety First! TLS enabled by default.

# Summary

Tested on:

- Elastic Stack 7.7 on Ubuntu 18.04 LTS.
- Elastic Stack 7.9 on Ubuntu 18.04 LTS.
- Elastic Stack 7.10 on Ubuntu 18.04 LTS.


In this example we will use `18.181.163.232` as ansible node:

```
export ANSIBLE_NODE=ubuntu@18.181.163.232
```

And manage these nodes for deployments:

```
172.16.50.4
172.16.50.5
172.16.50.6
```

# Prerequisite

## Network

Open port 9300 within cluster nodes, open port 9204 for coordinating nodes, open 5601 for Kibana nodes.

## Install Ansible

```
sudo apt install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt install ansible -y
sudo apt install python3-pip -y
```

## Generate an SSH Key

```
ssh-keygen 
ssh-keygen -f id_rsa
```

## Trusted with SSH Key

Make sure Ansible node have access to all managed nodes, can be setup in many ways, like:

```
ssh-copy-id -i id_rsa.pub ubuntu@172.16.50.4
ssh-copy-id -i id_rsa.pub ubuntu@172.16.50.5
ssh-copy-id -i id_rsa.pub ubuntu@172.16.50.6
```

## Ignore host verification

Let Ansible node ignore host verification

```
tee ~/.ssh/config <<-'EOF'
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF
```

## Create `hosts` config

```./hosts
[all-in-one]
172.16.50.4
172.16.50.5
172.16.50.6
```

## Test Ansible

```
ansible -i hosts all -m shell -a 'uptime'

ansible -i hosts all -a 'uptime'

ansible -b --become-user=root -i hosts all -m shell  -a '/sbin/ifconfig | /bin/grep 172'
```

# System optimization

```
ansible -b --become-user=root -i hosts all -m copy -a 'src=./scripts/optimize.sh dest=/tmp/optimize.sh owner=root group=root mode=644 backup=yes'
ansible -b --become-user=root -i hosts all -m shell -a 'chmod a+x /tmp/optimize.sh;/tmp/optimize.sh'
ansible -b --become-user=root -i hosts all -m shell -a 'reboot'
ansible -b --become-user=root -i hosts all -m shell -a 'uptime'   
```


# Deploy Elasticsearch

## Download roles 

Login into Ansible server

```
mkdir -p /home/test/elastic/ansible/roles
cd /home/test/
git clone https://github.com/medcl/ansible.git  ansible
```

## Create playbook 

You can create your own playbook, but here ships with examples, `es/site.yml` is for multi-role elasticsearch deployment, you can modify the relevant configuration of each node separately in `es/vars/{ROLE}.yml`. general parameters are located in `es/vars/vars.yml`.

Let's check `es/site-all-in-one.yml` to deploy unified roles for example, usually you only need to configure heap size:

```
- hosts: all-in-one
  become: true
  become_user: root
  become_method: sudo
  roles:
    - role: elastic.elasticsearch
  vars_files:
    - ../vars/vars.yml
    - ./vars/vars.yml
  vars:    
    es_instance_name: "all"
    es_heap_size: "512m"
    es_config:
      node.data: true
      node.master: true
      http.port: 9200
      transport.port: 9300
      cluster.name: "{{es_cluster_name}}"
      xpack.security.enabled: true
      cluster.initial_master_nodes: "{{es_cluster_initial_master_nodes}}"
      network.host: "{{es_main_network_device}},_local_"
      xpack.security.http.ssl.verification_mode: none
      bootstrap.memory_lock: true
      http.max_initial_line_length: "8k"
      http.max_header_size: "16k"
      indices.memory.index_buffer_size: 20%
      thread_pool.write.queue_size: 2000
      http.cors.enabled: true
      http.cors.allow-origin: /.*/
```

And also must modify `vars/vars.yml`, these are supposed to be sharable variables, could be potentially used by other playbooks:

```
es_api_host: 172.31.6.229
es_api_port: 9200
es_api_basic_auth_username: "elastic"
es_api_basic_auth_password: "esrocks"

es_cluster_initial_master_nodes: "172.31.6.229:9300"
es_discovery_seed_hosts: "172.31.6.229:9300,172.31.6.229:9300"
```

## Prepare self-signed cert files to `certs` folder

You should regenerate your own cert files by run `cd es/certs; ./generate.sh`, the folder should have follow structure:

```
-> playbooks/ tree
.
|-- es
|   |-- certs
|   |   |-- ca.crt
|   |   |-- instance.crt
|   |   |-- instance.key
```

## Deploy Elasticsearch

```
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i ./hosts ./playbooks/es/site-all-in-one.yml  -vvv
```

## Verify deployment

View node list.

```
curl -u elastic:changeme  -k 'https://172.16.50.4:9200/_cat/nodes?v'
```

View cluster health.

```
curl -u elastic:changeme -k 'https://172.16.50.4:9200/_cluster/health?pretty'
```

## Deploy Kibana and beats

Modify `hosts` file, add node for `kibana`

```./hosts
[all-in-one]
172.16.50.4
172.16.50.5
172.16.50.6

[kibana]
172.16.50.4
```

And run the following scripts, kibana and beats should be just deployed.

```
ansible -b --become-user=root -i ./hosts kibana -m shell -a 'sudo apt install python3-pip -y'
```

```
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i ./hosts  ./playbooks/kibana/site.yml
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i ./hosts  ./playbooks/metricbeat/site.yml 
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i ./hosts  ./playbooks/filebeat/site.yml 
```

Open `https://externalIP:5601`, and check it out.

# Development tips

## Check services

```
ansible -b --become-user=root -i hosts all -m shell -a 'systemctl daemon-reload|/bin/systemctl -a|grep elastic'
```   

## Destroy && Restart over

```
ansible -b --become-user=root -i hosts all -m shell -a '/bin/systemctl stop *elasticsearch.service'
ansible -b --become-user=root -i hosts all -m shell -a '/bin/systemctl disable coord_elasticsearch.service  \
data_elasticsearch.service \
vote_elasticsearch.service \
master_elasticsearch.service
'
ansible -b --become-user=root -i hosts all -m shell -a '/bin/systemctl -a|grep elastic'
ansible -b --become-user=root -i hosts all -m shell -a 'rm -rif /data/'
ansible -b --become-user=root -i hosts all -m shell -a 'rm -rif /etc/elasticsearch/' 
ansible -b --become-user=root -i hosts all -m shell -a 'rm -rif /usr/lib/systemd/system/*elastic*' 
ansible -b --become-user=root -i hosts all -m shell -a 'apt-get purge metricbeat -y' 
ansible -b --become-user=root -i hosts all -m shell -a 'apt-get purge filebeat -y' 
ansible -b --become-user=root -i hosts all -m shell -a 'apt-get purge kibana -y' 
```


## Upload Ansible configs

For local development, you can modify the playbook and roles, and upload to ansible node

```
cd ..
tar cfz ansible.tar.gz --exclude .git --exclude "*.log" ansible 
scp ansible.tar.gz $ANSIBLE_NODE:/tmp
ssh $ANSIBLE_NODE "pwd; cd /tmp; tar vxzf ansible.tar.gz"
rm -rif ansible.tar.gz
```

## Update config

```
scp hosts $ANSIBLE_NODE:/tmp/ansible/hosts 
scp playbooks/es/vars/* $ANSIBLE_NODE:/tmp/ansible/playbooks/es/vars 
scp playbooks/es/site.yml $ANSIBLE_NODE:/tmp/ansible/playbooks/es/
scp playbooks/kibana/* $ANSIBLE_NODE:/tmp/ansible/playbooks/kibana/
scp playbooks/filebeat/* $ANSIBLE_NODE:/tmp/ansible/playbooks/filebeat/
scp playbooks/metricbeat/* $ANSIBLE_NODE:/tmp/ansible/playbooks/metricbeat/
```


## Deploy multi playbook at the same time

```
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i ./hosts  ./playbooks/es/site.yml ./playbooks/kibana/site.yml  
```


## Generate and initial password 

Change user `beats_system` to a random password

```
BEAT_PASS=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo ''`
curl -XPOST -k -u elastic:changeme "https://ESIP:9200/_security/user/beats_system/_password" -H 'Content-Type: application/json' -d'{"password": "'"$BEAT_PASS"'"}'
```

## Keystore

```
echo 'changeme`|bin/elasticsearch-keystore add "bootstrap.password"

#set +o history
#export LOGSTASH_KEYSTORE_PASS=mypassword
#set -o history
```

```
/usr/share/kibana/bin//kibana-keystore create 
echo $SSL_KEY_PASS|  /usr/share/kibana/bin/kibana-keystore add server.ssl.keyPassphrase
echo $BEAT_PASS| /usr/share/kibana/bin/kibana-keystore add elasticsearch.password -f
```

```
ansible -b --become-user=root -i hosts es-master -m copy -a 'src=/hom
e/config/elasticsearch.keystore dest=/etc/elasticsearch/master/elasticsearch.keystore o
wner=elasticsearch group=elasticsearch mode=644 backup=yes'
```

```
cat /file/containing/setting/value | bin/kibana-keystore add the.setting.name.to.set --stdin
```


# FAQ

## /bin/sh: 1: /usr/bin/python: not found

```
➜  ansible ansible -i hosts es -m shell -a 'uptime'
18.181.163.232 | FAILED! => {
    "changed": false,
    "module_stderr": "Shared connection to 18.181.163.232 closed.\r\n",
    "module_stdout": "/bin/sh: 1: /usr/bin/python: not found\r\n",
    "msg": "The module failed to execute correctly, you probably need to set the interpreter.\nSee stdout/stderr for the exact error",
    "rc": 127
}
13.113.40.42 | CHANGED | rc=0 >>
 11:38:01 up 1 day,  8:46,  1 user,  load average: 0.00, 0.00, 0.00
```

```
[all:vars]
ansible_python_interpreter = /usr/bin/python3
```

# Licenses

Please thank these awesome ansible roles to make life easier.

- Elasticsearch role based from (Apache 2.0): https://github.com/elastic/ansible-elasticsearch
- Beats roles base from (Apache 2.0): https://github.com/elastic/ansible-beats
- Kibana roles base from (Apache 2.0): https://github.com/lean-delivery/ansible-role-kibana
