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
            local res=$($SRVC $APACHE stop)
            _dbg $res
        }

        _start_apache       ()  {
            local res=$($SRVC $APACHE start)
            _dbg $res
        }

        _reload_apache      ()  {
            _log $SRVC $APACHE reload
            $($SRVC $APACHE reload >reload.log)
            _dbg $($CAT reload.log | sed 's/[][*}{]/\\&/g')
        }

    _parse_options      ()  {   #   parse command line arguments
      while [ $# -gt 1 ];
       do 
        local key=$1 
        
        shift  #skip opt                 
        case $key in
        
            -v|--verbose)
                VERBOSE=1
            ;;
            
            -p|--pass)
                PASS=$1
                shift # skip arg
            ;;
            
            -h|--hst|--host)                            # target host
            
                HOST=$1
                shift # skip arg
                _dbg "HOST:" $HOST
                echo $HOST >$HST
            ;;
            
            -en|--enbl|--enable)                        # enable site
            
                ENABLE_SITE=$1
                shift # skip arg
                _dbg "ENABLE:" $ENABLE_SITE
            ;;
            
            -dis|--dsbl|--disable)                        # disable site
            
                DISABLE_SITE=$1
                shift # skip arg
            ;;
            
            -o|--dhopt|--dhcp_opt|--dhcp_option)        # DHCP option
            
                DHCP_OPTION=$@
                break;
            ;;
            
            *)                                          # unknown option
            
                _usage $key
                break;
            ;;
            
        esac
        
      done  # while $ARGN  
    }

    _do_enable          ()  {   #   enables an Apache2 site by using the perl script a2ensite
        _dbg "trying to enable: " $@
        res=$($A2ENS $@)
        _log $res
        RELOAD_APACHE=1
    }
    
    _do_disable         ()  {   #   enables an Apache2 site by using the perl script a2ensite
        _dbg "trying to disable: " $@
        res=$($A2DIS $@)
        _log $res
        RELOAD_APACHE=1
    }
    
    _do_set_dhcp_option ()  {   #   change or add a line in the DHCP configuration file by parsing it
        _dbg "trying to set DHCP: " $@
    }
    
        local       CD=$PWD
        local      CMD=$0
        local       ME=${CMD##*/}
        local      HST=${ME%.*}.cfg
        local     ARGN=$#
        local      PID=$$

        #_dbg "hello I'm " $ME "running in:" $CD
        #_dbg "with pid:" $PID "num args:" $ARGN


        local      CAT='cat'
        local    A2ENS='a2ensite'
        local    A2DIS='a2dissite'
        local   APACHE='apache2'
        local     SRVC='service'
        local     USER='devel'
        
        _parse_options $@
        
        # enable site if specified
        if [ $ENABLE_SITE ];then
            _do_enable $ENABLE_SITE
        fi

        # disable site if specified
        # (executed after so it will be finally disable if you specify it to enable as well )
        if [ $DISABLE_SITE ]; then
            _do_disable $DISABLE_SITE
        fi

        if [ $RELOAD_APACHE ]; then
            _reload_apache
        fi
        
        
    }

##  ========================================================================

_simpleMan $@
