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
function getDecoded () { 
    python -c "import sys,base64,json; x=sys.stdin.read().decode('base64').decode('base64'); sys.stdout.write(x)" 
}
function getDecodedVar () { 
     echo -n "$1" | python -c "import base64,sys; x= sys.stdin.read().decode('base64').decode('base64'); print(x)"
}
case $1 in
install)
sudo apt update
sudo apt install jq
echo "jq utilities installed! OK!"
echo "        "
if [[ ! -d "../sandbox" ]]
then
    echo "Installing Algorand SandBox environment"
    echo "        "
    git clone https://github.com/algorand/sandbox.git ../sandbox
    echo "Algorand SandBox installed successfully in parent folder (Beside current folder)"
    echo "        "
else
  echo "Algorand SandBox is installed OK!"
  echo "        "
fi
if [[ ! -f "/usr/local/bin/sampler" ]]
then
    echo "Installing Sampler Dashboard environment"
    echo "        "
    sudo wget https://github.com/sqshq/sampler/releases/download/v1.1.0/sampler-1.1.0-linux-amd64 -O /usr/local/bin/sampler
    sudo chmod +x /usr/local/bin/sampler
    echo "Sampler Dashboard successfully in /usr/local/bin as a program"
    echo "        "
else
  echo "Sampler Dashboard is installed OK!"
  echo "        "
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
    echo "        "
else
  echo "Sensor Emulator is installed OK!"
  echo "        "
fi
if [[ ! -d "../emitter" ]]
then
    echo "Installing EmitterIO"
    echo "        "
    git clone https://github.com/emitter-io/emitter ../emitter
 
    cd ../emitter
    go build
    cd ../desense
    ../emitter/emitter
    echo "EmitterIO installed successfully in parent folder (Beside current folder)"
    echo "        "
else
  echo "EmitterIO is installed OK!"
  echo "        "
fi

;;
reset)
echo "Reseting sandbox environment"
echo "        "
rm -f desense-id.txt
rm -f desense-escrow-stateless.txt
rm -f desense-escrow-account.txt
rm -f desense-escrow-prog-snd.teal
rm -f desense-main-account.txt
rm -f *.tx
rm -f *.rej
rm -f awk
rm -f head
rm -f *.scratch
rm -f trx-group-sense-signed-dryrun.json
rm -f sed
rm -f python
$sandboxcli reset
;;
stop)
echo "Stopping sandbox environment"
echo "        "
$sandboxcli down
;;
startsandbox)
echo "Starting sandbox environment"
echo "        "
$sandboxcli up
;;
startemitter)
echo "Starting EmitterIO environment"
echo "        "
../emitter/emitter
;;
startemulator)
echo "Starting Sensor Emulator environment"
echo "        "
echo "If this is the first run, the generated license and secret key are shown, please take note of them both and open your browser and go to http://127.0.0.1:8080/keygen and generate channels and channel keys using the secret key you just noted. Do not forget to set EMITTER_LICENSE env variable before start after this run which gave you the keys to make the generated license work!"
echo "        "
cp sensor-template-config.json ../sensor-emulator
cd ../sensor-emulator && ./emulator.sh --DS --run  --config-file=sensor-template-config.json
;;
startsampler)
echo "Starting Sensor Sampler environment"
echo "        "
sampler -c ./desense-dashboard.yml
;;
desense)
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
echo "        "
cat $ESCROW_PROG | awk -v awk_var=${APP} '{ gsub("appIdParam", awk_var); print}' | awk -v awk_var=${ACC} '{ gsub("SENSEAddr", awk_var); print}' > "desense-escrow-stateless-snd.teal"
ESCROW_PROG_SND="desense-escrow-stateless-snd.teal"
$sandboxcli copyTo "$ESCROW_PROG_SND"
ESCROW_ACCOUNT=$(
  ${goalcli} clerk compile -a ${ACC} -n ${ESCROW_PROG_SND} | awk '{ print $2 }' | head -n 1
)
echo -ne "${ACC}" > "desense-main-account.txt"
echo "        "
echo -ne "${ESCROW_ACCOUNT}" > "desense-escrow-account.txt"
echo "        "
echo "Stateful Application ID $APP"
echo "        "
echo "Stateless Escrow Account = ${ESCROW_ACCOUNT}"
echo "        "
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
echo "        "
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
echo "Escrfow account:$ESCROW_ACC_TRIM" 
echo "        "
${goalcli} account balance -a $ESCROW_ACC_TRIM
;;
mainbal)
echo "Getting the main account balance..."
echo "        "
MAIN_ACC=$(<desense-main-account.txt)
echo "Main account:$MAIN_ACC" 
echo "        "
${goalcli} account balance -a $MAIN_ACC
;;
sensors)
echo "Getting the escrow account info..."
echo "        "
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
echo "Escrow account:$ESCROW_ACC_TRIM"
echo "        " 
${goalcli} account info -a $ESCROW_ACC_TRIM
;;
main)
echo "Getting the main account info..."
echo "        "
MAIN_ACC=$(<desense-main-account.txt)
echo "Main account:$MAIN_ACC" 
echo "        "
${goalcli} account info -a $MAIN_ACC
;;
link)
echo "Linking stateless escrow account to stateful smart contract"
echo "        "
MAIN_ACC=$(<desense-main-account.txt)
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
ESCROW_ACC_TRIMM="${ESCROW_ACC//$'\n'/ }"
APP_ID=$(cat "desense-id.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
APP_ID_TRIM="${APP_ID//$'\r'/ }"
echo "Escrow account: $ESCROW_ACC_TRIMM"
echo "        "
echo "Main account:$MAIN_ACC"
echo "        "
echo "Application ID:$APP_ID_TRIM"
echo "        "
${goalcli} app call --app-id ${APP_ID_TRIM} --app-arg "str:escrow_set" --app-arg "addr:${ESCROW_ACC_TRIMM}" -f ${MAIN_ACC}
${goalcli} app read --app-id ${APP_ID_TRIM} --guess-format --global --from ${MAIN_ACC}
;;
sense)
echo "Generating SENSE Standard Asset..."
echo "        "
MAIN_ACC=$(<desense-main-account.txt)
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
APP_ID=$(cat "desense-id.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
APP_ID_TRIM="${APP_ID//$'\r'/ }"
ESCROW_PROG_SND="desense-escrow-stateless-snd.teal"
NOTEGEN=$(echo -n "{'SENSE': 'generate'}" | base64)
$sandboxcli copyTo "$ESCROW_PROG_SND"
echo "Escrow account: $ESCROW_ACC_TRIM"
echo "        "
echo "Main account: $MAIN_ACC"
echo "        "
echo "Application ID:$APP_ID_TRIM"
echo "        "
echo "The asset name: SENSE"
echo "        "
${goalcli} app call --app-id ${APP_ID_TRIM} --app-arg "str:sense_cfg" -f ${MAIN_ACC} -o trx-call-app-unsigned.tx
$sandboxcli copyFrom "trx-call-app-unsigned.tx"
${goalcli} asset create --creator ${ESCROW_ACC_TRIM} --name "SENSE" --total 999999999999999 --asseturl "https://github.com/emg110/desense" --unitname "SNS"  --decimals 6 -o trx-create-sense-unsigned.tx --note "{$NOTEGEN}"
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
echo "        "
${goalcli} clerk rawsend -f trx-group-sense-signed.tx
rm -f *.tx
rm -f *.rej
rm -f awk
rm -f head
rm -f *.scratch
rm -f trx-group-sense-signed-dryrun.json
rm -f sed
rm -f python
;;

dryrun)
echo "Creating Dry-run dump from signed transaction group..."
echo "        "
${goalcli} clerk dryrun -t trx-group-sense-signed.tx --dryrun-dump -o trx-group-sense-signed-dryrun.json
$sandboxcli copyFrom "trx-group-sense-signed-dryrun.json"
echo "Dryrun dump JSON file generated successfully!"
echo "        "
;;

drapproval)
echo "Dry-running signed approval program with signed transaction group ..."
echo "        "
${goalcli} clerk dryrun -t trx-group-sense-signed.tx --dryrun-dump -o trx-group-sense-signed-dryrun.json
$sandboxcli copyFrom "trx-group-sense-signed-dryrun.json"
cd "../" && docker exec -it algorand-sandbox-algod  tealdbg debug ${APPROVAL_PROG} -f cdt --listen 0.0.0.0 -d trx-group-sense-signed-dryrun.json --group-index 0
echo "The Dry run JSON file is running to check Approval Smart Contract"
echo "        "
cd desense


;;
drescrow)
echo "Dry-running signed approval program with signed transaction group..."
echo "        "
${goalcli} clerk dryrun -t trx-group-sense-signed.tx --dryrun-dump -o trx-group-sense-signed-dryrun.json
$sandboxcli copyFrom "trx-group-sense-signed-dryrun.json"
cd "../" && docker exec -it  algorand-sandbox-algod tealdbg debug ${ESCROW_PROG_SND} -f cdt --listen 0.0.0.0 -d trx-group-sense-signed-dryrun.json
echo "The Dry run JSON file is running to check Stateful Approval Smart Contract..."
echo "        "
cd desense
;;

tsstart)
echo "Starting Telesense (Opt-in to Sensor Asset)..."
echo "        "
MAIN_ACC=$(<desense-main-account.txt)
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
APP_ID=$(cat "desense-id.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
APP_ID_TRIM="${APP_ID//$'\r'/ }"


if [ $2 = "auto" ]; then
    ASSET_ID=$(${goalcli} account info -a ${ESCROW_ACC_TRIM} | grep ID | head -n 1 | awk '{ print $2 }')
    ASSET_ID_FINAL=${ASSET_ID%?}
    echo "The asset (SENSE) ID selected by auto mode is: ${ASSET_ID_FINAL}"
    echo "        "
else
    
    ASSET_ID_FINAL=$2
    echo "Manual asset (SENSE) ID entering mode selected! Asset (SENSE) ID in request to be transfered (one unit only) ${ASSET_ID%?}"
    echo "        "
    echo -ne "${ASSET_ID}" > "desense-asset-index.txt" 
    echo "        "
fi

echo "Escrow account: $ESCROW_ACC_TRIM"
echo "        "
echo "Application ID:$APP_ID_TRIM"
echo "        "
echo "The asset (SENSE) ID to opt-into: ${ASSET_ID_FINAL}"
echo "        "

NOTEOPT=$(printf '{"sense": "optin", "temprature": "0", "voltage": "0", "current": "0"}' | base64)
${goalcli} asset send --assetid ${ASSET_ID_FINAL} -f ${MAIN_ACC} -t ${MAIN_ACC} -a 0 --note "${NOTEOPT}"

rm -f *.tx
rm -f *.rej
rm -f awk
rm -f head
rm -f *.scratch
rm -f sed
rm -f python
;;
telesense)
echo "Telesensing Sensor Asset..."
echo "        "
MAIN_ACC=$(<desense-main-account.txt)
ESCROW_ACC=$(cat "desense-escrow-account.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
ESCROW_ACC_TRIM="${ESCROW_ACC//$'\r'/ }"
APP_ID=$(cat "desense-id.txt" | head -n 1 | awk -v awk_var='' '{ gsub(" ", awk_var); print}')
APP_ID_TRIM="${APP_ID//$'\r'/ }"


if [ $2 = "auto" ]; then
    ASSET_ID=$(${goalcli} account info -a ${ESCROW_ACC_TRIM} | grep ID | head -n 1 | awk '{ print $2 }')
    ASSET_ID_FINAL=${ASSET_ID%?}
    echo "The asset (SENSE) ID selected by auto mode is: ${ASSET_ID_FINAL}"
    echo "        "
else
    
    ASSET_ID_FINAL=$2
    echo "Manual asset (SENSE) ID entering mode selected! Asset (SENSE) ID in request to be transfered (one unit only) ${ASSET_ID%?}"
    echo "        "
    echo -ne "${ASSET_ID}" > "desense-asset-index.txt" 
    echo "        "
fi

echo "Escrow account: $ESCROW_ACC_TRIM"
echo "        "
echo "Application ID:$APP_ID_TRIM"
echo "        "
echo "The asset (SENSE) ID from which 1 (one) unit will be transfered to main account: ${ASSET_ID_FINAL}"
echo "        "
NOTEOPT=$(printf '{"sense": "optin", "temprature": "0", "voltage": "0", "current": "0"}' | base64)
NOTEACT=$(printf '{"sense": "activate", "temprature": "24", "voltage": "220", "current": "1100"}' | base64)
echo "        "
ESCROW_PROG_SND="desense-escrow-stateless-snd.teal"
${goalcli} app call --app-id ${APP_ID_TRIM} --app-arg "str:sense-xfer" -f ${MAIN_ACC} -o trx-get-sense-unsigned.tx
$sandboxcli copyFrom "trx-get-sense-unsigned.tx"
${goalcli} asset send --assetid ${ASSET_ID_FINAL} -f ${ESCROW_ACC_TRIM} -t ${MAIN_ACC} -a 1000 -o trx-send-sense-unsigned.tx --note "${NOTEACT}"
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
echo "        "
${goalcli} clerk rawsend -f trx-group-sense-transfer-signed.tx 
rm -f *.tx
rm -f *.rej
rm -f awk
rm -f head
rm -f *.scratch
rm -f sed
rm -f python
;;
tstrxlist)
echo "listing telesense transactions..."
echo "        "
curl  -s "localhost:8980/v2/transactions?pretty&tx-type=axfer"
;;
tslast)
echo "listing telesensed sensor observations from blockchain..."
echo "        "


echo -n $(curl  -s "localhost:8980/v2/transactions?pretty&tx-type=axfer")  | jq '[.transactions[].note] | last' | getDecoded 
echo "        "
echo "        "
;;
tslist)
echo "listing telesensed sensor observations from blockchain..."
echo "        "
for i in $(echo -n $(curl  -s "localhost:8980/v2/transactions?pretty&tx-type=axfer")  | jq '[.transactions[].note] ')
do
 getDecodedVar "$i"

done


echo "        "
echo "        "
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
echo "1- ./desense.sh desense" 
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
echo "5- ./desense.sh sensors"
echo "To check the escrow sensor assets" 
echo "                "
echo "                "
echo "6- ./desense.sh tsstart 'ID' or 'auto'"
echo "To opt-in to last sensor asset (auto) or the one specified with sensor asset ID (you can get it by sensor command)" 
echo "                "
echo "6- ./desense.sh telesense 'ID' or 'auto'"
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
echo "./desense.sh sensors"
echo "Show generated sensors escrow account's info" 
echo "                "
echo "./desense.sh mainbal"
echo "Show main account's balance" 
echo "                "
echo "./desense.sh escrowbal"
echo "Show generated sensors escrow account's balance" 
echo "                "

;;
*)
echo "Welcome deSense, a partiucipation to Monash University-Algorand Blockchain Hackathon 2021 "
echo "This repository contains educational (DO NOT USE IN PRODUCTION!) code and content in response to Monash University-Algorand Blockchain Hackathon 2021"
;;
esac