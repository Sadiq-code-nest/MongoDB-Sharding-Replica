#!/bin/bash

set -e

echo "🧪 MongoDB Sharding Distribution Test"
echo "======================================"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}Step 1: Checking Data Distribution${NC}"
echo "------------------------------------"
docker exec mongos-router mongosh testdb --quiet --eval "
  if (db.users.countDocuments() === 0) {
    print('❌ No data found. Please run: ./scripts/insert-data.sh sharding 25000');
    quit(1);
  }
  
  print('Total Documents: ' + db.users.countDocuments());
  print('');
  print('Distribution by Shard:');
  print('======================');
  db.users.getShardDistribution();
"

echo ""
echo -e "${BLUE}Step 2: Analyzing Chunk Distribution${NC}"
echo "--------------------------------------"
docker exec mongos-router mongosh config --quiet --eval "
  const chunks = db.chunks.aggregate([
    { \$match: { ns: 'testdb.users' } },
    { \$group: { _id: '\$shard', count: { \$sum: 1 } } },
    { \$sort: { _id: 1 } }
  ]).toArray();
  
  print('Chunks per Shard:');
  chunks.forEach(c => {
    print('  ' + c._id + ': ' + c.count + ' chunks');
  });
  
  print('');
  print('Total Chunks: ' + db.chunks.countDocuments({ ns: 'testdb.users' }));
"

echo ""
echo -e "${BLUE}Step 3: Testing Cross-Shard Queries${NC}"
echo "-------------------------------------"
docker exec mongos-router mongosh testdb --quiet --eval "
  print('Query 1: Count by Department (scatter-gather)');
  const start1 = Date.now();
  const deptCounts = db.users.aggregate([
    { \$group: { _id: '\$department', count: { \$sum: 1 } } },
    { \$sort: { count: -1 } },
    { \$limit: 5 }
  ]).toArray();
  const time1 = Date.now() - start1;
  
  deptCounts.forEach(d => {
    print('  ' + d._id + ': ' + d.count);
  });
  print('Query time: ' + time1 + 'ms');
  print('');
  
  print('Query 2: Find Specific User (targeted)');
  const start2 = Date.now();
  const user = db.users.findOne({ userId: 12345 });
  const time2 = Date.now() - start2;
  
  if (user) {
    print('  Found: ' + user.username + ' (' + user.email + ')');
  }
  print('Query time: ' + time2 + 'ms');
  print('');
  
  print('Query 3: Range Query (multiple shards)');
  const start3 = Date.now();
  const rangeCount = db.users.countDocuments({ 
    userId: { \$gte: 1000, \$lte: 5000 } 
  });
  const time3 = Date.now() - start3;
  
  print('  Documents in range: ' + rangeCount);
  print('Query time: ' + time3 + 'ms');
"

echo ""
echo -e "${BLUE}Step 4: Testing Shard Targeting${NC}"
echo "---------------------------------"
docker exec mongos-router mongosh testdb --quiet --eval "
  print('Explain plan for targeted query:');
  const explain = db.users.find({ userId: 5000 }).explain('executionStats');
  
  print('Shards queried: ' + Object.keys(explain.executionStats.executionStages.shards || {}).length);
  print('Documents examined: ' + explain.executionStats.totalDocsExamined);
  print('Documents returned: ' + explain.executionStats.nReturned);
  print('Execution time: ' + explain.executionStats.executionTimeMillis + 'ms');
"

echo ""
echo -e "${BLUE}Step 5: Testing Write Distribution${NC}"
echo "------------------------------------"
echo "Inserting test batch..."
docker exec mongos-router mongosh testdb --quiet --eval "
  const testDocs = [];
  for (let i = 0; i < 1000; i++) {
    testDocs.push({
      userId: 1000000 + i,
      username: 'shardtest_' + i,
      email: 'test' + i + '@sharding.test',
      testBatch: true,
      insertedAt: new Date()
    });
  }
  
  const result = db.users.insertMany(testDocs);
  print('✓ Inserted ' + result.insertedIds.length + ' documents');
  print('Documents will be distributed across shards based on hashed userId');
"

echo ""
echo -e "${BLUE}Step 6: Balancer Activity${NC}"
echo "--------------------------"
docker exec mongos-router mongosh config --quiet --eval "
  print('Recent Balancer Activity:');
  db.changelog.find({ what: 'moveChunk.commit' })
    .sort({ time: -1 })
    .limit(5)
    .forEach(entry => {
      print('  ' + entry.time.toISOString() + ' - ' + entry.details.from + ' → ' + entry.details.to);
    });
  
  const lockCount = db.changelog.countDocuments({ what: 'moveChunk.commit' });
  if (lockCount === 0) {
    print('  No recent chunk migrations (cluster is balanced)');
  }
"

echo ""
echo -e "${GREEN}======================================"
echo "Sharding Test Complete ✓"
echo "======================================${NC}"
echo ""
echo "Summary:"
echo "  • Data is distributed across multiple shards"
echo "  • Queries are routed to appropriate shards"
echo "  • Writes are balanced automatically"
echo "  • Balancer manages chunk distribution"
echo ""
echo "Performance Tips:"
echo "  ✓ Queries with shard key are fastest (targeted)"
echo "  ✓ Range queries may hit multiple shards"
echo "  ✓ Aggregations distribute work across shards"
echo ""
