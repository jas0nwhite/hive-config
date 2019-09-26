#!/usr/bin/env bash



######################
# CONFIGURATION      #
######################

#SBATCH --job-name=iv-sources
#SBATCH --output=log/iv-sources_%a.out
#SBATCH --error=log/iv-sources_%a.err
#SBATCH --array=0-9
#SBATCH --nodes=1-5
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem-per-cpu=2048
#SBATCH --hint=compute_bound
#SBATCH --mail-type=FAIL,ARRAY_TASKS
#SBATCH --mail-user=jas0nw@vtc.vt.edu


######################
# SETUP              #
######################

# task-specific values
CPUS_PER_WORKER=2
MAX_WORKERS=10

# provide defaults if we're not running via sbatch
TASK_ID=${SLURM_ARRAY_TASK_ID:-0}
NUM_TASKS=${SLURM_ARRAY_TASK_COUNT:-1}

# calculate how many workers to use for this task
if [[ -z $SLURM_CPUS_PER_TASK ]]
then
    # not running via sbatch
    NUM_WORKERS=-1
else
    NUM_WORKERS=$(( $SLURM_CPUS_PER_TASK / $CPUS_PER_WORKER ))

    if [[ $NUM_WORKERS -gt $MAX_WORKERS ]]
    then
        NUM_WORKERS=$MAX_WORKERS
    fi
fi

# print summary lines to log file
echo "BEGIN BATCH $SLURM_JOB_NAME"
echo "[$(hostname)] taskID=$TASK_ID numTasks=$NUM_TASKS numWorkers=$NUM_WORKERS (of $SLURM_JOB_CPUS_PER_NODE) cpusPerWorker=$CPUS_PER_WORKER"


######################
# TASK               #
######################

# load MATLAB module
module load MATLAB || exit 1

# get rid of default java options
unset _JAVA_OPTIONS

# run matlab
matlab -nodisplay -nosplash -nodesktop << EOF
T=tic;
try
    process_cluster_sources( $TASK_ID, $NUM_TASKS, $NUM_WORKERS, $CPUS_PER_WORKER );
catch e
    disp(getReport(e));
    delete(gcp('nocreate'));
    exit(1);
end

fprintf('\n\nDONE (%.1fs)\n', toc(T));
exit(0)
EOF


######################
# TEAR-DOWN          #
######################

echo "END BATCH $SLURM_JOB_NAME"

