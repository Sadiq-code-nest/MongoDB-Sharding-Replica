#!/bin/bash

set -e

echo "🚀 Starting MongoDB Replica Set..."
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Start containers
echo -e "${BLUE}📦 Launching Docker containers...${NC}"
docker-compose -f docker-compose.replica.yml up -d

# Wait for containers to be healthy
echo -e "${YELLOW}⏳ Waiting for containers to be ready (30 seconds)...${NC}"
sleep 30

# Initialize replica set
echo -e "${BLUE}🔧 Initializing replica set...${NC}"
./scripts/init-replica.sh

# Wait for primary election
echo -e "${YELLOW}⏳ Waiting for primary election (10 seconds)...${NC}"
sleep 10

# Check status
echo -e "${GREEN}✅ Replica set initialization complete!${NC}"
echo ""
echo "=================================="
echo "Connection Information:"
echo "=================================="
echo "Primary Node:     mongodb://localhost:27017"
echo "Secondary Node 1: mongodb://localhost:27018"
echo "Secondary Node 2: mongodb://localhost:27019"
echo ""
echo "Replica Set Connection String:"
echo "mongodb://localhost:27017,localhost:27018,localhost:27019/?replicaSet=rs0"
echo ""
echo "=================================="
echo "Next Steps:"
echo "=================================="
echo "1. Check status:     ./scripts/check-status.sh"
echo "2. Insert data:      ./scripts/insert-data.sh replica 15000"
echo "3. Test failover:    ./scripts/test-failover.sh"
echo ""
