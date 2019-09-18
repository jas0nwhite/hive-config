#!/usr/bin/env bash



######################
# CONFIGURATION      #
######################

# The following are arguments that can be passed to sbatch; man sbatch for a full list.

#SBATCH --job-name=matlab-test
#SBATCH --output=log/matlab-test.out
#SBATCH --error=log/matlab-test.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48

### 
### Note, paths above are relative to the current working directory when sbatch is executed.
### Make sure any directories already exist ("log" in this case)
###


######################
# SETUP              #
######################

# Print this job's task ID and info to the log file.
# ...these variables are set by SBATCH; man sbatch for a full list ("OUTPUT ENVIRONMENT VARIABLES" section).
echo "BEGIN BATCH $SLURM_JOB_NAME"
echo "[$(hostname)] nodeId=$SLURM_NODEID numNodes=$SLURM_NTASKS cpuCount=$SLURM_CPUS_PER_TASK (of $SLURM_CPUS_ON_NODE)"

# you can use your own variables and do some math in the shell
# the following calculates how many workers we can use given SLURM_CPUS_PER_TASK and 2 cpus per worker
CPUS_PER_WORKER=2
NUM_WORKERS=$(( $SLURM_CPUS_PER_TASK / $CPUS_PER_WORKER ))


######################
# TASK               #
######################

# Load MATLAB module.
module load MATLAB || exit 1

# Get rid of default java options.
unset _JAVA_OPTIONS

# Run matlab commands (between the two EOF markers).
matlab -nodisplay -nosplash -nodesktop << EOF
T=tic;

try
    disp ' '
    disp 'Run matlab script here.'
    disp 'Insert shell variables where appropriate.'
    disp 'e.g. process_cluster_sets( $SLURM_NODEID, $SLURM_NTASKS, $NUM_WORKERS, $CPUS_PER_WORKER );'
    disp ' '
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

# Print end-of-job line to the log file.
echo "END BATCH $SLURM_JOB_NAME"



###
### How to run
###

# mkdir log
# sbatch matlab-test.sh


###
### Example output in log/matlab-test.out
###

# BEGIN BATCH matlab-test
# [cnode004] nodeId=0 numNodes=1 cpuCount=48 (of 48)
# 
#                             < M A T L A B (R) >
#                   Copyright 1984-2018 The MathWorks, Inc.
#                    R2018b (9.5.0.944444) 64-bit (glnxa64)
#                               August 28, 2018
# 
# 
# To get started, type doc.
# For product information, visit www.mathworks.com.
# 
# >> >> >>
# Run matlab script here.
# Insert shell variables where appropriate.
# e.g. process_cluster_sets( 0, 1, 24, 2 );
# 
# >> >>
# 
# DONE (0.0s)
# >> END BATCH matlab-test
