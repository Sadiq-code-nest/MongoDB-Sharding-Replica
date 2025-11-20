#!/bin/bash

echo "🧹 MongoDB Cleanup Script"
echo "========================="

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo -e "${YELLOW}This will remove:${NC}"
echo "  • All MongoDB containers"
echo "  • All data volumes"
echo "  • MongoDB network"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Cleanup cancelled."
  exit 0
fi

echo ""
echo -e "${RED}Stopping and removing containers...${NC}"

# Stop replica set
if docker-compose -f docker-compose.replica.yml ps -q 2>/dev/null | grep -q .; then
  echo "Cleaning up replica set..."
  docker-compose -f docker-compose.replica.yml down -v
fi

# Stop sharding cluster
if docker-compose -f docker-compose.sharding.yml ps -q 2>/dev/null | grep -q .; then
  echo "Cleaning up sharded cluster..."
  docker-compose -f docker-compose.sharding.yml down -v
fi

# Remove any orphaned containers
echo "Removing orphaned containers..."
docker ps -a --filter "name=mongo-node" --filter "name=config-server" --filter "name=shard" --filter "name=mongos" -q | xargs -r docker rm -f

# Remove volumes
echo "Removing data volumes..."
docker volume ls --filter "name=mongo" -q | xargs -r docker volume rm

# Remove network
echo "Removing network..."
docker network rm mongodb-network 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo "To start fresh:"
echo "  Replica Set:     ./scripts/start-replica.sh"
echo "  Sharded Cluster: ./scripts/start-sharding.sh"
echo ""
