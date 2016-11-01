#!/bin/bash
clear

echo -e "###########################################################################"
echo -e "#  Ahmad Imanudin - http://www.imanudin.net | http://ahmad.imanudin.com   #"
echo -e "#    Script Auto Install Openstack KILO (Controller, Compute, Network)    #"
echo -e "#               Pada CentOS 7 (Core) versi 0.1 (12 Sept 2015)             #"
echo -e "#   Jika ada pertanyaan, silakan kontak saya pada alamat email berikut    #"
echo -e "#                  ahmad@imanudin.com | iman@imanudin.net                 #"
echo -e "#                   www.imanudin.com |  www.imanudin.net                  #"
echo -e "###########################################################################"

sleep 5
echo ""
echo ""

echo -e "===[Memulai proses auto install Openstack]==="
echo ""
echo ""
sleep 5

lokasi=`pwd`;
lokasikonfigurasi=`pwd`/konfigurasi;

# Data kolektif

echo -e "[INFO] : Data kolektif untuk instalasi node Openstack"
echo ""
sleep 5

echo -n "Silakan ketik/masukkan IP Address Controller Node : "
read IPCONTROLLERNODE

echo -n "Silakan ketik/masukkan IP Address Compute Node : "
read IPCOMPUTENODE

echo -n "Silakan ketik/masukkan IP Address Network Node : "
read IPNETWORKNODE

echo -n "Silakan ketik/masukkan IP Address Tunnel Compute Node : "
read IPTUNNELCOMPUTENODE

echo -n "Silakan ketik/masukkan IP Address Tunnel Network Node : "
read IPTUNNELNETWORKNODE

echo -n "Silakan ketik/masukkan Subnet internal untuk instance (misalnya : 172.16.10.0/24) : "
read IPINTERNALNETWORK

echo -n "Silakan ketik/masukkan IP Default Gateway internal untuk instance (misalnya : 172.16.10.254) : "
read GATEWAYINTERNALNETWORK

echo -n "Silakan ketik/masukkan interface external yang akan digunakan pada network node (misalnya : eth2) : "
read PORTEXTERNAL

echo -n "Silakan ketik/masukkan Subnet Segmen IP Public/Floating IP (misalnya : 192.168.200.0/24) : "
read NETWORKPUBLICIP

echo -n "Silakan ketik/masukkan IP Gateway Segmen IP Public/Floating IP (misalnya : 192.168.200.254) : "
read GATEWAYPUBLICIP

echo -n "Silakan ketik/masukkan IP Allocation Pool Awal Segmen IP Public/Floating IP (misalnya : 192.168.200.1) : "
read POOLAWALPUBLICIP

echo -n "Silakan ketik/masukkan IP Allocation Pool Akhir Segmen IP Public/Floating IP (misalnya : 192.168.200.253) : "
read POOLAKHIRPUBLICIP

echo -n "Silakan ketik/masukkan Password (Password ini akan digunakan untuk password services dan password login dashboard) : "
read PASSWORDSERVICES

echo -n "Ketik kvm jika processor pada compute node support kvm (ditulis dengan huruf kecil) : "
read CPUSUPPORT

## Generate token
echo -e "[INFO] : Generate Token untuk autentikasi Services"
echo ""
sleep 5

openssl rand -hex 10
echo ""
echo -n "Copy/salin hasil generate token diatas : "
read GENERATETOKEN

## Find & Replace file konfigurasi
find $lokasikonfigurasi -type f -exec sed -i s/10.10.10.10/$IPCONTROLLERNODE/g {} \;
find $lokasikonfigurasi -type f -exec sed -i s/10.10.10.20/$IPCOMPUTENODE/g {} \;
find $lokasikonfigurasi -type f -exec sed -i s/10.10.10.30/$IPNETWORKNODE/g {} \;
find $lokasikonfigurasi -type f -exec sed -i s/10.11.11.20/$IPTUNNELCOMPUTENODE/g {} \;
find $lokasikonfigurasi -type f -exec sed -i s/10.11.11.30/$IPTUNNELNETWORKNODE/g {} \;
find $lokasikonfigurasi -type f -exec sed -i s/RAHASIA/$PASSWORDSERVICES/g {} \;
find $lokasikonfigurasi -type f -exec sed -i s/PASTETOKEN/$GENERATETOKEN/g {} \;


## Konfigurasi Environment
#echo -e "[INFO] : Konfigurasi LC_CTYPE pada Environment"
#echo ""
#sleep 5

#echo LC_CTYPE="en_US.UTF-8" > /etc/environment
#ssh root@compute -t "command; echo LC_CTYPE="en_US.UTF-8" > /etc/environment"
#ssh root@network -t "command; echo LC_CTYPE="en_US.UTF-8" > /etc/environment"

## Install screen
#yum install -y screen
#ssh root@compute -t "command; yum install -y screen"
#ssh root@network -t "command; yum install -y screen"

## Install Paket NTP
echo -e "[INFO] : Instalasi NTP"
echo ""
sleep 5

yum install -y ntp
systemctl enable ntpd.service
systemctl start ntpd.service
timedatectl

ssh root@compute -t "command; yum install -y ntp; systemctl enable ntpd.service; systemctl start ntpd.service; timedatectl"
ssh root@network -t "command; yum install -y ntp; systemctl enable ntpd.service; systemctl start ntpd.service; timedatectl"


## Install Paket openstack-selinux
echo -e "[INFO] : Instalasi paket openstack-selinux"
echo ""
sleep 5

yum install -y openstack-selinux

ssh root@compute -t "command; yum install -y openstack-selinux"
ssh root@network -t "command; yum install -y openstack-selinux"

## =====Konfigurasi SQL Server (MariaDB) di Node Controller===== ##
echo -e "[INFO] : Instalasi dan konfigurasi SQL Server (MariaDB) pada Node Controller"
echo ""
sleep 5

yum install -y mariadb mariadb-server MySQL-python

yes | cp -rf $lokasikonfigurasi/controller/mariadb_openstack.cnf /etc/my.cnf.d/mariadb_openstack.cnf

systemctl enable mariadb.service
systemctl start mariadb.service
mysqladmin -u root password $PASSWORDSERVICES

## =====Konfigurasi Message queue (RabbitMQ) di Node Controller===== ##
echo -e "[INFO] : Instalasi dan konfigurasi RabbitMQ  pada Node Controller"
echo ""
sleep 5

yum install -y rabbitmq-server
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service

echo -e "Proses pembuatan user openstack pada RabbitMQ"
sleep 3

rabbitmqctl add_user openstack $PASSWORDSERVICES
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

## =====Konfigurasi Identity Service (Keystone) di Node Controller===== ##
echo -e "[INFO] : Instalasi dan konfigurasi Keystone pada Node Controller"
echo ""
sleep 5

# Buat database keystone

mysql -u root -p$PASSWORDSERVICES < $lokasikonfigurasi/controller/keystone.sql
yum install -y openstack-keystone httpd mod_wsgi python-openstackclient memcached python-memcached

# Jalankan service memcached

systemctl enable memcached.service
systemctl start memcached.service
systemctl status memcached.service

yes | cp -rf $lokasikonfigurasi/controller/keystone.conf /etc/keystone/keystone.conf

echo -e "Sinkronisasi database keystone"
sleep 3

su -s /bin/sh -c "keystone-manage db_sync" keystone

echo -e "Proses edit konfigurasi Apache httpd"
sleep 3

yes | cp -rf $lokasikonfigurasi/controller/httpd.conf /etc/httpd/conf/httpd.conf
yes | cp -rf $lokasikonfigurasi/controller/wsgi-keystone.conf /etc/httpd/conf.d/wsgi-keystone.conf

# Buat direktori untuk komponen WSGI

mkdir -p /var/www/cgi-bin/keystone

yes | cp -rf $lokasikonfigurasi/controller/main /var/www/cgi-bin/keystone/main
yes | cp -rf $lokasikonfigurasi/controller/admin /var/www/cgi-bin/keystone/admin

# Sesuaikan kepemilikan dan hak akses

chown -R keystone:keystone /var/www/cgi-bin/keystone
chmod 755 /var/www/cgi-bin/keystone/*

echo -e "Restart service Apache"
sleep 3

systemctl enable httpd.service
systemctl start httpd.service
systemctl status httpd.service


## Membuat entitas service dan API endpoint di Node Controller
echo -e "[INFO] : Membuat entitas service dan API endpoint"
echo ""
sleep 5

# Set environment shell

export OS_TOKEN=$GENERATETOKEN
export OS_URL=http://controller:35357/v2.0

echo -e "Membuat entitas service keystone-admin"
sleep 3

openstack service create --name keystone --description "OpenStack Identity" identity

echo -e "Membuat API endpoint keystone"
sleep 3

openstack endpoint create --publicurl http://controller:5000/v2.0 --internalurl http://controller:5000/v2.0 --adminurl http://controller:35357/v2.0 --region RegionOne identity

## Membuat Project, Users dan Role di Node Controller
echo -e "[INFO] : Membuat Project, Users dan Role"
echo ""
sleep 5

echo -e "Membuat project admin"
sleep 3

openstack project create --description "Admin Project" admin

echo -e "Membuat user admin"
sleep 3

openstack user create --password $PASSWORDSERVICES admin

echo -e "Membuat role admin"
sleep 3

openstack role create admin

echo -e "Menambahkan role admin ke project admin dan user admin"
sleep 3

openstack role add --project admin --user admin admin

echo -e "Membuat project service"
sleep 3

openstack project create --description "Service Project" service

## Verifikasi Service Keystone di Node Controller
echo -e "[INFO] : Verifikasi Service Keystone"
echo ""
sleep 5


# Disable mekanisme token otentikasi sementara

yes | cp -rf $lokasikonfigurasi/controller/keystone-dist-paste.ini /usr/share/keystone/keystone-dist-paste.ini

# Unset environment shell

unset OS_TOKEN OS_URL

echo -e "Sebagai admin, request token otentikasi dari API v2 keystone"
sleep 3

openstack --os-auth-url http://controller:35357 --os-project-name admin --os-username admin --os-auth-type password token issue --os-password $PASSWORDSERVICES


echo -e "Sebagai admin, request token otentikasi dari API v3 keystone"
sleep 3

openstack --os-auth-url http://controller:35357 --os-project-domain-id default --os-user-domain-id default --os-project-name admin --os-username admin --os-auth-type password token issue --os-password $PASSWORDSERVICES


echo -e "Sebagai admin, tampilkan daftar project"
sleep 3

openstack --os-auth-url http://controller:35357 --os-project-name admin --os-username admin --os-auth-type password project list --os-password $PASSWORDSERVICES


echo -e "Sebagai admin, tampilkan daftar user"
sleep 3

openstack --os-auth-url http://controller:35357 --os-project-name admin --os-username admin --os-auth-type password user list --os-password $PASSWORDSERVICES

echo -e "Sebagai admin, tampilkan daftar role"
sleep 3

openstack --os-auth-url http://controller:35357 --os-project-name admin --os-username admin --os-auth-type password role list --os-password $PASSWORDSERVICES



## Membuat Skrip Environment di Node Controller
echo -e "[INFO] : Salin skrip Environment"
echo ""
sleep 5

yes | cp -rf $lokasikonfigurasi/controller/admin-openrc.sh /srv/admin-openrc.sh

echo -e "Test memuat file environment dan request token otentikasi"
sleep 3

source /srv/admin-openrc.sh

# Request token otentikasi

openstack token issue

## =====Konfigurasi Service Image (Glance) di Node Controller===== ##
echo -e "[INFO] : Instalasi dan konfigurasi Service Image (Glance)"
echo ""
sleep 5

# Buat database dan user glance

mysql -u root -p$PASSWORDSERVICES < $lokasikonfigurasi/controller/glance.sql

# Muat environment admin

source /srv/admin-openrc.sh

echo -e "Membuat user glance"
sleep 3

openstack user create --password $PASSWORDSERVICES glance


echo -e "Menambahkan role admin ke user glance dan project service"
sleep 3

openstack role add --project service --user glance admin

echo -e "Membuat service entitas glance"
sleep 3

openstack service create --name glance --description "OpenStack Image service" image


echo -e "Membuat API endpoint glance"
sleep 3

openstack endpoint create --publicurl http://controller:9292 --internalurl http://controller:9292 --adminurl http://controller:9292 --region RegionOne image


echo -e "Install paket-paket glance"
sleep 3

yum install -y openstack-glance python-glance python-glanceclient


echo -e "Proses edit konfigurasi Glance API"
sleep 3

yes | cp -rf $lokasikonfigurasi/controller/glance-api.conf /etc/glance/glance-api.conf

echo -e "Proses edit konfigurasi Glance Registry"
sleep 3

yes | cp -rf $lokasikonfigurasi/controller/glance-registry.conf /etc/glance/glance-registry.conf

echo -e "Sinkronisasi database glance"
sleep 3

su -s /bin/sh -c "glance-manage db_sync" glance

echo -e "Jalankan service glance"
sleep 3

systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service
systemctl status openstack-glance-api.service openstack-glance-registry.service

## Verifikasi Glance di Node Controller
echo -e "[INFO] : Verifikasi Glance"
echo ""
sleep 5

# Memuat environment admin

source /srv/admin-openrc.sh
yum install -y wget

echo " Upload image cirros ke service glance"
sleep 3

glance image-create --name "cirros-0.3.4-x86_64" --file $lokasikonfigurasi/controller/cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --visibility public --progress


echo -e "Tampilkan daftar image"
sleep 3

glance image-list

## =====Konfigurasi Nova di Node Controller===== ##
echo -e "[INFO] : Konfigurasi Nova"
echo ""
sleep 5

# Buat database dan user nova

mysql -u root -p$PASSWORDSERVICES < $lokasikonfigurasi/controller/nova.sql

# Load skrip environment admin

source /srv/admin-openrc.sh

echo -e "Membuat user nova"
sleep 3

openstack user create --password $PASSWORDSERVICES nova

echo -e "Menambahkan role admin ke user nova"
sleep 3

openstack role add --project service --user nova admin

echo -e "Membuat entitas service nova"
sleep 3

openstack service create --name nova --description "OpenStack Compute" compute

echo -e "Membuat API endpoint nova"
sleep 3

openstack endpoint create --publicurl http://controller:8774/v2/%\(tenant_id\)s --internalurl http://controller:8774/v2/%\(tenant_id\)s --adminurl http://controller:8774/v2/%\(tenant_id\)s --region RegionOne compute

echo -e "Install paket-paket nova"
sleep 3

yum install -y openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient

echo -e "Proses edit file konfigurasi nova"
sleep 3

yes | cp -rf $lokasikonfigurasi/controller/nova.conf /etc/nova/nova.conf

echo -e "Sinkronisasi database nova"
sleep 3

su -s /bin/sh -c "nova-manage db sync" nova

echo -e "Jalankan service-service nova"
sleep 3

systemctl enable openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl status openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service


## =====Konfigurasi Nova di Node Compute===== ##
echo -e "[INFO] : Konfigurasi Nova pada Node Compute"
echo ""
sleep 5

echo -e "Instal paket-paket nova"
sleep 3

ssh root@compute -t "command; yum install -y openstack-nova-compute sysfsutils"

echo -e "Cek processor mendukung virtualisasi dan konfigurasi Nova"
sleep 3

#ssh root@compute -t "command; egrep -c '(vmx|svm)' /proc/cpuinfo"
#sleep 3

#cekvirtualisasi=`ssh root@compute -t "command; egrep -c '(vmx|svm)' /proc/cpuinfo"`;
 
if [ "$CPUSUPPORT" == "kvm" ]; then
	echo "Processor Node Compute mendukung Virtualisasi KVM"
        scp $lokasikonfigurasi/compute/nova.conf-kvm root@compute:/etc/nova/nova.conf
	sleep 3
        else
	echo "Processor Node Compute tidak mendukung Virtualisasi KVM"
	scp $lokasikonfigurasi/compute/nova.conf-qemu root@compute:/etc/nova/nova.conf
	fi
	sleep 3

echo -e "Jalankan service nova"
sleep 3

ssh root@compute -t "command; systemctl enable libvirtd.service openstack-nova-compute.service; systemctl start libvirtd.service openstack-nova-compute.service; systemctl status libvirtd.service openstack-nova-compute.service"

## Verifikasi Service Nova di Node Compute
echo -e "[INFO] : Verifikasi Service Nova"
echo ""
sleep 5

# Load environment admin

scp /srv/admin-openrc.sh root@compute:/srv/
#ssh root@compute -t "command; source /srv/admin-openrc.sh"

echo -e "Tampilkan service nova"
sleep 3

ssh root@compute -t "command; source /srv/admin-openrc.sh; nova service-list"
sleep 3

echo -e "Tampilkan API endpoint nova"
sleep 3

ssh root@compute -t "command; source /srv/admin-openrc.sh; nova endpoints"
sleep 3

echo -e "Tampilkan daftar image nova"
sleep 3

ssh root@compute -t "command; source /srv/admin-openrc.sh; nova image-list"
sleep 3

## =====Konfigurasi Neutron di Node Controller===== ##
echo -e "[INFO] : Konfigurasi Neutron pada Node Controller"
echo ""
sleep 5

# Buat user dan database neutron

mysql -u root -p$PASSWORDSERVICES < $lokasikonfigurasi/controller/neutron.sql

# Muat skrip environment admin

source /srv/admin-openrc.sh

echo -e "Membuat user neutron"
sleep 3

openstack user create --password $PASSWORDSERVICES neutron

echo -e "Menambahkan role admin ke user neutron"
sleep 3

openstack role add --project service --user neutron admin

echo -e "Membuat entitas service neutron"
sleep 3

openstack service create --name neutron --description "OpenStack Networking" network

echo -e "Membuat API endpoint neutron"
sleep 3

openstack endpoint create --publicurl http://controller:9696 --adminurl http://controller:9696 --internalurl http://controller:9696 --region RegionOne network

echo -e "Instal paket-paket neutron"
sleep 3

yum install -y openstack-neutron openstack-neutron-ml2 python-neutronclient which

echo -e "Proses edit file konfigurasi neutron"
sleep 3

yes | cp -rf $lokasikonfigurasi/controller/neutron.conf /etc/neutron/neutron.conf

echo -e "Proses edit konfigurasi plugin Modular Layer 2 (ML2)"
sleep 3

yes | cp -rf $lokasikonfigurasi/controller/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini

echo -e "Proses edit konfigurasi nova agar menggunakan service neutron"
sleep 3

yes | cp -rf $lokasikonfigurasi/controller/nova.conf /etc/nova/nova.conf

echo -e "Membuat symlink plugin ML2 untuk plugin neutron"
sleep 3

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

echo -e "Mengisi database neutron"
sleep 3

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

echo -e "Restart service nova"
sleep 3

systemctl restart openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-conductor.service
systemctl status openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-conductor.service

echo -e "Jalankan service neutron"
sleep 3

systemctl enable neutron-server.service
systemctl start neutron-server.service
systemctl status neutron-server.service


# Memuat skrip environment admin

source /srv/admin-openrc.sh

echo -e "Tampilkan daftar ekstention neutron"
sleep 3

neutron ext-list

## =====Konfigurasi Neutron di Node Network===== ##
echo -e "[INFO] : Instalasi dan Konfigurasi Neutron pada Node Network"
echo ""
sleep 5

echo -e "Proses edit parameter networking kernel"
sleep 3

scp $lokasikonfigurasi/network/sysctl.conf root@network:/etc/sysctl.conf
ssh root@network -t "command; sysctl -p"

echo -e "Instal paket-paket neutron"
sleep 3

ssh root@network -t "command; yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch"

echo -e "Proses edit file konfigurasi neutron"
sleep 3

scp $lokasikonfigurasi/network/neutron.conf root@network:/etc/neutron/neutron.conf

echo -e "Proses edit konfigurasi plugin Modular Layer 2 (ML2)"
sleep 3

scp $lokasikonfigurasi/network/ml2_conf.ini root@network:/etc/neutron/plugins/ml2/ml2_conf.ini

echo -e "Konfigurasi L3 agent"
sleep 3

scp $lokasikonfigurasi/network/l3_agent.ini root@network:/etc/neutron/l3_agent.ini

echo -e "Konfigurasi DHCP agent"
sleep 3

scp $lokasikonfigurasi/network/dhcp_agent.ini root@network:/etc/neutron/dhcp_agent.ini

echo -e "Konfigurasi MTU pada DHCP dnsmasq"
sleep 3

scp $lokasikonfigurasi/network/dnsmasq-neutron.conf root@network:/etc/neutron/dnsmasq-neutron.conf

echo -e "Matikan proses dnsmasq yang sedang berjalan"
sleep 3

ssh root@network -t "command; pkill dnsmasq"

echo -e "Konfigurasi metadata agent"
sleep 3

scp $lokasikonfigurasi/network/metadata_agent.ini root@network:/etc/neutron/metadata_agent.ini

echo -e "Proses edit konfigurasi nova pada Controller Node"
sleep 3

yes | cp -rf $lokasikonfigurasi/controller/nova.conf /etc/nova/nova.conf
systemctl restart openstack-nova-api.service

## =====Konfigurasi Service Open vSwitch (OVS) di Node Network===== ##
echo -e "[INFO] : Konfigurasi Service Open vSwitch (OVS) pada Node Network"
echo ""
sleep 5

echo -e "Jalankan service OVS"
sleep 3

ssh root@network -t "command; systemctl enable openvswitch.service; systemctl start openvswitch.service; systemctl status openvswitch.service"

echo -e "Tambahkan bridge eksternal"
sleep 3

ssh root@network -t "command; ovs-vsctl add-br br-ex"

echo -e "Tambahkan port fisik eksternal ke dalam bridge eksternal"
sleep 3

ssh root@network -t "command; ovs-vsctl add-port br-ex $PORTEXTERNAL"

echo -e "Disable generic receive offload (GRO)"
sleep 3

ssh root@network -t "command; ethtool -K $PORTEXTERNAL gro off"

echo -e "Membuat symlink plugin ML2 untuk plugin neutron"
sleep 3

ssh root@network -t "command; ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini"
ssh root@network -t "command; cp /usr/lib/systemd/system/neutron-openvswitch-agent.service /usr/lib/systemd/system/neutron-openvswitch-agent.service.orig"
scp $lokasikonfigurasi/network/neutron-openvswitch-agent.service root@network:/usr/lib/systemd/system/neutron-openvswitch-agent.service

echo -e "Jalankan service-service neutron"
sleep 3

ssh root@network -t "command; systemctl enable neutron-openvswitch-agent.service neutron-l3-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service neutron-ovs-cleanup.service"
ssh root@network -t "command; systemctl start neutron-openvswitch-agent.service neutron-l3-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service"
ssh root@network -t "command; systemctl status neutron-openvswitch-agent.service neutron-l3-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service"

# Muat skrip environment admin

scp /srv/admin-openrc.sh root@network:/srv/
#ssh root@network -t "command; source /srv/admin-openrc.sh"

echo -e "Tampilkan daftar agen neutron"
sleep 3

ssh root@network -t "command; source /srv/admin-openrc.sh; neutron agent-list"

## =====Konfigurasi Neutron di Node Compute===== ##
echo -e "[INFO] : Konfigurasi Neutron pada Node Compute"
echo ""
sleep 5

echo -e "Proses edit parameter networking kernel"
sleep 3

scp $lokasikonfigurasi/compute/sysctl.conf root@compute:/etc/sysctl.conf

ssh root@compute -t "command; modprobe bridge"
ssh root@compute -t "command; sysctl -p"

echo -e "Instal paket-paket neutron"
sleep 3

ssh root@compute -t "command; yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch"

echo -e "Proses edit file konfigurasi neutron"
sleep 3

scp $lokasikonfigurasi/compute/neutron.conf root@compute:/etc/neutron/neutron.conf

echo -e "Proses Konfigurasi file plugin ML2"
sleep 3

scp $lokasikonfigurasi/compute/ml2_conf.ini root@compute:/etc/neutron/plugins/ml2/ml2_conf.ini

echo -e "Jalankan service OVS"
sleep 3

ssh root@compute -t "command; systemctl enable openvswitch.service"
ssh root@compute -t "command; systemctl start openvswitch.service"
ssh root@compute -t "command; systemctl status openvswitch.service"

echo -e "Membuat symlink plugin ML2 untuk plugin neutron"
sleep 3

ssh root@compute -t "command; ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini"
ssh root@compute -t "command; cp /usr/lib/systemd/system/neutron-openvswitch-agent.service /usr/lib/systemd/system/neutron-openvswitch-agent.service.orig"
scp $lokasikonfigurasi/compute/neutron-openvswitch-agent.service root@compute:/usr/lib/systemd/system/neutron-openvswitch-agent.service

echo -e "Restart service nova"
sleep 3

ssh root@compute -t "command; systemctl restart openstack-nova-compute.service"

echo -e "Jalankan service agent OVS"
sleep 3

ssh root@compute -t "command; systemctl enable neutron-openvswitch-agent.service"
ssh root@compute -t "command; systemctl start neutron-openvswitch-agent.service"
ssh root@compute -t "command; systemctl status neutron-openvswitch-agent.service"

# Muat skrip environment admin

#ssh root@compute -t "command; source /srv/admin-openrc.sh"

echo -e "Tampilkan daftar agen neutron"
sleep 3

ssh root@compute -t "command; source /srv/admin-openrc.sh; neutron agent-list"

## =====Konfigurasi Dashboard (Horizon) di Node Controller===== ##
echo -e "[INFO] : Konfigurasi Dashboard (Horizon) pada Node Controller"
echo ""
sleep 5

echo -e "Instal paket-paket dashboard"
sleep 3

yum install -y openstack-dashboard httpd mod_wsgi memcached python-memcached

echo -e "Proses edit file konfigurasi dashboard"
sleep 3

yes | cp -rf $lokasikonfigurasi/controller/local_settings /etc/openstack-dashboard/local_settings

echo -e "Permit SELinux dan Ubah permission CSS"
sleep 3

setsebool -P httpd_can_network_connect on
chown -R apache:apache /usr/share/openstack-dashboard/static

echo -e "Restart service httpd dan memcached"
sleep 3

systemctl restart httpd.service memcached.service

## =====Membuat External Network dan Internal Network di Node Controller (Bisa di Dashboard)===== ##
echo -e "[INFO] : Membuat External Network dan Internal Network pada Node Controller"
echo ""
sleep 5

# Muat skrip environment admin

source /srv/admin-openrc.sh

echo -e "Proses pembuatan external network"
sleep 3

neutron net-create net-ext --router:external --provider:physical_network external --provider:network_type flat --shared

echo -e "Proses pembuatan subnet external network"
sleep 3

neutron subnet-create net-ext $NETWORKPUBLICIP --name subnet-ext --allocation-pool start=$POOLAWALPUBLICIP,end=$POOLAKHIRPUBLICIP --disable-dhcp --gateway $GATEWAYPUBLICIP

echo -e "Proses pembuatan internal network"
sleep 3

neutron net-create net-int

echo -e "Proses pembuatan subnet internal network"
sleep 3

neutron subnet-create net-int $IPINTERNALNETWORK --name subnet-int --gateway $GATEWAYINTERNALNETWORK

## =====Membuat Router untuk Gateway Instance di Node Controller===== ##
echo -e "[INFO] : Membuat Router untuk Gateway Instance pada Node Controller"
echo ""
sleep 5

echo -e "Proses pembuatan Router"
sleep 3

neutron router-create router0

echo -e "Proses Pemasangan internal subnet ke interface router"
sleep 3

neutron router-interface-add router0 subnet-int

echo -e "Proses Pemasangan external subnet sebagai gateway bagi router"
sleep 3

neutron router-gateway-set router0 net-ext

echo -e "Testing Ping dari Host ke Gateway IP Public"
sleep 3

ping $GATEWAYPUBLICIP -c5

## =====Membuat Project, Role dan User (Bisa Di Dashboard)===== ##
echo -e "[INFO] : Membuat Project, Role dan User"
echo ""
sleep 5

# Muat skrip environment admin

source /srv/admin-openrc.sh

echo -e "Proses pembuatan project user"
sleep 3

openstack project create --description "User Project" user

echo -e "Proses pembuatan role user"
sleep 3

openstack role create user

echo -e "Proses otomatis instalasi dan konfigurasi Openstack telah selesai. Silakan akses link berikut via browser http://$IPCONTROLLERNODE/dashboard untuk membuat user, project, launch instance dan lain lain"
sleep 5

echo -e "[Kredit] : Terima Kasih Kepada"
sleep 5

echo -e "ALLAH SWT"
sleep 5

echo -e "Nabi Muhammad SAW"
sleep 5

echo -e "Kedua Orang Tua"
sleep 5

echo -e "Kakak dan Adik"
sleep 5

echo -e "Pak Boss Masim "Vavai" Sugianto"
sleep 5

echo -e "Team Excellent Infotama Kreasindo"
sleep 5

echo -e "Bapak Utian Ayuba (B-Tech)"
sleep 5

echo -e "Mas Edi Gunawan (gunawan.eddy1@gmail.com)"
sleep 5

echo -e "Teman Teman"
sleep 5

echo -e "Rekan-rekan semua atas partisipasinya"
sleep 5
