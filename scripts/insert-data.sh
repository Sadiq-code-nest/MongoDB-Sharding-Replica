#!/bin/bash

set -e

MODE=${1:-replica}
COUNT=${2:-15000}

echo "🔄 Inserting $COUNT documents into MongoDB ($MODE mode)..."

if [ "$MODE" = "replica" ]; then
  CONTAINER="mongo-node-1"
  PORT="27017"
elif [ "$MODE" = "sharding" ]; then
  CONTAINER="mongos-router"
  PORT="27017"
else
  echo "❌ Invalid mode. Use: replica or sharding"
  exit 1
fi

# Generate data by multiplying base dataset
docker exec $CONTAINER mongosh testdb --port $PORT --quiet --eval "

// Base demo data - will be duplicated
const baseUsers = [
  { name: 'Alice Johnson', dept: 'Engineering', city: 'New York', age: 28 },
  { name: 'Bob Smith', dept: 'Marketing', city: 'Los Angeles', age: 35 },
  { name: 'Charlie Brown', dept: 'Sales', city: 'Chicago', age: 42 },
  { name: 'Diana Prince', dept: 'HR', city: 'Houston', age: 31 },
  { name: 'Eve Wilson', dept: 'Finance', city: 'Phoenix', age: 29 }
];

const TOTAL_DOCS = $COUNT;
const BATCH_SIZE = 1000;
let insertedCount = 0;

print('Generating ' + TOTAL_DOCS + ' documents from base dataset...');

for (let batch = 0; batch < Math.ceil(TOTAL_DOCS / BATCH_SIZE); batch++) {
  const documents = [];
  const batchStart = batch * BATCH_SIZE;
  const batchEnd = Math.min(batchStart + BATCH_SIZE, TOTAL_DOCS);
  
  for (let i = batchStart; i < batchEnd; i++) {
    const base = baseUsers[i % baseUsers.length];
    documents.push({
      userId: i + 1,
      username: base.name.toLowerCase().replace(/\s+/g, '') + (i + 1),
      name: base.name,
      email: base.name.toLowerCase().replace(/\s+/g, '.') + (i + 1) + '@company.com',
      department: base.dept,
      city: base.city,
      age: base.age + (i % 10),
      salary: 50000 + (i % 100) * 1000,
      active: i % 5 !== 0,
      createdAt: new Date()
    });
  }
  
  db.users.insertMany(documents, { ordered: false });
  insertedCount += documents.length;
  
  if ((batch + 1) % 5 === 0 || batch === Math.ceil(TOTAL_DOCS / BATCH_SIZE) - 1) {
    print('Progress: ' + insertedCount + '/' + TOTAL_DOCS + ' documents');
  }
}

print('✓ Inserted ' + insertedCount + ' documents');

// Create indexes
db.users.createIndex({ userId: 1 });
db.users.createIndex({ email: 1 });
db.users.createIndex({ department: 1 });

print('✓ Indexes created');
print('Total Documents: ' + db.users.countDocuments());
"

echo ""
echo "✅ Data insertion complete!"
echo ""
echo "Sample queries:"
echo "  docker exec $CONTAINER mongosh testdb --quiet --eval \"db.users.find().limit(5)\""
echo "  docker exec $CONTAINER mongosh testdb --quiet --eval \"db.users.countDocuments()\""
echo ""
