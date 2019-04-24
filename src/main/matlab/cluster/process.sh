#!/usr/bin/env bash

BATCH_HOME=cluster

# start jobs that process sources
RES=$(sbatch "$@" $BATCH_HOME/process-sources.sh) || exit 1

jid=${RES##* }

# queue job to proces sets after the sources have been processed correctly
sbatch --dependency=afterok:$jid "$@" $BATCH_HOME/process-sets.sh

# show dependencies in squeue output:
squeue -u $USER -o "%.8A %.4C %.10m %.20E"
