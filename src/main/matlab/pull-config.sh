#!/usr/bin/env bash

#--chown=jwhite:admin \
#sudo 
rsync \
    -aiH \
    --include=Chem.m \
    --include=Config.m \
    --include=TargetCatalog.m \
    --include=TestingCatalog.m \
    --include=TrainingCatalog.m \
    --safe-links \
    --exclude="*.m" \
    --exclude="*.m~" \
    --exclude="*.swp" \
    --exclude=log/ \
    --exclude=.DS_Store \
    --exclude=push.sh \
    --exclude=pull.sh \
    --exclude=.nfs.* \
    --exclude=target/ \
    --exclude=process_test.m \
    --no-p \
    --no-o \
    --no-g \
    $@ gootch:/mnt/nfs/proj/in-vitro/iterate/src/ ./
