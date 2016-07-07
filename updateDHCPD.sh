#!/bin/sh

#################
# updateDHCPD.sh
#################

#$ shellcheck myscript
#No issues detected!


    _updateDHCPD    ()  {   # this is just a proof of concept script .. it should be done better
        mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.saved
        cp ~/dhcpd.new /etc/dhcp/dhcpd.conf
        chmod 644 /etc/dhcp/dhcpd.conf
        echo "Done."
    }


_updateDHCPD