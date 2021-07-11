echo "
  ___ __    ___   ___  ____  ___ __  ______        ___  ___  ___  __  __ ___  __ __  __    
 // \\||   // \\ // \\ || \\// \\||\ |||| \\       ||\\//|| // \\ ||\ ||// \\(( \||  ||   
 ||=||||  (( ___((   ))||_//||=||||\\||||  ))      || \/ ||((   ))||\\||||=|| \\ ||==||     
 || ||||__|\\_|| \\_// || \\|| |||| \||||_//       ||    || \\_// || \|||| ||\_))||  ||
                                                                                                        
"
date '+ Running desense | by @emg110 | %Y/%m/%d %H:%M:%S |'
echo "----------------------------------------------------------------------------"
echo "                       "
set -o pipefail
export SHELLOPTS
set -e
#set -x



goalcli="../sandbox/sandbox goal"
tealdbgcli="../sandbox/sandbox tealdbg"
sandboxcli="../sandbox/sandbox"
ACC=$( ${goalcli} account list | awk '{ print $3 }' | tail -1)
APPROVAL_PROG="./desense-application-statefull.teal"
CLEAR_PROG="./desense-clear-prog.teal"
ESCROW_PROG="./desense-escrow-stateless.teal"
