#!/bin/bash

rs1=`getent hosts ${MONGORS1} | awk '{ print $1 }'`
rs2=`getent hosts ${MONGORS2} | awk '{ print $1 }'`
rs3=`getent hosts ${MONGORSCNF} | awk '{ print $1 }'`

port=${PORT:-27017}

# 函数来检查副本集状态是否为OK
check_replica_set() {
    local host=$1
    local port=$2
    local status=$(mongo --host ${host}:${port} --eval "rs.status().ok" --quiet)
    if [ "$status" == "1" ]; then
        return 0
    else
        return 1
    fi
}

# 等待副本集初始化完成
echo "Waiting for replica set to be ready..."
for node in ${rs1} ${rs2} ${rs3}; do
    until check_replica_set ${node} ${port}; do
        echo "Replica set not ready yet..."
        sleep 2
    done
done

# 副本集已经初始化完成，可以启动mongos路由器
echo "Replica set is ready, starting mongos router..."
exec mongos --configdb cnf-serv/mongo-cnf-1:27017,mongo-cnf-2:27017,mongo-cnf-3:27017 --port 27017 --bind_ip 0.0.0.0