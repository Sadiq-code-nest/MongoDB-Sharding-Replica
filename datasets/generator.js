// Simplified MongoDB Data Generator
// Base dataset that gets multiplied for bulk inserts

const baseUsers = [
  { name: 'Alice Johnson', dept: 'Engineering', city: 'New York', age: 28 },
  { name: 'Bob Smith', dept: 'Marketing', city: 'Los Angeles', age: 35 },
  { name: 'Charlie Brown', dept: 'Sales', city: 'Chicago', age: 42 },
  { name: 'Diana Prince', dept: 'HR', city: 'Houston', age: 31 },
  { name: 'Eve Wilson', dept: 'Finance', city: 'Phoenix', age: 29 },
  { name: 'Frank Miller', dept: 'Engineering', city: 'Seattle', age: 33 },
  { name: 'Grace Lee', dept: 'Operations', city: 'Boston', age: 27 },
  { name: 'Henry Davis', dept: 'Sales', city: 'Miami', age: 38 },
  { name: 'Iris Chen', dept: 'Product', city: 'Austin', age: 30 },
  { name: 'Jack Ryan', dept: 'Support', city: 'Denver', age: 26 }
];

function generateUser(id) {
  const base = baseUsers[id % baseUsers.length];
  return {
    userId: id,
    username: base.name.toLowerCase().replace(/\s+/g, '') + id,
    name: base.name,
    email: `${base.name.toLowerCase().replace(/\s+/g, '.')}${id}@company.com`,
    department: base.dept,
    city: base.city,
    age: base.age + (id % 10),
    salary: 50000 + (id % 100) * 1000,
    active: id % 5 !== 0,
    createdAt: new Date()
  };
}

function generateBatch(startId, count) {
  const batch = [];
  for (let i = 0; i < count; i++) {
    batch.push(generateUser(startId + i));
  }
  return batch;
}

// Export for Node.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { generateUser, generateBatch, baseUsers };
}

// Usage in MongoDB shell:
// load('datasets/generator.js')
// db.users.insertMany(generateBatch(1, 10000))
