#!/bin/bash

set -e

echo "Initializing replica set configuration..."

docker exec mongo-node-1 mongosh --quiet --eval "
rs.initiate({
  _id: 'rs0',
  members: [
    { _id: 0, host: 'mongo-node-1:27017', priority: 2 },
    { _id: 1, host: 'mongo-node-2:27018', priority: 1 },
    { _id: 2, host: 'mongo-node-3:27019', priority: 1 }
  ]
})
" 2>/dev/null || echo "Replica set already initialized or initialization in progress"

echo "Waiting for replica set to stabilize..."
sleep 5

# Wait for primary to be elected
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  PRIMARY=$(docker exec mongo-node-1 mongosh --quiet --eval "rs.isMaster().primary" 2>/dev/null || echo "")
  
  if [ ! -z "$PRIMARY" ] && [ "$PRIMARY" != "null" ]; then
    echo "✓ Primary elected: $PRIMARY"
    break
  fi
  
  ATTEMPT=$((ATTEMPT + 1))
  echo "Waiting for primary election... ($ATTEMPT/$MAX_ATTEMPTS)"
  sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
  echo "⚠ Warning: Primary election took longer than expected"
  exit 1
fi

echo "✓ Replica set initialized successfully"
