#!/bin/sh	

#################
# updateDHCPD.sh
#################

	_updateDHCPD	()	{
		mv /etc/dhcpd/dhcpd.conf /etc/dhcpd/dhcpd.conf.saved 
        cp ~/dhcpd.new /etc/dhcp/dhcpd.conf
		chmod 644 /etc/dhcp/dhcpd.conf
	    echo "Done." 
	}


_updateDHCPD