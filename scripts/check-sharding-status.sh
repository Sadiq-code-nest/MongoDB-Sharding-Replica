#!/bin/bash

echo "📊 MongoDB Replica Set Status"
echo "=============================="

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if containers are running
echo ""
echo -e "${BLUE}Container Status:${NC}"
echo "-------------------"
docker ps --filter "name=mongo-node" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -4

echo ""
echo -e "${BLUE}Replica Set Configuration:${NC}"
echo "----------------------------"
docker exec mongo-node-1 mongosh --quiet --eval "
  const status = rs.status();
  const config = rs.conf();
  
  print('Replica Set Name: ' + status.set);
  print('Members: ' + status.members.length);
  print('');
  
  status.members.forEach(member => {
    const state = member.stateStr;
    const health = member.health === 1 ? '✓' : '✗';
    const icon = state === 'PRIMARY' ? '⭐' : (state === 'SECONDARY' ? '📋' : '❓');
    print(icon + ' ' + member.name + ' -> ' + state + ' [' + health + ']');
    if (member.optimeDate) {
      print('   Last Optime: ' + member.optimeDate.toISOString());
    }
  });
"

echo ""
echo -e "${BLUE}Replication Lag:${NC}"
echo "------------------"
docker exec mongo-node-1 mongosh --quiet --eval "rs.printSlaveReplicationInfo()"

echo ""
echo -e "${BLUE}Connection String:${NC}"
echo "-------------------"
echo "mongodb://localhost:27017,localhost:27018,localhost:27019/?replicaSet=rs0"

echo ""
echo -e "${BLUE}Database Statistics:${NC}"
echo "---------------------"
docker exec mongo-node-1 mongosh testdb --quiet --eval "
  if (db.users.countDocuments() > 0) {
    print('Total Users: ' + db.users.countDocuments());
    print('Active Users: ' + db.users.countDocuments({ active: true }));
    print('Database Size: ' + (db.stats().dataSize / 1024 / 1024).toFixed(2) + ' MB');
  } else {
    print('No data inserted yet. Run: ./scripts/insert-data.sh replica 15000');
  }
"

echo ""
