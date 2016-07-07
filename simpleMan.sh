#!/bin/bash

##############
# simpleMan.sh
##############

# shellcheck disable=SC2086
# shellcheck disable=SC2034

    _simpleMan          ()  {   # ensures the entire script is downloaded first!

        #--------------------------------------------------
        _noop               ()  {   #   does nothing
            :   #
        }

        _dbg                ()  {   #   handy debug helper
            :   #       
            printf %s\\n "$*" 2>/dev/null
        }

        _log                ()  {   #   handy log   wrapper
             printf %s\\n "$*" 2>/dev/null
        }

        _warn               ()  {   #   handy warn  wrapper
            _log "WARNING: $*"
        }

        _err                ()  {   #   handy error wrapper
            >&2 _log "ERROR: $*"
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
        _stop_apache        ()  {   #   stop apache service
             res=$(ssh $SSH_USER@$TARGET_HOST $SRVC $APACHE stop)
            _dbg "$res"
        }

        _start_apache       ()  {   #   start apache service
             res=$(ssh $SSH_USER@$TARGET_HOST $SRVC $APACHE start)
            _dbg "$res"
        }

        _host_required      ()  {   #   checks if host is specified or saved
            TARGET_HOST=$HOST
            if [ -z $TARGET_HOST ]; then
                _warn "no target host specified!"
                exit 123
            fi
            _log "Host: " $TARGET_HOST
        }

        _parse_options      ()  {   #   parse command line arguments

            while [ $# -gt 0 ];
            do
                local key=$1

                shift  #skip opt
                case $key in

                    -v|--verbose)
                                VERBOSE=1
                                _dbg "verbose enabled"
                    ;;

                    -p|--pass)
                                PASS=$1
                                _dbg "password set"
                                shift # skip arg
                    ;;

                    -u|--user)
                                SSH_USER=$1
                                _dbg "user: $SSH_USER"
                                shift #skip arg
                    ;;

                    -ra|--apache-reload)
                                RELOAD_APACHE=1
                    ;;

                    -rd|--dhcpd-restart)
                                RESTART_DHCPD=1
                    ;;

                    -h|--hst|--host)                    # target host

                                HOST=$1
                                shift # skip arg
                        _dbg "HOST:" $HOST
                        echo $HOST >$HST                # save host to file cache
                    ;;

                    -en|--enbl|--enable)                # enable site
                                ENABLE_SITE=$1
                                shift # skip arg
                        _dbg "ENABLE:" $ENABLE_SITE
                    ;;

                    -dis|--dsbl|--disable)              # disable site
                                DISABLE_SITE=$1
                                shift # skip arg
                    ;;

                    -o|--dhopt|--dhcp-opt|--dhcp-option)                # modify  a DHCP option
                                DHCP_OPTION=$*
                                break;
                    ;;    
                    -oa|--add-dhopt|--add-dhcp-opt|--add-dhcp-option)   # add new   DHCP option
                                DHCP_OPT_ADD=1
                                DHCP_OPTION=$*
                                break;
                    ;;                    
                    -od|--del-dhopt|--del-dhcp-opt|--del-dhcp-option)   # delete  a DHCP option
                                DHCP_OPT_DEL=1
                                DHCP_OPTION=$*
                                break;
                    ;;

                    *)                                  # unknown option
                                _usage $key
                                break;
                    ;;

                esac

            done  # while $ARGN
        }

        _do_enable          ()  {   #   enables an Apache2 site by using the perl script a2ensite
            _log "trying to enable:  $* at $TARGET_HOST::"
            ssh -t $SSH_USER@$TARGET_HOST "sudo $A2ENS $*"
            _log "$res"
            #RELOAD_APACHE=1
        }

        _do_disable         ()  {   #   enables an Apache2 site by using the perl script a2ensite
            _log "trying to disable:  $* at $TARGET_HOST::"
            ssh -t $SSH_USER@$TARGET_HOST "sudo $A2DIS $*"
            #RELOAD_APACHE=1
        }

        _do_reload_apache   ()  {   #   reloads apache 2 service
            _log "reloading Apache::"
            ssh -t $SSH_USER@$TARGET_HOST "sudo $SRVC $APACHE reload"
        }

        _do_restart_DHCP    ()  {   #   reloads DHCP server
            _log "reloading DHCP server::"
            ssh -t $SSH_USER@$TARGET_HOST "sudo $SRVC $DHCPD  restart"
        }

        _do_set_dhcp_option ()  {   #   change or add a line in the DHCP configuration file by parsing it
                                    #   we can parse the file much better [[ TO DO ..]]
            _newFile    ()  {
             printf ""      >  $FILE
             printf ""      >  $CHNG_FILE
            }
            _wrFile     ()  {
             printf "%s\n" "$*"  >> $FILE
            }
            _chngd      ()  {
             printf "%s\n" "$*"  >  $CHNG_FILE
            }
            _log "trying to set DHCP line: '$*'"
            res=$(ssh $SSH_USER@$TARGET_HOST $CAT $DHCP_CFG >dhcpd.tmp)
            res=$(<dhcpd.tmp)

            local       opt=$*
            local      FILE="dhcpd.new"
            local CHNG_FILE="dhcpd.chng"
            local tkns
            local tknn
            local lp
            local last

            _newFile        # open file

            printf %s "$res" | while IFS= read -r line
            do
                line=$(printf "%s" "${line}" | sed -e 's/^[[:space:]]*//')   # remove leading space
                tkns=($line)
                tknn=${#tkns[@]}
                if [ $tknn -lt 1 ]; then                                # skip empty lines but save them to file
                 _wrFile
                 continue;
                fi
                lp=$((tknn - 1))                                        # last token idx
                last=${tkns[${lp}]}                                     # last token value
                case "${tkns[0]}" in
                    \#*)
                                _wrFile "${line}"                       # write comment line to file
                                continue                                # skip comment line
                        ;;
                    option)                                             # special case
                                                                        #   if first token start with option
                                                                        #   then should match also option name ..
                        case ${tkns[1]} in
                            $2)
                                _chngd  "$line"
                                _dbg    "[] ${line} ]"
                                if [ $DHCP_OPT_DEL ]; then
                                    _warn "[${line}] has been deleted!"
                                else
                                    _wrFile " ${opt};"                  # change line
                                fi    
                                ;;
                             *)                                         # no full match (skip)
                                _dbg    "${line}"
                                _wrFile "${line}"                       # write original line to file
                                ;;
                        esac
                        ;;
                    $1)                                                 # DHCP parameter MATCH ...
                                                                        # check if ends with ';'
                                _chngd  "$line"
                                _dbg    "[ ${line} ]"
                                if [ $DHCP_OPT_DEL  ]; then
                                    _warn "[${line}] has been deleted!"
                                else
                                    _wrFile " ${opt};"                  # change line
                                fi    
                        ;;
                    *)                                                  # no full match (skip)
                                _dbg    "$line"
                                _wrFile "${line}"                       # write original line to file
                        ;;
                esac
            done
            res="$($CAT $CHNG_FILE)"
            if [ $DHCP_OPT_ADD ]; then
                if [ ${#res} -gt 0 ]; then
                    _warn "can't add option line, already exist: $res (delete it first)"
                    res=                                                #not changed
                else
                    _warn "adding new line: ${opt}"
                    res=" ${opt};"                                      # add new line
                    _wrFile $res 
                    _wrFile                                             # just in case !
                fi   
            fi
            if [ $DHCP_OPT_DEL ]; then
                if [ ${#res} -eq 0 ]; then
                    _warn "can't find option for: $opt (sorry)"
                fi
            fi
            if [ ${#res} -gt 0 ]; then
                _dbg "changed: $res"
               
                _dbg "sending file to home dir"
                scp $FILE $SSH_USER@$TARGET_HOST:~/                         # send file to home
                res=$(ssh $SSH_USER@$TARGET_HOST $CAT $DHCP_SCR >script.tmp)
                res=$(<script.tmp)
                if [ ${#res} -eq 0 ]; then
                 _log "missing script sending it along .."
                 scp $DHCP_SCR $SSH_USER@$TARGET_HOST:~/                    # send script along
                 ssh -t $SSH_USER@$TARGET_HOST  sudo chmod 744 $DHCP_SCR    # make it executable
                fi
                                                                            # call script to do
                                                                            # all things remoteley
                _dbg "invoking $DHCP_SCR remote"
                ssh -t $SSH_USER@$TARGET_HOST  sudo ./$DHCP_SCR
            else 
                _log "can't find $opt"
            fi

        }

        local       CD="$PWD"
        local      CMD="$0"
        local       ME=${CMD##*/}
        local      HST=${ME%.*}.cfg
        local     ARGN=$#
        local      PID=$$


        local      CAT='cat'
        local    A2ENS='a2ensite'
        local    A2DIS='a2dissite'
        local   APACHE='apache2'
        local    DHCPD='isc-dhcp-server'
        local     SRVC='service'
        local DHCP_CFG='/etc/dhcp/dhcpd.conf'
        local DHCP_SCR='updateDHCPD.sh'

        local   res
        local   line

        local   SSH_USER
        local   VERBOSE
        local   PASS
        local   HOST
        local   ENABLE_SITE
        local   DISABLE_SITE
        local   RELOAD_APACHE
        local   RESTART_DHCPD
        local   DHCP_OPTION
        local   DHCP_OPT_ADD
        local   DHCP_OPT_DEL
        local   TARGET_HOST

        SSH_USER=$(whoami)

        _dbg "hello I'm " $ME  "running in:" $CD
        _dbg "with pid :" $PID "num args  :" $ARGN
        _dbg "user: "     $SSH_USER

        if [ $ARGN -lt 1 ]; then
            _usage
        fi

        _parse_options "$@"



        if [ $ENABLE_SITE ];then            # enable site if specified
            _host_required
            _do_enable $ENABLE_SITE
        fi

        if [ $DISABLE_SITE ]; then          # disable site if specified
            _host_required                  # (executed after so it will be finally disable
            _do_disable $DISABLE_SITE       #  if you specify it to enable as well )
        fi

        if [ $RELOAD_APACHE ]; then         # do we need to reload Apache ?
            _host_required
            _do_reload_apache
        fi

        if [ "$DHCP_OPTION" ]; then
            _host_required
            _do_set_dhcp_option $DHCP_OPTION
        fi

        if [ $RESTART_DHCPD ]; then         # do we need to restart DHCP ?
            _host_required
            _do_restart_DHCP
        fi

    }

##  ========================================================================

_simpleMan "$@"


