#!/bin/bash

echo "Starting replica set initialize"
until mongo --host mongo1 --eval "print(\"waited for connection\")"
do
    sleep 2
done
echo "Connection finished"
echo "Creating replica set"
mongo --host mongo1 <<EOF
rs.initiate(
  {
    _id : 'rs0',
    members: [
      { _id : 0, host : "mongo1:27017", priority:10 },
      { _id : 1, host : "mongo2:27017", priority:5 },
      { _id : 2, host : "mongo3:27017", priority:5 }
    ]
  }
)
EOF


sleep 2

mongo --host mongo1 <<EOF
use admin
db.createUser({user:"admin",pwd:"admin",roles:["clusterAdmin","readWriteAnyDatabase","dbAdminAnyDatabase","userAdminAnyDatabase"]})
EOF

echo "replica set created"
