#!/bin/sh
##############
# simpleMan.sh
##############

#   ssh devel@hostB '(ls /etc/apache2/sites-available)' > sites.cfg
#   ssh devel@hostC '(cat /etc/dhcp/dhcpd.conf)'        > dhcpd.cfg

    _simpleMan          ()  {   # ensures the entire script is downloaded first!
        #--------------------------------------------------
        _dbg                ()  {   #   handy debug helper
            : #
            command printf %s\\n "$*" 2>/dev/null
        }

        _log                ()  {   #   handy log   wrapper
            command printf %s\\n "$*" 2>/dev/null
        }

        _warn               ()  {   #   handy warn  wrapper
            _log "WARNING:" $@
        }

        _err                ()  {   #   handy error wrapper
            >&2 _log "$@"
        }

        #--------------------------------------------------
        _usage              ()  {   #   shows usage example
            if [ $# -eq 1 ]; then
                _err "unknown option: " $1;
            fi
_log "
      Usage:
            $ME [--host <host>]
                         [--enable <site>]
                         [--disable <site>]
                         [--dhcp_option <option line>]
"
            exit 666
        }
        #--------------------------------------------------
        _stop_apache        ()  {
            res=$($SRVC $APACHE stop)
            _dbg $res
        }

        _start_apache       ()  {
            res=$($SRVC $APACHE start)
            _dbg $res
        }

        _reload_apache      ()  {
            _log $SRVC $APACHE reload
            res=$($SRVC $APACHE reload)
            _dbg $res
        }

        local       CD=$PWD
        local      CMD=$0
        local       ME=${CMD##*/}
        local      HST=${ME%.*}.cfg
        local     ARGN=$#
        local      PID=$$

        local      CAT='cat'
        local    A2ENS='a2ensite'
        local    A2DIS='a2dissite'
        local   APACHE='apache2'
        local     SRVC='service'
        local     USER='devel'

        _usage
    }

##  ========================================================================

_simpleMan $@
