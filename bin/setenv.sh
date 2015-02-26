#!/bin/bash

# Set this to location of stormhpc
export STORMHPC_HOME="/N/u/skamburu/projects/stormhpc"

# Set this to the location of the Storm installation
export STORM_HOME="/N/u/skamburu/software/apache-storm-0.9.2"

# Set this to the location you want to use for storm local dir
export STORM_LOCAL_DIR="/tmp/$HOSTNAME/local-dir"

# Set this to the location where you want the storm logfies
export STORM_LOG_DIR="/tmp/$HOSTNAME/local-dir"

# set this to the location where your zk is located
export ZK_HOME="/N/u/skamburu/software/zookeeper-3.4.6"

# set this to the location where your zk data is located
export ZK_DATA_DIR="/tmp/$HOSTNAME/zkdata"

