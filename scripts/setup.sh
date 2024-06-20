#!/bin/bash 

mongodb1=`getent hosts ${MONGO1} | awk '{ print $1 }'`
mongodb2=`getent hosts ${MONGO2} | awk '{ print $1 }'`
mongodb3=`getent hosts ${MONGO3} | awk '{ print $1 }'`

port=${PORT:-27017}

echo "Waiting for startup.."
for node in ${MONGO1} ${MONGO2} ${MONGO3}; do
    until mongo --host ${node}:${port} --eval 'quit(db.runCommand({ ping: 1 }).ok ? 0 : 2)' &>/dev/null; do
        echo "mongodb not ready yet..."
        sleep 1
    done
done

echo "Started.."

echo setup.sh time now: `date +"%T" `
mongo --host ${MONGO1}:${port} <<EOF
   var cfg = {
        "_id": "${RS}",
        "protocolVersion": 1,
        "members": [
            {
                "_id": 0,
                "host": "${MONGO1}:${port}"
            },
            {
                "_id": 1,
                "host": "${MONGO2}:${port}"
            },
            {
                "_id": 2,
                "host": "${MONGO3}:${port}"
            }
        ]
    };
    rs.initiate(cfg, { force: true });
EOF