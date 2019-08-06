#!/usr/bin/env bash

#SBATCH --job-name=iv-sources
#SBATCH --output=log/iv-sources_%a.out
#SBATCH --error=log/iv-sources_%a.err
#SBATCH --array=0-9
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#XXXXXX --exclusive


######################
# Begin work section #
######################

# collect job information
NODE_ID=${SLURM_ARRAY_TASK_ID:-0}
NUM_NODES=${SLURM_ARRAY_TASK_COUNT:-1}
NUM_CPUS=${SLURM_CPUS_PER_TASK:-1}

# print this sub-job's task ID
echo "BEGIN BATCH $SLURM_JOB_NAME"
echo "[$(hostname)] nodeId=$NODE_ID numNodes=$NUM_NODES cpuCount=$NUM_CPUS"
sleep 1

# load MATLAB module
module load MATLAB || exit 1

# get rid of default java options (not sure where this is coming from)
unset _JAVA_OPTIONS

# run matlab
matlab -nodisplay -nosplash -nodesktop << EOF
try
    process_cluster_sources( $NODE_ID, $NUM_NODES, $NUM_CPUS );
catch e
    disp(getReport(e));
    delete(gcp('nocreate'));
    exit(1);
end

disp('DONE');
exit(0)
EOF

sleep 1
echo "END BATCH $SLURM_JOB_NAME"

