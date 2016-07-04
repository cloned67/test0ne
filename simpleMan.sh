#!/bin/sh
##############
# simpleMan.sh
##############

ssh devel@hostB '(ls /etc/apache2/sites-available)'	> sites.cfg
ssh devel@hostC '(cat /etc/dhcp/dhcpd.conf)' 		> dhcpd.cfg


