#!/bin/sh
# Author: maxigas <maxigas@anargeek.net> and webmind <webmind@puscii.nl>
# Licence: GPLv3
# ----------------------------------------------------------------------
# Stop on error:
# set -e
# DEBUG
# set -x

# CONFIG
INT_DEV=/dev/sdb1
EXT_DEV=/dev/sdc1
INT_MNT=/mnt/int
EXT_MNT=/mnt/ext
INT_DIR=$INT_MNT/kapsule
EXT_DIR=$EXT_MNT/kapsule
# Program directory: has to contain kapsule.sh and motion.config
PRG_DIR=/home/mxs/dev/kapsule/
DATE=$(date +%Y-%m-%d)

# Says if we are doing something actively atm:
ACTIVE=false
INT_FREE=0
EXT_FREE=0
EXT_DATA=0
LOCK_FILE=/tmp/kapsule.lock

# SANITY CHECKS
# Exit values:
# 1  Already running.
# 2  No external storage.
# 3  No internal storage

if [ -f $LOCK_FILE ]; then
    echo "Already running. Exiting."
    exit 1
fi

if ! [ -b $EXT_DEV ]; then
    echo "No storage. Exiting."
    exit 2
fi

if ! [ -d $INT_MNT ]; then
    echo "Internal mount directory does not exist."
    echo "Creating it."
    mkdir $INT_MNT
fi

if ! [ -d $EXT_MNT ]; then
    echo "External mount directory does not exist."
    echo "Creating it."
    mkdir $EXT_MNT
fi

# CHECK IF INTERNAL STORAGE EXISTS AND IS MOUNTED

if ! [ -b $INT_DEV ]; then
    echo "No internal storage device. Exiting."
    exit 3
fi

if ! [ -f $INT_DIR/mounted ]; then
    mount $INT_DEV $INT_MNT
    echo "Mounting internal storage.  We should do this only the first time."
fi

# CHECK FOR NEW DEVICE

touch $LOCK_FILE
if [ -b $EXT_DEV ]; then
    echo "Found new device..."
    # MOTION PART OVER
    echo "Stopping motion capture..."
    killall -SIGTERM motion
    # MOTION PART START
    if mount | grep $EXT_MNT > /dev/null; then
        echo "Hm something is already mounted in EXT_MNT so we unmount it to be sure."
        umount $EXT_MNT
    fi
    mount $EXT_DEV $EXT_MNT        
    EXT_FREE=$(df -m $EXT_DIR | tail -n 1 | awk '{print $4}')
    INT_FREE=$(df -m $INT_DIR | tail -n 1 | awk '{print $4}')
    # Better to use du instead of df here
    EXT_DATA=$(du $EXT_DIR | tail -n 1 | awk '{print $1}')
    INT_DATA=$(du $INT_DIR | tail -n 1 | awk '{print $1}')
    # DEBUG
    echo EXT_DIR: $EXT_DIR, INT_DIR: $INT_DIR
    echo EXT_FREE: $EXT_FREE, INT_FREE: $INT_FREE, EXT_DATA: $EXT_DATA, INT_DATA: $INT_DATA
    if [ $EXT_DATA -lt $INT_FREE ]; then
        echo "Decided to copy data in..."
        if ! [ -d $EXT_DIR/$DATE ]; then
            mkdir $EXT_DIR/$DATE
        fi
        touch $INT_DIR/kapsule_was_here
        cp -vR $INT_DIR/* $EXT_DIR/$DATE/.
            sync
            sync
    else
        echo "No we will not copy any data in."
    fi
    if [ $INT_DATA -lt $EXT_FREE ]; then
        echo "Decided to copy data out..."
        if ! [ -d $EXT_DIR/$DATE ]; then
            mkdir $EXT_DIR/$DATE
        fi
        cp -vR $INT_DIR/* $EXT_DIR/$DATE
        sync
        sync
    else
        echo "No we will not copy any data out."
    fi
    echo "Unmounting..."
    umount -f $EXT_DEV
    # MOTION PART START
    echo "Starting motion capture."
    if ! [ -d $INT_DIR/motion ]; then
        echo "Creating new directory."
        mkdir $INT_DIR/motion
    fi
    if ! [ -f $PRG_DIR/motion.conf ]; then
        echo "Cannot find motion.conf"
    fi
    echo "Starting motion"
    motion -c $PRG_DIR/motion.conf
    # MOTION PART OVER
else
    echo "No new device..."
fi
rm $LOCK_FILE
echo READY
