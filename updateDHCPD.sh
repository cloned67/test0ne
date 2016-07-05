#!/bin/sh

#################
# updateDHCPD.sh
#################

    _updateDHCPD    ()  {   # this is just a proof of concept script .. it should be done better
        mv /etc/dhcpd/dhcpd.conf /etc/dhcpd/dhcpd.conf.saved
        cp ~/dhcpd.new /etc/dhcp/dhcpd.conf
        chmod 644 /etc/dhcp/dhcpd.conf
        echo "Done."
    }


_updateDHCPD