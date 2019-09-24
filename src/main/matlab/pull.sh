#!/usr/bin/env bash

    #--chown=jwhite:admin \
#sudo 
rsync \
    -aiH \
    --safe-links \
    --exclude="*.m~" \
    --exclude="*.swp" \
    --exclude=log/ \
    --exclude=.DS_Store \
    --exclude=push.sh \
    --exclude=pull.sh \
    --exclude=.nfs.* \
    --exclude=target/ \
    --exclude=Chem.m \
    --exclude=Config.m \
    --exclude=TargetCatalog.m \
    --exclude=TestingCatalog.m \
    --exclude=TrainingCatalog.m \
    --exclude=process_test.m \
    --no-p \
    --no-o \
    --no-g \
    $@ hnl02:/mnt/nfs/proj/in-vitro/iterate/src/ ./
