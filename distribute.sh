#!/usr/bin/env bash

function show_help() {
    echo "Keystore & truststore distributor for Hadoop's HDFS & YARN nodes"
    echo "usage: $0 -n <list_of_nodes> -d <destination_directory> " \
    "-u <superuser_name>"
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

function upload() {
    # check if the directory exists or create one
    #scp changes
    ssh $2@$1 "if [ ! -d '$3' ]; then mkdir $3; fi;"
    ret=$?
    if [ "$ret" -ne "0" ]; then
        echo $ret
        exit
    fi
    scp keys/$1.* keys/truststore $2@$1:$3/
    ret=$?
    echo $ret
}

function register() {
    scp agent.sh $2@$1:.agent
    ssh -t $2@$1 "chmod 700 .agent && ./.agent $1 $2 $3 $4"
    ret=$?
    echo $ret
}

# entry point
while getopts ":n:d:u:" opt; do
    case $opt in
        n )
            nodes=$(get_nodes_list $OPTARG)
            ;;
        d )
            destination=$OPTARG
            ;;
        u )
            user_name=$OPTARG
            ;;
        \? )
            show_help
            exit 1
            ;;
    esac
done

if [ -z $destination ] || [ -z $user_name ]; then
    show_help
    exit 1
fi
if [ -z "$nodes" ]; then
    missing_list_of_nodes
    exit 1
fi
for host in $nodes
do
    ret=$(upload $host $user_name .keys)
    if [ "$(upload $host $user_name .keys)" -ne "0" ] \
            || [ $(register $host $user_name $destination .keys) -ne "0" ]; then
        echo "key distributon unsuccessful"
        exit 1
    fi
done
echo "keys published successfully!"
exit 0
