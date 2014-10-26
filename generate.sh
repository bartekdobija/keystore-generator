#!/usr/bin/env bash

function show_help() {
    echo "Keystore & truststore generator for Hadoop's HDFS & YARN"
    echo "usage: $0 -n <list_of_nodes> -p <6plus_long_keystore_password> " \
    "-e <key_expiration>"
}

function missing_list_of_nodes() {
    echo "The \"nodes\" file is not accessible."
}

function get_nodes_list() {
    if [ ! -f $1 ]; then
        echo ''
    else
        echo $(cat $1 | tr -d ' ')
    fi
}

function generate_keystore() {
    if [[ $3 =~ [0-9]+$ ]]; then
        validity=$3
    else
        validity=3650
    fi
    keytool -genkey -alias $1 -keyalg RSA -keysize 1024 \
    -dname "CN=$1,OU=IT,O=Ryanair Ltd.,L=Dublin,ST=Co. Dublin,C=IE" \
    -keypass $2 -storepass $2 -keystore keys/$1.keystore -validity $validity -v
}

function generate_certificate() {
    keytool -exportcert -keystore keys/$1.keystore -file keys/$1.cert \
     -alias $1 -storepass $2 -keypass $2 -v
}

function add_cert_to_main_truststore() {

    if [ $(keytool -list -keystore keys/truststore -storepass $2 | \
            grep $1 | wc -l | tr -d ' ') -eq "1" ]; then
        keytool -delete -keystore keys/truststore -storepass $2 -alias $1
    fi

    keytool -import -v -noprompt -trustcacerts -alias $1 -file keys/$1.cert \
     -keystore keys/truststore -storepass $2 -keypass $2 -v
}

# entry point
while getopts ":n:p:e:" opt;
do
    case $opt in
    n )
        nodes=$(get_nodes_list $OPTARG)
        ;;
    p )
        password=$OPTARG
        ;;
    e )
        expiration=$OPTARG
        ;;
    \? )
        show_help
        exit 1
        ;;
    esac
done

if [ ${#password} -lt 6 ] || [ -z "$expiration" ]; then
    show_help
    exit 1
fi

if [ -z "$nodes" ]; then
    missing_list_of_nodes
    exit 1;
fi

if [ -d "keys" ]; then
    rm keys/*.keystore keys/*.cert
else
    mkdir keys
fi

for host in $nodes
do
    generate_keystore $host $password $expiration
    generate_certificate $host $password
    add_cert_to_main_truststore $host $password
done
exit 0
