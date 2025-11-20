#!/bin/bash

set -e

echo "🚀 Starting MongoDB Sharded Cluster..."
echo "======================================"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Start all containers
echo -e "${BLUE}📦 Launching Docker containers...${NC}"
docker-compose -f docker-compose.sharding.yml up -d

# Wait for containers to start
echo -e "${YELLOW}⏳ Waiting for containers to be ready (35 seconds)...${NC}"
sleep 35

# Initialize sharding
echo -e "${BLUE}🔧 Initializing sharded cluster...${NC}"
./scripts/init-sharding.sh

# Check status
echo -e "${GREEN}✅ Sharded cluster initialization complete!${NC}"
echo ""
echo "======================================"
echo "Connection Information:"
echo "======================================"
echo "Mongos Router: mongodb://localhost:27017"
echo ""
echo "Config Servers:"
echo "  - config-server-1: localhost:40001"
echo "  - config-server-2: localhost:40002"
echo "  - config-server-3: localhost:40003"
echo ""
echo "Shards:"
echo "  - Shard 1: localhost:50001, localhost:50011"
echo "  - Shard 2: localhost:50002, localhost:50012"
echo ""
echo "======================================"
echo "Next Steps:"
echo "======================================"
echo "1. Check status:       ./scripts/check-sharding-status.sh"
echo "2. Insert data:        ./scripts/insert-data.sh sharding 25000"
echo "3. Test distribution:  ./scripts/test-sharding.sh"
echo ""
