
echo "
   _       ___                    
 _| | ___ / __> ___ ._ _  ___ ___ 
/ . |/ ._>\__ \/ ._>| ' |<_-</ ._>
\___|\___.<___/\___.|_|_|/__/\___.
                                  
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
function getJsonVal () { 
    python -c "import json,sys;sys.stdout.write(json.dumps(json.load(sys.stdin)$1, sort_keys=True, indent=4))"; 
}
case $1 in
install)
if [[ ! -d "../sandbox" ]]
then
    echo "Installing Algorand SandBox environment"
    git clone https://github.com/algorand/sandbox.git ../sandbox
    echo "Algorand SandBox installed successfully in parent folder (Beside current folder)"
else
  echo "Algorand SandBox is installed OK!"
fi
if [[ ! -f "/usr/local/bin/sampler" ]]
then
    echo "Installing Sampler Dashboard environment"
    sudo wget https://github.com/sqshq/sampler/releases/download/v1.1.0/sampler-1.1.0-linux-amd64 -O /usr/local/bin/sampler
    sudo chmod +x /usr/local/bin/sampler
    echo "Sampler Dashboard successfully in /usr/local/bin as a program"
else
  echo "Sampler Dashboard is installed OK!"
fi
if [[ ! -d "../sensor-emulator" ]]
then
    echo "Installing Sensor Emulator environment"
    git clone https://github.com/emg110/sensor-emulator.git ../sensor-emulator
    cd ../sensor-emulator
    chmod +x emulator.sh
    ./emulator.sh --h
    cd ../desense
    echo "Sensor Emulator installed successfully in parent folder (Beside current folder)"
else
  echo "Sensor Emulator is installed OK!"
fi
if [[ ! -d "../emitter" ]]
then
    echo "Installing EmitterIO"
    git clone https://github.com/emitter-io/emitter ../emitter
 
    cd ../emitter
    go build
    cd ../desense
    ../emitter/emitter
    echo "EmitterIO installed successfully in parent folder (Beside current folder)"
else
  echo "EmitterIO is installed OK!"
fi

;;
reset)
echo "Reseting sandbox environment"
rm -f desense-id.txt
rm -f desense-escrow-stateless.txt
rm -f desense-escrow-account.txt
rm -f desense-escrow-prog-snd.teal
rm -f desense-main-account.txt
$sandboxcli reset
;;
stop)
echo "Stopping sandbox environment"
$sandboxcli down
;;
startsandbox)
echo "Starting sandbox environment"
$sandboxcli up
;;
startemitter)
echo "Starting EmitterIO environment"

../emitter/emitter
;;
startemulator)
echo "Starting Sensor Emulator environment"
echo "If this is the first run, the generated license and secret key are shown, please take note of them both and open your browser and go to http://127.0.0.1:8080/keygen and generate channels and channel keys using the secret key you just noted. Do not forget to set EMITTER_LICENSE env variable before start after this run which gave you the keys to make the generated license work!"
cp sensor-template-config.json ../sensor-emulator
cd ../sensor-emulator && ./emulator.sh --DS --run  --config-file=sensor-template-config.json
;;
startsampler)
echo "Starting Sensor Sampler environment"
sampler -c ./desense-dashboard.yml
;;
asc)
rm -f desense-id.txt
rm -f desense-escrow-stateless.txt
rm -f desense-escrow-account.txt
rm -f desense-escrow-prog-snd.teal
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
cat $ESCROW_PROG | awk -v awk_var=${APP} '{ gsub("appIdParam", awk_var); print}' | awk -v awk_var=${ACC} '{ gsub("SENSEAddr", awk_var); print}' > "desense-escrow-stateless-snd.teal"
ESCROW_PROG_SND="desense-escrow-stateless-snd.teal"
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
sense)
echo "Generating SENSE Standard Asset..."

MAIN_ACC=$(<desense-main-account.txt)
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
APP_ID=$(cat "desense-id.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
APP_ID_TRIM="${APP_ID//$'\r'/ }"
ESCROW_PROG_SND="desense-escrow-stateless-snd.teal"
$sandboxcli copyTo "$ESCROW_PROG_SND"
echo "Escrow account: $ESCROW_ACC_TRIM"
echo "Main account: $MAIN_ACC"
echo "Application ID:$APP_ID_TRIM"
echo "The asset name: SENSE"
${goalcli} app call --app-id ${APP_ID_TRIM} --app-arg "str:sense_cfg" -f ${MAIN_ACC} -o trx-call-app-unsigned.tx
$sandboxcli copyFrom "trx-call-app-unsigned.tx"
${goalcli} asset create --creator ${ESCROW_ACC_TRIM} --name "SENSE" --total 999999999999999 --asseturl "https://github.com/emg110/desense" --unitname "SNS" --decimals 6 -o trx-create-sense-unsigned.tx
$sandboxcli copyFrom "trx-create-sense-unsigned.tx"
cat trx-call-app-unsigned.tx trx-create-sense-unsigned.tx > trx-array-sense-unsigned.tx
$sandboxcli copyTo "trx-array-sense-unsigned.tx"
${goalcli} clerk group -i trx-array-sense-unsigned.tx -o group-trx-sense-unsigned.tx
$sandboxcli copyFrom "group-trx-sense-unsigned.tx"
${goalcli} clerk split -i group-trx-sense-unsigned.tx -o trx-sense-unsigned-index.tx
$sandboxcli copyFrom "trx-sense-unsigned-index-0.tx"
$sandboxcli copyFrom "trx-sense-unsigned-index-1.tx"
${goalcli} clerk sign -i trx-sense-unsigned-index-0.tx -o trx-sense-signed-index-0.tx
$sandboxcli copyFrom "trx-sense-signed-index-0.tx"
${goalcli} clerk sign -i trx-sense-unsigned-index-1.tx -p ${ESCROW_PROG_SND} -o trx-sense-signed-index-1.tx
$sandboxcli copyFrom "trx-sense-signed-index-1.tx"
cat trx-sense-signed-index-0.tx trx-sense-signed-index-1.tx > trx-group-sense-signed.tx
$sandboxcli copyTo "trx-group-sense-signed.tx"
echo "Sending signed transaction group with clerk..."
${goalcli} clerk rawsend -f trx-group-sense-signed.tx
rm -f *.tx
rm -f *.rej
rm -f awk
rm -f head
rm -f *.scratch
rm -f trx-group-sense-signed-dryrun.json
rm -f sed
;;

dryrun)
echo "Creating Dry-run dump from signed transaction group..."
${goalcli} clerk dryrun -t trx-group-sense-signed.tx --dryrun-dump -o trx-group-sense-signed-dryrun.json
$sandboxcli copyFrom "trx-group-sense-signed-dryrun.json"
echo "Dryrun dump JSON file generated successfully!"
;;

drapproval)
echo "Dry-running signed approval program with signed transaction group ..."
${goalcli} clerk dryrun -t trx-group-sense-signed.tx --dryrun-dump -o trx-group-sense-signed-dryrun.json
$sandboxcli copyFrom "trx-group-sense-signed-dryrun.json"
cd "../" && docker exec -it algorand-sandbox-algod  tealdbg debug ${APPROVAL_PROG} -f cdt --listen 0.0.0.0 -d trx-group-sense-signed-dryrun.json --group-index 0
echo "The Dry run JSON file is running to check Approval Smart Contract"
cd desense


;;
drescrow)
echo "Dry-running signed approval program with signed transaction group..."
${goalcli} clerk dryrun -t trx-group-sense-signed.tx --dryrun-dump -o trx-group-sense-signed-dryrun.json
$sandboxcli copyFrom "trx-group-sense-signed-dryrun.json"
cd "../" && docker exec -it  algorand-sandbox-algod tealdbg debug ${ESCROW_PROG_SND} -f cdt --listen 0.0.0.0 -d trx-group-sense-signed-dryrun.json
echo "The Dry run JSON file is running to check Stateful Approval Smart Contract..."
cd desense
;;

axfer)
echo "Receiving Standard Asset..."
MAIN_ACC=$(<desense-main-account.txt)
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
APP_ID=$(cat "desense-id.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
APP_ID_TRIM="${APP_ID//$'\r'/ }"


if [ $2 = "auto" ]; then
    ASSET_ID=$(${goalcli} account info -a ${ESCROW_ACC_TRIM} | grep ID | head -n 1 | awk '{ print $2 }')
    echo "The asset (SENSE) ID selected by auto mode is: ${ASSET_ID%?}"
else
    
    ASSET_ID= $2
    echo "Manual asset (SENSE) ID entering mode selected! Asset (SENSE) ID in request to be transfered (one unit only) ${ASSET_ID%?}"
    echo -ne "${ASSET_ID%?}" > "desense-asset-index.txt" 
fi

echo "Escrow account: $ESCROW_ACC_TRIM"
echo "Application ID:$APP_ID_TRIM"
echo "The asset (SENSE) ID from which 1 (one) unit will be transfered to main account: ${ASSET_ID%?}"

ESCROW_PROG_SND="desense-escrow-stateless-snd.tea"
${goalcli} asset send --assetid ${ASSET_ID%?} -f ${MAIN_ACC} -t ${MAIN_ACC} -a 0
${goalcli} app call --app-id ${APP_ID_TRIM} --app-arg "str:sense-xfer" -f ${MAIN_ACC} -o trx-get-sense-unsigned.tx
$sandboxcli copyFrom "trx-get-sense-unsigned.tx"
${goalcli} asset send --assetid ${ASSET_ID%?} -f ${ESCROW_ACC_TRIM} -t ${MAIN_ACC} -a 1 -o trx-send-sense-unsigned.tx
$sandboxcli copyFrom "trx-send-sense-unsigned.tx"
cat trx-get-sense-unsigned.tx trx-send-sense-unsigned.tx > trx-array-sense-transfer-unsigned.tx
$sandboxcli copyTo "trx-array-sense-transfer-unsigned.tx"
${goalcli} clerk group -i trx-array-sense-transfer-unsigned.tx -o trx-group-sense-transfer-unsigned.tx
$sandboxcli copyFrom "trx-group-sense-transfer-unsigned.tx"
${goalcli} clerk split -i trx-group-sense-transfer-unsigned.tx -o trx-sense-transfer-unsigned-index.tx
${goalcli} clerk sign -i trx-sense-transfer-unsigned-index-0.tx -o trx-sense-transfer-signed-index-0.tx
${goalcli} clerk sign -i trx-sense-transfer-unsigned-index-1.tx -p ${ESCROW_PROG_SND} -o trx-sense-transfer-signed-index-1.tx
$sandboxcli copyFrom "trx-sense-transfer-signed-index-0.tx"
$sandboxcli copyFrom "trx-sense-transfer-signed-index-1.tx"
cat trx-sense-transfer-signed-index-0.tx trx-sense-transfer-signed-index-1.tx > trx-group-sense-transfer-signed.tx
$sandboxcli copyTo "trx-group-sense-transfer-signed.tx"
echo "Transfering one unit of SENSE with clerk"
${goalcli} clerk rawsend -f trx-group-sense-transfer-signed.tx 
rm -f *.tx
rm -f *.rej
rm -f awk
rm -f head
rm -f *.scratch
rm -f sed
;;
trxlist)
echo "listing transactions..."
curl "localhost:8980/v2/transactions?pretty"
;;
axferlist)
echo "listing transactions..."

curl  "localhost:8980/v2/transactions?pretty&tx-type=axfer"   | getJsonVal "['transactions']"
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
echo "4- ./desense.sh sense"
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
echo "Installs the sandbox, EmitterIO and sensor emulator instances" 
echo "                "
echo "./desense.sh reset"
echo "Resets the sandbox instance" 
echo "                "
echo "./desense.sh startsandbox"
echo "Starts the sandbox instance" 
echo "                "
echo "./desense.sh startemitter"
echo "Starts the EmitterIO instance" 
echo "                "
echo "./desense.sh startemulator"
echo "Starts the sensor emulator instance" 
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