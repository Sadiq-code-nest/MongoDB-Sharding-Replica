#!/bin/bash

set -e

echo "Step 1: Initializing Config Server Replica Set..."

docker exec config-server-1 mongosh --port 40001 --quiet --eval "
rs.initiate({
  _id: 'cfgrs',
  configsvr: true,
  members: [
    { _id: 0, host: 'config-server-1:40001' },
    { _id: 1, host: 'config-server-2:40002' },
    { _id: 2, host: 'config-server-3:40003' }
  ]
})
" 2>/dev/null || echo "Config server RS already initialized"

sleep 8

echo "Step 2: Initializing Shard 1 Replica Set..."

docker exec shard1-node-1 mongosh --port 50001 --quiet --eval "
rs.initiate({
  _id: 'shard1rs',
  members: [
    { _id: 0, host: 'shard1-node-1:50001' },
    { _id: 1, host: 'shard1-node-2:50011' }
  ]
})
" 2>/dev/null || echo "Shard 1 RS already initialized"

sleep 6

echo "Step 3: Initializing Shard 2 Replica Set..."

docker exec shard2-node-1 mongosh --port 50002 --quiet --eval "
rs.initiate({
  _id: 'shard2rs',
  members: [
    { _id: 0, host: 'shard2-node-1:50002' },
    { _id: 1, host: 'shard2-node-2:50012' }
  ]
})
" 2>/dev/null || echo "Shard 2 RS already initialized"

sleep 8

echo "Step 4: Adding Shards to Cluster..."

docker exec mongos-router mongosh --quiet --eval "
sh.addShard('shard1rs/shard1-node-1:50001,shard1-node-2:50011')
" 2>/dev/null || echo "Shard 1 already added"

docker exec mongos-router mongosh --quiet --eval "
sh.addShard('shard2rs/shard2-node-1:50002,shard2-node-2:50012')
" 2>/dev/null || echo "Shard 2 already added"

sleep 3

echo "Step 5: Enabling Sharding on Database..."

docker exec mongos-router mongosh --quiet --eval "
sh.enableSharding('testdb')
" 2>/dev/null || echo "Database sharding already enabled"

docker exec mongos-router mongosh --quiet --eval "
sh.shardCollection('testdb.users', { userId: 'hashed' })
" 2>/dev/null || echo "Collection already sharded"

docker exec mongos-router mongosh --quiet --eval "
sh.shardCollection('testdb.transactions', { transactionId: 1 })
" 2>/dev/null || echo "Transactions collection already sharded"

echo "✓ Sharded cluster configured successfully"
