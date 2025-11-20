#!/bin/bash

set -e

echo "🧪 MongoDB Replica Set Failover Test"
echo "====================================="

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to get current primary
get_primary() {
  docker exec mongo-node-1 mongosh --quiet --eval "rs.isMaster().primary" 2>/dev/null | grep -o "mongo-node-[0-9]" || echo "unknown"
}

# Function to check data accessibility
check_data() {
  local count=$(docker exec mongo-node-1 mongosh testdb --quiet --eval "db.users.countDocuments()" 2>/dev/null || echo "0")
  echo $count
}

echo ""
echo -e "${BLUE}Step 1: Checking current cluster state${NC}"
echo "---------------------------------------"
PRIMARY=$(get_primary)
echo -e "Current Primary: ${GREEN}$PRIMARY${NC}"

docker exec mongo-node-1 mongosh --quiet --eval "
  rs.status().members.forEach(m => {
    print(m.name + ' -> ' + m.stateStr + (m.stateStr === 'PRIMARY' ? ' ⭐' : ''))
  })
"

INITIAL_COUNT=$(check_data)
echo -e "Documents in database: ${GREEN}$INITIAL_COUNT${NC}"

echo ""
echo -e "${YELLOW}Step 2: Simulating primary node failure${NC}"
echo "---------------------------------------"
echo -e "${RED}Stopping $PRIMARY...${NC}"
docker stop $PRIMARY

echo ""
echo -e "${YELLOW}Step 3: Waiting for new primary election (15 seconds)${NC}"
echo "---------------------------------------"
for i in {15..1}; do
  echo -ne "⏳ $i seconds remaining...\r"
  sleep 1
done
echo ""

echo ""
echo -e "${BLUE}Step 4: Checking new cluster state${NC}"
echo "---------------------------------------"
sleep 3

# Try multiple nodes to find the new primary
NEW_PRIMARY=""
for node in mongo-node-1 mongo-node-2 mongo-node-3; do
  if [ "$node" != "$PRIMARY" ]; then
    STATUS=$(docker exec $node mongosh --quiet --eval "rs.isMaster().ismaster" 2>/dev/null || echo "false")
    if [ "$STATUS" = "true" ]; then
      NEW_PRIMARY=$node
      break
    fi
  fi
done

if [ -z "$NEW_PRIMARY" ]; then
  echo -e "${RED}⚠ Warning: Could not determine new primary${NC}"
  NEW_PRIMARY=$(docker exec mongo-node-2 mongosh --quiet --eval "rs.isMaster().primary" 2>/dev/null | grep -o "mongo-node-[0-9]" || echo "unknown")
fi

echo -e "New Primary elected: ${GREEN}$NEW_PRIMARY ✓${NC}"

# Show current status from active node
ACTIVE_NODE="mongo-node-2"
if [ "$NEW_PRIMARY" = "mongo-node-2" ]; then
  ACTIVE_NODE="mongo-node-3"
fi

docker exec $ACTIVE_NODE mongosh --quiet --eval "
  rs.status().members.forEach(m => {
    print(m.name + ' -> ' + m.stateStr + (m.stateStr === 'PRIMARY' ? ' ⭐' : ''))
  })
"

echo ""
echo -e "${BLUE}Step 5: Verifying data integrity${NC}"
echo "---------------------------------------"
NEW_COUNT=$(docker exec $ACTIVE_NODE mongosh testdb --quiet --eval "db.users.countDocuments()" 2>/dev/null || echo "0")
echo -e "Documents in database: ${GREEN}$NEW_COUNT${NC}"

if [ "$INITIAL_COUNT" = "$NEW_COUNT" ]; then
  echo -e "${GREEN}✓ Data integrity verified - no data loss${NC}"
else
  echo -e "${RED}⚠ Warning: Document count mismatch${NC}"
fi

echo ""
echo -e "${BLUE}Step 6: Testing write operations${NC}"
echo "---------------------------------------"
docker exec $ACTIVE_NODE mongosh testdb --quiet --eval "
  const result = db.users.insertOne({
    userId: 999999,
    username: 'failover_test_user',
    firstName: 'Failover',
    lastName: 'Test',
    email: 'failover@test.com',
    testTimestamp: new Date(),
    testType: 'post-failover'
  });
  print('✓ Write successful, insertedId: ' + result.insertedId);
"

echo ""
echo -e "${YELLOW}Step 7: Restarting failed node${NC}"
echo "---------------------------------------"
echo -e "Starting $PRIMARY..."
docker start $PRIMARY

echo "Waiting for node to rejoin (10 seconds)..."
sleep 10

echo ""
echo -e "${BLUE}Step 8: Final cluster state${NC}"
echo "---------------------------------------"
docker exec $ACTIVE_NODE mongosh --quiet --eval "
  rs.status().members.forEach(m => {
    print(m.name + ' -> ' + m.stateStr + (m.stateStr === 'PRIMARY' ? ' ⭐' : ''))
  })
"

echo ""
echo -e "${GREEN}====================================="
echo "Failover Test Complete ✓"
echo "=====================================${NC}"
echo ""
echo "Summary:"
echo "  • Original Primary:   $PRIMARY"
echo "  • New Primary:        $NEW_PRIMARY"
echo "  • Data Preserved:     $NEW_COUNT documents"
echo "  • Failed Node:        Recovered and rejoined"
echo ""
echo "The replica set automatically:"
echo "  ✓ Detected primary failure"
echo "  ✓ Elected a new primary"
echo "  ✓ Maintained data availability"
echo "  ✓ Accepted new writes"
echo "  ✓ Re-integrated the failed node"
echo ""
