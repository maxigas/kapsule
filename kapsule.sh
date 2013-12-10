#!/bin/bash
# Stop on error:
set -e
# DEBUG
set -x

# CONFIG
INT_DEV=/dev/sdb1
EXT_DEV=/dev/sdc1
INT_DIR=/mount/int
INT_DIR=/mount/ext
# Says if we are doing something actively atm:
ACTIVE="false"
# Says how much free space we have:
INT_FREE=0
EXT_FREE=0
EXT_DATA=0

# SANITY CHECKS
# Exit values:
# 1  Already running.
# 2  No storage.

if [ -f /tmp/kapsule.lock ]; then
    echo "Already running. Exiting."
    exit 1
fi

if [ -f $STORAGE ]; then
    echo "No storage. Exiting."
    exit 2
fi

# CHECK FOR NEW DEVICE

if ! $ACTIVE; then
    if [ -f $EXT_DEV ]; then
        echo "Found new device..."
        mount $EXT_DEV $EXT_DIR
        EXT_FREE=$(df --sync --source="available" -h $EXT_DEV|grep -v "Avail")
        INT_FREE=$(df --sync --source="available" -h $INT_DEV|grep -v "Avail")
        EXT_DATA=$(df --sync --source="used" -h $EXT_DEV|grep -v "Used")
        if [ $EXT_DATA < $INT_FREE ]; then
            echo "Decided to copy data..."
            DATE=$(date +%Y-%m-%d)
            mkdir $INT_DIR/$DATE
            cp -vR $EXT_DIR $INT_DIR/$DATE
            sync
            sync
        fi
        echo "Unmounting..."
        umount -f $EXT_DIR
    else
        echo "No new device..."
    fi
else
    echo "Already running..."
fi






