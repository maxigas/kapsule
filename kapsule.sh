#!/bin/bash
# Stop on error:
set -e
# DEBUG
set -x

# CONFIG
INT_DEV=/dev/sdb1
EXT_DEV=/dev/sdc1
INT_DIR=/mount/int
EXT_DIR=/mount/ext
# Says if we are doing something actively atm:
ACTIVE=false
INT_FREE=0
EXT_FREE=0
EXT_DATA=0
LOCK_FILE=/tmp/kapsule.lock
ACTI_FILE=/tmp/kapsule.acti

# SANITY CHECKS
# Exit values:
# 1  Already running.
# 2  No storage.

if [ -f /tmp/kapsule.lock ]; then
    echo "Already running. Exiting."
    exit 1
fi

if [ -f $EXT_DEV ]; then
    echo "No storage. Exiting."
    exit 2
fi

# CHECK FOR NEW DEVICE

if ! [ -f $ACTIVE ]; then
touch /tmp/kapsule.lock
    if [ -f $EXT_DEV ]; then
        touch /tmp/kapsule.acti
        echo "Found new device..."
        mount $EXT_DEV $EXT_DIR
        EXT_FREE=$(df -m $EXT_DIR | tail -n 1 | awk '{print $4}')
        INT_FREE=$(df -m $INT_DIR | tail -n 1 | awk '{print $4}')
        EXT_DATA=$(df -m $EXT_DIR | tail -n 1 | awk '{print $3}')
        INT_DATA=$(df -m $INT_DIR | tail -n 1 | awk '{print $3}')
        if [ $EXT_DATA < $INT_FREE ]; then
            echo "Decided to copy data in..."
            DATE=$(date +%Y-%m-%d)
            mkdir $INT_DIR/$DATE
            cp -vR $EXT_DIR $INT_DIR/$DATE
            sync
            sync
        fi
        if [ $INT_DATA < $EXT_DREE ]; then
            echo "Decided to copy data out..."
            mkdir $EXT_DIR/kapsule
            cp -vR $INT_DIR $EXT_DIR/kapsule
            sync
            sync
        fi
        echo "Unmounting..."
        umount -f $EXT_DIR
        rm $ACTI_FILE
    else
        echo "No new device..."
    fi
rm /tmp/kapsule.lock
else
    echo "Already active..."
fi

