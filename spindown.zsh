#!/usr/local/bin/zsh
 
timeout=$((60*60))
typeset -A timeouts
 
iostat -x 1 \
| stdbuf -o L egrep '^a?da' \
| while read device rs ws kr kw qlen svct b; do
        if [[ "${kr}" == "0.0" && "${kw}" == "0.0" ]]; then
                timeouts[${device}]=$((timeouts[${device}]+1))
        else
                timeouts[${device}]=0
        fi
 
        if [[ ${timeouts[${device}]} -eq ${timeout} ]]; then
                echo "$(date +'%Y-%m-%d %T') spindown ${device}"
                case ${device} in
                        ada*)
                                camcontrol standby ${device}
                                ;;
                        da*)
                                camcontrol stop ${device}
                                ;;
                esac
        fi
done
