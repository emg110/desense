
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

date '+ Running deSense | by @emg110 | %Y/%m/%d %H:%M:%S |'
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

case $1 in
install)
echo "Installing sandbox environment"
cd "../" && git clone https://github.com/algorand/sandbox
echo "Algorand Sandbox installed in parent folder (Beside current folder)"
cd desense
;;
reset)
echo "Reseting sandbox environment"
rm -f desense-id.txt
rm -f desense-escrow-stateless.txt
rm -f desense-escrow-account.txt
rm -f desense-main-account.txt
$sandboxcli reset
;;
stop)
echo "Stopping sandbox environment"
$sandboxcli down
;;
start)
echo "Starting sandbox environment"
$sandboxcli up
;;
asc)
rm -f desense-id.txt
rm -f desense-escrow-stateless.txt
rm -f desense-escrow-account.txt
rm -f desense-main-account.txt
cp "$APPROVAL_PROG" "$CLEAR_PROG" ../sandbox
$sandboxcli copyTo "$APPROVAL_PROG"
$sandboxcli copyTo "$CLEAR_PROG"
APP=$(
  ${goalcli} app create --creator "${ACC}" --clear-prog "$CLEAR_PROG" --approval-prog "$APPROVAL_PROG" \
    --global-byteslices 1 \
    --local-byteslices 0 \
    --global-ints 1 \
    --local-ints 0 |
    grep Created |
    awk '{ print $NF }'
)
echo -ne "${APP}" > "desense-id.txt"
cat $ESCROW_PROG | awk -v awk_var=${APP} '{ gsub("appIdParam", awk_var); print}' > "desense-escrow-stateless.teal"
ESCROW_PROG_SND="desense-escrow-stateless.teal"
$sandboxcli copyTo "$ESCROW_PROG_SND"
ESCROW_ACCOUNT=$(
  ${goalcli} clerk compile -a ${ACC} -n ${ESCROW_PROG_SND} | awk '{ print $2 }' | head -n 1
)
echo -ne "${ACC}" > "desense-main-account.txt"
echo -ne "${ESCROW_ACCOUNT}" > "desense-escrow-account.txt"
echo "Stateful Application ID $APP"
echo "Stateless Escrow Account = ${ESCROW_ACCOUNT}"
;;
fund)
AMOUNT=$2
MAIN_ACC=$(<desense-main-account.txt)
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
${goalcli} clerk send -a ${AMOUNT} -f "${MAIN_ACC}" --to ${ESCROW_ACC_TRIM}
;;
escrowbal)
echo "Getting the escrow account balance..."
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
echo "Escrfow account:$ESCROW_ACC_TRIM" 
${goalcli} account balance -a $ESCROW_ACC_TRIM
;;
mainbal)
echo "Getting the main account balance..."
MAIN_ACC=$(<desense-main-account.txt)
echo "Main account:$MAIN_ACC" 
${goalcli} account balance -a $MAIN_ACC
;;
escrow)
echo "Getting the escrow account info..."
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
echo "Escrow account:$ESCROW_ACC_TRIM" 
${goalcli} account info -a $ESCROW_ACC_TRIM
;;
main)
echo "Getting the main account info..."
MAIN_ACC=$(<desense-main-account.txt)
echo "Main account:$MAIN_ACC" 
${goalcli} account info -a $MAIN_ACC
;;
link)
echo "Linking stateless escrow account to stateful smart contract"
MAIN_ACC=$(<desense-main-account.txt)
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
ESCROW_ACC_TRIMM="${ESCROW_ACC//$'\n'/ }"
APP_ID=$(cat "desense-id.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
APP_ID_TRIM="${APP_ID//$'\r'/ }"
echo "Escrow account: $ESCROW_ACC_TRIMM"
echo "Main account:$MAIN_ACC"
echo "Application ID:$APP_ID_TRIM"
${goalcli} app call --app-id ${APP_ID_TRIM} --app-arg "str:escrow_set" --app-arg "addr:${ESCROW_ACC_TRIMM}" -f ${MAIN_ACC}
${goalcli} app read --app-id ${APP_ID_TRIM} --guess-format --global --from ${MAIN_ACC}
;;
asa)
echo "Generating SENSE Standard Asset..."

MAIN_ACC=$(<desense-main-account.txt)
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
APP_ID=$(cat "desense-id.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
APP_ID_TRIM="${APP_ID//$'\r'/ }"
ESCROW_PROG_SND="desense-escrow-stateless.teal"
$sandboxcli copyTo "$ESCROW_PROG_SND"
echo "Escrow account: $ESCROW_ACC_TRIM"
echo "Main account: $MAIN_ACC"
echo "Application ID:$APP_ID_TRIM"
echo "The asset name: SENSE"
${goalcli} app call --app-id ${APP_ID_TRIM} --app-arg "str:asa_cfg" -f ${MAIN_ACC} -o trx-call-app-unsigned.tx
$sandboxcli copyFrom "trx-call-app-unsigned.tx"
${goalcli} asset create --creator ${ESCROW_ACC_TRIM} --name "SENSE" --total 99999999 --decimals 0 -o trx-create-asa-unsigned.tx
$sandboxcli copyFrom "trx-create-asa-unsigned.tx"
cat trx-call-app-unsigned.tx trx-create-asa-unsigned.tx > trx-array-asa-unsigned.tx
$sandboxcli copyTo "trx-array-asa-unsigned.tx"
${goalcli} clerk group -i trx-array-asa-unsigned.tx -o group-trx-asa-unsigned.tx
$sandboxcli copyFrom "group-trx-asa-unsigned.tx"
${goalcli} clerk split -i group-trx-asa-unsigned.tx -o trx-asa-unsigned-index.tx
$sandboxcli copyFrom "trx-asa-unsigned-index-0.tx"
$sandboxcli copyFrom "trx-asa-unsigned-index-1.tx"
${goalcli} clerk sign -i trx-asa-unsigned-index-0.tx -o trx-asa-signed-index-0.tx
$sandboxcli copyFrom "trx-asa-signed-index-0.tx"
${goalcli} clerk sign -i trx-asa-unsigned-index-1.tx -p ${ESCROW_PROG_SND} -o trx-asa-signed-index-1.tx
$sandboxcli copyFrom "trx-asa-signed-index-1.tx"
cat trx-asa-signed-index-0.tx trx-asa-signed-index-1.tx > trx-group-asa-signed.tx
$sandboxcli copyTo "trx-group-asa-signed.tx"
echo "Sending signed transaction group with clerk..."
${goalcli} clerk rawsend -f trx-group-asa-signed.tx
rm -f *.tx
rm -f *.rej
rm -f awk
rm -f head
rm -f *.scratch
rm -f *.json
rm -f sed
;;

dryrun)
echo "Creating Dry-run dump from signed transaction group..."
${goalcli} clerk dryrun -t trx-group-asa-signed.tx --dryrun-dump -o trx-group-asa-signed-dryrun.json
$sandboxcli copyFrom "trx-group-asa-signed-dryrun.json"
echo "Dryrun dump JSON file generated successfully!"
;;

drapproval)
echo "Dry-running signed approval program with signed transaction group ..."
${goalcli} clerk dryrun -t trx-group-asa-signed.tx --dryrun-dump -o trx-group-asa-signed-dryrun.json
$sandboxcli copyFrom "trx-group-asa-signed-dryrun.json"
cd "../" && docker exec -it algorand-sandbox-algod  tealdbg debug ${APPROVAL_PROG} -f cdt --listen 0.0.0.0 -d trx-group-asa-signed-dryrun.json --group-index 0
echo "The Dry run JSON file is running to check Approval Smart Contract"
cd desense


;;
drescrow)
echo "Dry-running signed approval program with signed transaction group..."
${goalcli} clerk dryrun -t trx-group-asa-signed.tx --dryrun-dump -o trx-group-asa-signed-dryrun.json
$sandboxcli copyFrom "trx-group-asa-signed-dryrun.json"
cd "../" && docker exec -it  algorand-sandbox-algod tealdbg debug ${ESCROW_PROG_SND} -f cdt --listen 0.0.0.0 -d trx-group-asa-signed-dryrun.json
echo "The Dry run JSON file is running to check Stateful Approval Smart Contract..."
cd desense
;;

axfer)
ASSET_ID=0

echo "Receiving Standard Asset..."
MAIN_ACC=$(<desense-main-account.txt)
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
APP_ID=$(cat "desense-id.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
APP_ID_TRIM="${APP_ID//$'\r'/ }"


ASSET_ID=$(${goalcli} account info -a ${ESCROW_ACC_TRIM} | grep ID | head -n 1 | awk '{ print $2 }')
    echo "The Asset ID selected by auto mode is: ${ASSET_ID%?}"

echo "Escrow account: $ESCROW_ACC_TRIM"
echo "Application ID:$APP_ID_TRIM"
echo "The asset ID of SENSE, of which 1 (one) unit (SNS) will be transfered to main account: ${ASSET_ID%?}"

ESCROW_PROG_SND="desense-escrow-stateless.teal"
${goalcli} asset send --assetid ${ASSET_ID%?} -f ${MAIN_ACC} -t ${MAIN_ACC} -a 0
${goalcli} app call --app-id ${APP_ID_TRIM} --app-arg "str:asa-xfer" -f ${MAIN_ACC} -o trx-get-asa-unsigned.tx
$sandboxcli copyFrom "trx-get-asa-unsigned.tx"
${goalcli} asset send --assetid ${ASSET_ID%?} -f ${ESCROW_ACC_TRIM} -t ${MAIN_ACC} -a 1 -o trx-send-asa-unsigned.tx
$sandboxcli copyFrom "trx-send-asa-unsigned.tx"
cat trx-get-asa-unsigned.tx trx-send-asa-unsigned.tx > trx-array-asa-transfer-unsigned.tx
$sandboxcli copyTo "trx-array-asa-transfer-unsigned.tx"
${goalcli} clerk group -i trx-array-asa-transfer-unsigned.tx -o trx-group-asa-transfer-unsigned.tx
$sandboxcli copyFrom "trx-group-asa-transfer-unsigned.tx"
${goalcli} clerk split -i trx-group-asa-transfer-unsigned.tx -o trx-asa-transfer-unsigned-index.tx
${goalcli} clerk sign -i trx-asa-transfer-unsigned-index-0.tx -o trx-asa-transfer-signed-index-0.tx
${goalcli} clerk sign -i trx-asa-transfer-unsigned-index-1.tx -p ${ESCROW_PROG_SND} -o trx-asa-transfer-signed-index-1.tx
$sandboxcli copyFrom "trx-asa-transfer-signed-index-0.tx"
$sandboxcli copyFrom "trx-asa-transfer-signed-index-1.tx"
cat trx-asa-transfer-signed-index-0.tx trx-asa-transfer-signed-index-1.tx > trx-group-asa-transfer-signed.tx
$sandboxcli copyTo "trx-group-asa-transfer-signed.tx"
echo "Transfering one unit of deSense with clerk"
${goalcli} clerk rawsend -f trx-group-asa-transfer-signed.tx 
rm -f *.tx
rm -f *.rej
rm -f awk
rm -f head
rm -f *.scratch
rm -f *.json
rm -f sed
;;
trxlist)
echo "listing transactions..."
curl "localhost:8980/v2/transactions?pretty"
;;

status)
echo "Getting node status from goal..."
${goalcli}  node status
;;
help)
echo "deSense Guid:"
echo "                "
echo "Step by step process flow:"
echo "                "
echo "1- ./desense.sh asc" 
echo "To create deSense stateful smart contract application and stateless smart contract escrow sccount" 
echo "                "
echo "2- ./desense.sh fund AMOUNT"
echo "To send funds (equal to AMOUNT) to deSense escrow account from main account" 
echo "                "
echo "3- ./desense.sh link"
echo "To link deSense stateful contract application with deSense stateless contract escrow account" 
echo "                "
echo "4- ./desense.sh asa"
echo "To generate SENSE Algorand standard asset" 
echo "                "
echo "5- ./desense.sh escrow"
echo "To check the escrow SENSE asset" 
echo "                "
echo "                "
echo "6- ./desense.sh axfer 'ID' or 'auto'"
echo "To transfer (receive) one unit of standard asset with ID (e.g 5). set 'auto' to make everything automated" 
echo "                "
echo " -------------------------------------------------               "
echo "Sandbox commands:"
echo "                "
echo "./desense.sh install" 
echo "Installs the sandbox instance" 
echo "                "
echo "./desense.sh reset"
echo "Resets the sandbox instance" 
echo "                "
echo "./desense.sh start"
echo "Starts the sandbox instance" 
echo "                "
echo "./desense.sh stop"
echo "Stops the sandbox instance" 
echo "                "
echo "--------------------------------------------------             "
echo "Other usefull commands:"
echo "                "
echo "./desense.sh main" 
echo "Show main account's info" 
echo "                "
echo "./desense.sh escrow"
echo "Show generated escrow account's info" 
echo "                "
echo "./desense.sh mainbal"
echo "Show main account's balance" 
echo "                "
echo "./desense.sh escrowbal"
echo "Show generated escrow account's balance" 
echo "                "

;;
*)
echo "Welcome deSense, a partiucipation to Monash University-Algorand Blockchain Hackathon 2021 "
echo "This repository contains educational (DO NOT USE IN PRODUCTION!) code and content in response to Monash University-Algorand Blockchain Hackathon 2021"
;;
esac