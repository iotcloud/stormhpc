#!/bin/bash

# Set this to location of stormhpc
export STORMHPC_HOME="/N/u/skamburu/projects/stormhpc"
#export STORMHPC_HOME="/home/supun/dev/projects/stormforhpc"

# Set this to the location of the Storm installation
export STORM_HOME="/N/u/skamburu/software/apache-storm-0.9.2"
#export STORM_HOME="/home/supun/dev/projects/dist/apache-storm-0.9.3"

# set this to the location where your zk is located
export ZK_HOME="/N/u/skamburu/software/zookeeper-3.4.6"

# set this to the location where your zk data is located
export ZK_DATA_DIR="/tmp/$HOSTNAME/zkdata"

