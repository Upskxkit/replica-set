<div>
    <h1>mongoDB replica-set</h1>
    <a href="https://docs.mongodb.com/manual/replication/">Replication docs</a>
</div>

<div>
    <p>This repository about how to create mongo replica-set from 3 mongodb (mongo1, mongo2, mongo3 on <a href="https://docs.mongodb.com/manual/core/replica-set-architecture-three-members/">PSS schema<a/>) into claster with Auth and craete super user or your own user.</p>
    <p>Basic you can create 2 schemas P-S-S or PSA</p>
</div>
<hr>
<div>
<h3>Deploy Replica Set With file.key Authentication</h3>
<a href="https://docs.mongodb.com/manual/tutorial/deploy-replica-set-with-keyfile-access-control/">replica authentication docs link</a>
<h5>Steps</h5>
<ul>
    <li>create file.key - for development/staging env</li>
    <li>allocate file to all members</li>
    <li>allocate admin user</li>
    <li>initialize replica-set</li>
    <li>create User for over DB</li>
    <li>Use DB</li>
</ul>
</div>
<hr>

###Create file.key
```
$openssl rand -base64 756 > <path-to-keyfile> 
$chmod 400 <path-to-keyfile>
$chown 999 <path-to-keyfile> - The file owner was changed to a user id of “999" because the user in the MongoDB Docker container is the one that needs to access this key file.
```

###Allocate file to all members

```$xslt
mongo2:
    hostname: mongo2
    container_name: mongo2
    image: mongo:4.0.4
    networks:
      - mongo-cluster
    ports:
      - 27018:27017
    restart: always
    command: "--keyFile /data/file.key --replSet rs0 --dbpath /data/db --journal --bind_ip_all"
    volumes:
      - "./scripts/file.key:/data/file.key"
      - "./data/mongo2:/data/db"
```

if you look at command you will see "--keyFile /data/file.key" by this command we start mongo with file.key security. Also don't forget to add file.key to image.

###Allocate admin user
To allocate admin user we will use default entrypoit of mongodb images
    https://hub.docker.com/_/mongo/

```
mongo1:
    hostname: mongo1
    ...
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_INITDB_ROOT_USERNAME}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_INITDB_ROOT_PASSWORD}
```
we pass default env to the image.

###Initialize replica-set
According to step before we create admin user and now we have right to auth.
For this we need define shall script and dockerify it. You will see template in mongo-replicator folder

on this step we wait until we connect to mongo1.
```bash
echo "Starting replica set initialize"
until mongo --host mongo1 --eval "print(\"waited for connection\")"; do
  sleep 5
done

echo "Connection finished"
echo "Creating replica set"
```
on this step we auth to the mongo1 and init replica-set
```bash
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
```
 
after we need to wait for elaborate PRIMARY database, it took by default 10 second and setup owr clusterAdmin that have all right.

```bash
sleep 15

echo "set User"

#Need overwrite userName and Password in CI/CD
mongo --host mongo1 --authenticationDatabase "admin" -u "admin" -p "pass" <<EOF
use admin
db.createUser({user:"clusterAdmin",pwd:"pass",roles:["clusterAdmin","readWriteAnyDatabase","dbAdminAnyDatabase","userAdminAnyDatabase"]})
EOF

echo "replica set created"
```
 
####Use DB
After such manipulation we able to use owr cluster.

mongo -u clusterAdmin -p pass 

or connect via mongoose(ODM).
