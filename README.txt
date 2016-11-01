===== Preliminary =====

- Create 3 VM (Controller, Compute and Network Node) using CentOS 7 Minimal on the VMware vSphere

- Use CD Installer CentOS-7-x86_64-Minimal-1503-01.iso. The ISO file could be downloaded at this link : http://kambing.ui.ac.id/iso/centos/7.1.1503/isos/x86_64/CentOS-7-x86_64-Minimal-1503-01.iso

- Minimum requirement for the system :

Contoller Node : 1-2 GB RAM 
		: 10 GB Harddisk
		: 1 NIC

Compue Node	: 2 GB RAM
		: 10 GB Harddisk
		: 2 NIC

Network Node	: 512 MB RAM
		: 10 GB Harddisk
		: 3 NIC

- Configure network so that like below :

== Interface Management (Controller, Compute and Network node) using interface 1

Controller	: 192.168.11.21/24
Compute		: 192.168.11.22/24
Network		: 192.168.11.23/24
Gateway		: 192.168.11.11
DNS 1		: 192.168.11.11
DNS 2		: 8.8.8.8


- Please ensure Promiscuous Mode Network on the VMware in Accept Condition

- Edit VMX File in Compute Node for support KVM by adding line below :

vhv.enable = “TRUE”

- Starting VM and give an IP address temporer for ease access from SSH

ip addr add

===== Install and Configure Process =====

- Configure permanent address using nmtui


== IP Tunnel (Interface 2)

Compute		: 10.10.10.20/24
Network		: 10.10.10.30/24


- copy openstack-kilo.tgz into Controller Node

- extract openstack-kilo.tgz and configure repository by execute script

sh autoconfigure-repositori-EN.sh

- Please wait until done and restarting VM

- SSH into Controller Node and execute auto install openstack script

sh autoinstall-openstack-kilo-EN.sh

== Information

- Internal Networks for the instance vm

Network		: 172.16.10.0/24
Gateway		: 172.16.10.254

- check external interface on the network node by ip addr command. for example eth2 is external interface

- Public IP/Floating IP for communication with public network

Network			: 192.168.200.0/24
Gateway			: 192.168.200.254
First allocation	: 192.168.200.1
End allocation		: 192.168.200.253

- Check Processor supporting KVM or not on the Compute Node

egrep -c ‘(vmx|svm)’ /proc/cpuinfo

Note : If the result is 1 or bigger, Compute node support KVM. If 0 (zero), the Compute node is not support KVM


===== End Installation =====

- Test create Instance

- Test give Floating IP

- Test open ICMP connection

- Test open SSH connection


===== Good Luck =====
