#!/usr/bin/env bash

if [ $(getent passwd | grep -c '^yarn:') -eq 0 ] \
        || [ $(getent passwd | grep -c '^hbase:') -eq 0 ] \
        || [ $(getent passwd | grep -c '^cloudera-scm:') -eq 0 ] \
        || [ $(grep -c '^hadoop' /etc/group) -eq 0 ];
    then rm $0 && exit 1;
fi
# Execute the plan and remove this agent in the last step
if [ -d "$4" ]; then
    sudo mv $4/$1.keystore $3/keystore \
    && sudo mv $4/truststore $3/truststore \
    && sudo chown yarn:hadoop $3/keystore $3/truststore \
    && sudo chmod 444 $3/truststore \
    && sudo chmod 440 $3/keystore && rm -f $0 \
    && sudo setfacl -m u:hbase:r,u:cloudera-scm:r $3/keystore $3/truststore \
    && rm -f $0 && exit 0
fi
exit 1
