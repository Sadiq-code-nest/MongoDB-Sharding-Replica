#!/bin/bash

echo "Which mode do you want to run?"
echo "1) replica"
echo "2) sharding"
read -p "Choose mode: " mode

if [ "$mode" == "1" ] || [ "$mode" == "replica" ]; then
    echo "[RUN] Replica Mode"
    bash scripts/start-replica.sh
    bash scripts/init-replica.sh
    bash scripts/insert-data.sh replica
    bash scripts/test-failover.sh
    bash scripts/check-status.sh

elif [ "$mode" == "2" ] || [ "$mode" == "sharding" ]; then
    echo "[RUN] Sharding Mode"
    bash scripts/start-sharding.sh
    bash scripts/init-sharding.sh
    bash scripts/insert-data.sh sharding
    bash scripts/test-sharding.sh
    bash scripts/check-sharding-status.sh

else
    echo "Invalid option"
    exit 1
fi
