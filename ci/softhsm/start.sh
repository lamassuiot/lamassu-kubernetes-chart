#!/bin/bash

function chck_empty(){
    if [[ "$2" == "" ]]; then
        echo "INVALID option $1: '$2' !!PANIC!!"
        exit 1
    fi
    echo "$1: $2"
}

echo "creating hsm config file..."
echo "=========================="
echo "directories.tokendir = /softhsm/tokens" > /etc/softhsm2.conf
echo "objectstore.backend = db" >> /etc/softhsm2.conf
echo "log.level = INFO" >> /etc/softhsm2.conf
echo "slots.removable = false" >> /etc/softhsm2.conf 

echo "config file content:"
cat  /etc/softhsm2.conf 

echo "=========================="
chck_empty "Slot" $SLOT
chck_empty "Label" $LABEL
chck_empty "PIN" $PIN
chck_empty "SO PIN" $SO_PIN
chck_empty "Connection Protocol" $CONNECTION_PROTOCOL
echo "PSK: $PSK"
echo "=========================="

echo "initing HSM:"
softhsm2-util --init-token --slot $SLOT --label $LABEL --pin $PIN --so-pin $SO_PIN
echo "init process completed."

echo "=========================="

if [[ "$CONNECTION_PROTOCOL" == "tcp" ]]; then
    echo "HSM Connection Protocol (tcp/tls): tcp"
    export PKCS11_DAEMON_SOCKET="tcp://0.0.0.0:5657"
elif [[ "$CONNECTION_PROTOCOL" == "tls" ]]; then
    echo "HSM Connection Protocol (tcp/tls): tls"
    export PKCS11_DAEMON_SOCKET="tls://0.0.0.0:5657"
    echo "$PSK" > /sym.psk 
    export PKCS11_PROXY_TLS_PSK_FILE=/sym.psk
else
    echo "INVALID CONNECTION_PROTOCOL '$CONNECTION_PROTOCOL' !!PANIC!!"
    exit 1
fi

echo "
 ___  ___  ________  _____ ______           ________  _______   ________  ________      ___    ___ 
|\  \|\  \|\   ____\|\   _ \  _   \        |\   __  \|\  ___ \ |\   __  \|\   ___ \    |\  \  /  /|
\ \  \\\  \ \  \___|\ \  \\\__\ \  \       \ \  \|\  \ \   __/|\ \  \|\  \ \  \_|\ \   \ \  \/  / /
 \ \   __  \ \_____  \ \  \\|__| \  \       \ \   _  _\ \  \_|/_\ \   __  \ \  \ \\ \   \ \    / / 
  \ \  \ \  \|____|\  \ \  \    \ \  \       \ \  \\  \\ \  \_|\ \ \  \ \  \ \  \_\\ \   \/  /  /  
   \ \__\ \__\____\_\  \ \__\    \ \__\       \ \__\\ _\\ \_______\ \__\ \__\ \_______\__/  / /    
    \|__|\|__|\_________\|__|     \|__|        \|__|\|__|\|_______|\|__|\|__|\|_______|\___/ /     

"

/usr/local/bin/pkcs11-daemon /usr/local/lib/softhsm/libsofthsm2.so
