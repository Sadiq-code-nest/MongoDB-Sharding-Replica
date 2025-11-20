#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "🔄 MongoDB Mode Switcher"
echo "========================"
echo ""
echo "Select mode:"
echo "1) Replica Set (High Availability)"
echo "2) Sharded Cluster (Horizontal Scaling)"
echo "3) Exit"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
  1)
    echo ""
    echo -e "${YELLOW}Switching to Replica Set mode...${NC}"
    ./scripts/cleanup.sh
    sleep 2
    ./scripts/start-replica.sh
    echo ""
    echo -e "${GREEN}✅ Replica Set mode activated!${NC}"
    echo "Next steps:"
    echo "  ./scripts/check-status.sh"
    echo "  ./scripts/insert-data.sh replica 15000"
    echo "  ./scripts/test-failover.sh"
    ;;
  2)
    echo ""
    echo -e "${YELLOW}Switching to Sharded Cluster mode...${NC}"
    ./scripts/cleanup.sh
    sleep 2
    ./scripts/start-sharding.sh
    echo ""
    echo -e "${GREEN}✅ Sharded Cluster mode activated!${NC}"
    echo "Next steps:"
    echo "  ./scripts/check-sharding-status.sh"
    echo "  ./scripts/insert-data.sh sharding 25000"
    echo "  ./scripts/test-sharding.sh"
    ;;
  3)
    echo "Exiting..."
    exit 0
    ;;
  *)
    echo -e "${RED}Invalid choice!${NC}"
    exit 1
    ;;
esac
