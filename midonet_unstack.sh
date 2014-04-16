#!/usr/bin/env bash

MIDO_DIR=$(pwd)
DEVSTACK_DIR="$MIDO_DIR/devstack"

# Destination directory
DEST=${DEST:-/opt/stack}

source $MIDO_DIR/midonetrc
source $MIDO_DIR/functions

# Execute stack script
cd $DEVSTACK_DIR && source unstack.sh

# Clean up ZK
stop_service zookeeper
sleep 3
sudo rm -rf /var/lib/zookeeper/version-2/

# Clean up Cassandra
stop_service cassandra
sudo rm -rf /var/lib/cassandra/*

# Start zinc, restart if running
ZINC_DIR=$MIDO_DEST/zinc
if is_running "zinc"
then
    echo "Stopping zinc"
    $ZINC_DIR/bin/zinc -shutdown
fi

# Shut down midonet screen 
MIDO_SCREEN=$(which screen)
if [[ -n "$MIDO_SCREEN" ]]; then
    MIDO_SESSION=$(screen -ls | awk '/[0-9].mido/ { print $1 }')
    if [[ -n "$MIDO_SESSION" ]]; then
        screen -X -S $MIDO_SESSION quit
    fi
fi

# Clean up uplink settings

sudo ip -o link ls | grep veth[0-9a] | cut -d' ' -d':'  -f2 | while read dev ; do sudo ip link del $dev 2> /dev/null ; done
sudo ip link set down uplinkbridge 2> /dev/null
sudo brctl delbr uplinkbridge 2> /dev/null
