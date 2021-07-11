
echo "
  ___ __    ___   ___  ____  ___ __  ______        ___  ___  ___  __  __ ___  __ __  __    
 // \\||   // \\ // \\ || \\// \\||\ |||| \\       ||\\//|| // \\ ||\ ||// \\(( \||  ||   
 ||=||||  (( ___((   ))||_//||=||||\\||||  ))      || \/ ||((   ))||\\||||=|| \\ ||==||     
 || ||||__|\\_|| \\_// || \\|| |||| \||||_//       ||    || \\_// || \|||| ||\_))||  ||                                                                                                     
"
echo "    ___            ____                                       
     `MM           6MMMMb                                     
      MM          6M'    `                                     
  ____MM   ____   MM         ____  ___  __     ____     ____   
 6MMMMMM  6MMMMb  YM.       6MMMMb `MM 6MMb   6MMMMb  6MMMMb  
6M'  `MM 6M'  `Mb  YMMMMb  6M'  `Mb MMM9 `Mb MM'    ` 6M'  `Mb 
MM    MM MM    MM      `Mb MM    MM MM'   MM YM.      MM    MM 
MM    MM MMMMMMMM       MM MMMMMMMM MM    MM  YMMMMb  MMMMMMMM 
MM    MM MM             MM MM       MM    MM      Mb MM       
YM.  ,MM YM    d9 L    ,M9 YM    d9 MM    MM L    ,MM YM    d9 
 YMMMMMM_ YMMMM9  MYMMMM9   YMMMM9 _MM_  _MM_MYMMMM9   YMMMM9  
                                     
"

date '+ Running algorand-gitcoin-bounty-appasa | by @emg110 | %Y/%m/%d %H:%M:%S |'
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
