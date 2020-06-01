#!/bin/sh

## author: medcl.com

FILE=/opt/.optimized
if test -f "$FILE"; then
   echo "system already optimized, skip"
else

echo "start optimize system"

echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf


sudo tee /etc/security/limits.d/21-elastic.conf <<-'EOF'
*                soft    nofile         1024000
*                hard    nofile         1024000
*                soft    memlock        unlimited
*                hard    memlock        unlimited
elasticsearch          soft    nofile         1024000
elasticsearch          hard    nofile         1024000
elasticsearch          soft    memlock        unlimited
elasticsearch          hard    memlock        unlimited
root             soft    nofile         1024000
root             hard    nofile         1024000
root             soft    memlock        unlimited
EOF

cat << SETTINGS | sudo tee /etc/sysctl.d/70-cloudenterprise.conf
net.ipv4.tcp_max_syn_backlog=65536
net.core.somaxconn=32768
net.core.netdev_max_backlog=32768
SETTINGS

touch /opt/.optimized

echo "finish system optimize"
fi
