#!/bin/bash

echo "Starting replica set initialize"
until mongo --host mongo1 --eval "print(\"waited for connection\")"; do
  sleep 5
done

echo "Connection finished"
echo "Creating replica set"

#Need overwrite userName and Password in CI/CD

mongo --host mongo1 --authenticationDatabase "admin" -u "admin" -p "pass" <<EOF
rs.initiate(
  {
    _id : 'rs0',
    members: [
      { _id : 0, host : "mongo1:27017", priority:1 },
      { _id : 1, host : "mongo2:27017", priority:0 },
      { _id : 2, host : "mongo3:27017", priority:0 }
    ]
  }
)

EOF

sleep 15

echo "set User"

#Need overwrite userName and Password in CI/CD
mongo --host mongo1 --authenticationDatabase "admin" -u "admin" -p "pass" <<EOF
use admin
db.createUser({user:"clusterAdmin",pwd:"pass",roles:["clusterAdmin","readWriteAnyDatabase","dbAdminAnyDatabase","userAdminAnyDatabase"]})
EOF

echo "replica set created"
