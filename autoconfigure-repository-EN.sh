#!/bin/bash
clear

echo -e "##########################################################################"
echo -e "#  Ahmad Imanudin - http://www.imanudin.net | http://ahmad.imanudin.com  #"
echo -e "#      Script automatic configure repository, /etc/hosts, firewall       #"
echo -e "#               hostname, SSH Password-less and upgrade OS               #"
echo -e "#             If any question, please drop an email to me at             #"
echo -e "#                  ahmad@imanudin.com | iman@imanudin.net                #"
echo -e "##########################################################################"

lokasi=`pwd`;

# Konfigurasi Repositori Controller Node
## Salin file openstack.tgz dari server luar via SCP
## Extract openstack.tgz
#tar -zxvf $lokasi/openstack.tgz -C /srv/

## Membuat repo lokal
rpm -Uvh $lokasi/repo/deltarpm-3.6-3.el7.x86_64.rpm
rpm -Uvh $lokasi/repo/libxml2-2.9.1-5.el7_1.2.x86_64.rpm
rpm -Uvh $lokasi/repo/libxml2-python-2.9.1-5.el7_1.2.x86_64.rpm
rpm -Uvh $lokasi/repo/deltarpm-3.6-3.el7.x86_64.rpm
rpm -Uvh $lokasi/repo/python-deltarpm-3.6-3.el7.x86_64.rpm
rpm -Uhv $lokasi/repo/createrepo-0.9.9-23.el7.noarch.rpm
createrepo $lokasi/repo/

## Buat folder dan repo openstack
mkdir -p /etc/yum.repos.d/repobak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/repobak/

echo "[openstack]" > /etc/yum.repos.d/openstack.repo
echo "name=openstack" >> /etc/yum.repos.d/openstack.repo
echo "baseurl=file://$lokasi/repo" >> /etc/yum.repos.d/openstack.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/openstack.repo
echo "enabled=1" >> /etc/yum.repos.d/openstack.repo 

## Konfigurasi /etc/hosts
echo -e "[INFO] : Configure /etc/hosts"
echo ""
sleep 5

echo -n "Please insert IP Address of Controller Node : "
read IPCONTROLLERNODE
echo -n "Please insert IP Address of Compute Node : "
read IPCOMPUTENODE
echo -n "Please insert IP Address of Network Node : "
read IPNETWORKNODE

cp /etc/hosts /etc/hosts-`date +%H-%M-%S-%d-%m-%Y`
echo "127.0.0.1 localhost" > /etc/hosts
echo "$IPCONTROLLERNODE controller" >> /etc/hosts
echo "$IPCOMPUTENODE compute" >> /etc/hosts 
echo "$IPNETWORKNODE network" >> /etc/hosts
echo ""

## Konfigurasi ssh-keygen (ssh tanpa password)
echo -e "[INFO] : configure ssh-keygen (ssh password-less)"
echo ""
sleep 5

echo -e "Just press the enter button"
echo ""
echo ""
sleep 2
ssh-keygen -t rsa
sleep 5

echo ""
echo -e "[INFO] : please insert password of Compute Node"
echo ""
ssh-copy-id -i ~/.ssh/id_rsa.pub root@compute
sleep 5
echo ""

echo ""
echo -e "[INFO] : please insert password of Network Node"
echo ""
ssh-copy-id -i ~/.ssh/id_rsa.pub root@network
sleep 5
echo ""

## Disable Firewall
echo -e "[INFO] : Disable firewall"
echo ""
sleep 5

echo -e "Disable firewall of Controller node"
systemctl disable firewalld
systemctl stop firewalld
systemctl status firewalld
echo ""

echo -e "Disable firewall of Compute node"
ssh root@compute -t "command; systemctl disable firewalld; systemctl stop firewalld; systemctl status firewalld"
sleep 2
echo ""

echo -e "Disable firewall of Network node"
ssh root@network -t "command; systemctl disable firewalld; systemctl stop firewalld; systemctl status firewalld"
sleep 2
echo ""

## Salin file /etc/hosts pada server lain
echo -e "[INFO] : copy file /etc/hosts to other nodes"
echo ""
sleep 5

ssh root@compute -t "command; cp /etc/hosts /etc/hosts-`date +%H-%M-%S-%d-%m-%Y`"
ssh root@network -t "command; cp /etc/hosts /etc/hosts-`date +%H-%M-%S-%d-%m-%Y`"
scp /etc/hosts root@compute:/etc/hosts
scp /etc/hosts root@network:/etc/hosts

## Konfigurasi hostname
echo -e "[INFO] : configure hostname"
echo ""
sleep 5

echo "controller" > /etc/hostname

ssh root@compute -t "command; echo 'compute' > /etc/hostname"

ssh root@network -t "command; echo 'network' > /etc/hostname"

## Konfigurasi Environment
echo -e "[INFO] : configure LC_CTYPE into Environment"
echo ""
sleep 5

echo LC_CTYPE="en_US.UTF-8" > /etc/environment

ssh root@compute -t "command; echo LC_CTYPE="en_US.UTF-8" > /etc/environment"
ssh root@network -t "command; echo LC_CTYPE="en_US.UTF-8" > /etc/environment"


## Salin repositori pada node lain
echo -e "[INFO] : copy repository packages to other nodes"
echo ""
sleep 5

ssh root@compute -t "command; mkdir -p /etc/yum.repos.d/repobak; mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/repobak/"
ssh root@network -t "command; mkdir -p /etc/yum.repos.d/repobak; mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/repobak/"

scp /etc/yum.repos.d/openstack.repo root@compute:/etc/yum.repos.d/openstack.repo
scp /etc/yum.repos.d/openstack.repo root@network:/etc/yum.repos.d/openstack.repo

scp -r $lokasi/ root@compute:$lokasi
scp -r $lokasi/ root@network:$lokasi

## Update repositori
echo -e "[INFO] : Update repository list"
echo ""
sleep 5

yum repolist
ssh root@compute -t "command; yum repolist"
ssh root@network -t "command; yum repolist"
sleep 5

## Upgrade OS CentOS 7
echo -e "[INFO] : Upgrading OS Controller Node"
echo ""
yum -y upgrade
sleep 5

echo -e "[INFO] : Upgrading OS Compute Node"
echo ""
ssh root@compute -t "command; yum -y upgrade"
sleep 5

echo -e "[INFO] : Upgrading OS Network Node"
echo ""
ssh root@network -t "command; yum -y upgrade"
sleep 5

## Install screen
yum install -y screen
ssh root@compute -t "command; yum install -y screen"
ssh root@network -t "command; yum install -y screen"

## Restart Semua node pasca upgrading OS
echo -e "[INFO] : Restart all nodes after upgrading OS"
echo ""
ssh root@compute -t "command; reboot"
ssh root@network -t "command; reboot"
reboot
