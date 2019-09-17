#!/usr/bin/env bash

#SBATCH --job-name=iv-sources
#SBATCH --output=log/iv-sources_%a.out
#SBATCH --error=log/iv-sources_%a.err
#SBATCH --array=0-19
#SBATCH --nodes=1-5
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=1536
#SBATCH --hint=compute_bound

###SBATCH --exclusive=user
###SBATCH --ntasks-per-node=2

######################
# Begin work section #
######################

# collect job information
NUM_THREADS=1
NUM_FOLDS=10

NODE_ID=${SLURM_ARRAY_TASK_ID:-0}
NUM_NODES=${SLURM_ARRAY_TASK_COUNT:-1}

if [[ -z $SLURM_CPUS_PER_TASK ]]
then
    NUM_CPUS=-1
else
    NUM_CPUS=$(( $SLURM_CPUS_PER_TASK / $NUM_THREADS ))

    if [[ $NUM_CPUS -gt $NUM_FOLDS ]]
    then
        NUM_CPUS=$NUM_FOLDS
    fi
fi


# print this sub-job's task ID
echo "BEGIN BATCH $SLURM_JOB_NAME"
echo "[$(hostname)] nodeId=$NODE_ID numNodes=$NUM_NODES cpuCount=$NUM_CPUS (of $SLURM_JOB_CPUS_PER_NODE) threadCount=$NUM_THREADS"
sleep 1

# load MATLAB module
module load MATLAB || exit 1

# get rid of default java options (not sure where this is coming from)
unset _JAVA_OPTIONS

# run matlab
matlab -nodisplay -nosplash -nodesktop << EOF
T=tic;
try
    process_cluster_sources( $NODE_ID, $NUM_NODES, $NUM_CPUS, $NUM_THREADS );
catch e
    disp(getReport(e));
    delete(gcp('nocreate'));
    exit(1);
end

fprintf('\n\nDONE (%.1fs)\n', toc(T));
exit(0)
EOF

sleep 1
echo "END BATCH $SLURM_JOB_NAME"

