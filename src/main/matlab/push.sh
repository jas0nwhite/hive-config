#!/usr/bin/env bash

    #--chown=10145:10026 \
#sudo 
rsync \
    -aiH \
    --safe-links \
    --exclude="*.m~" \
    --exclude=".*.swp" \
    --exclude=log/ \
    --exclude=.DS_Store \
    --exclude=push.sh \
    --exclude=pull.sh \
    --exclude=Chem.m \
    --exclude=Config.m \
    --exclude=TargetCatalog.m \
    --exclude=TestingCatalog.m \
    --exclude=TrainingCatalog.m \
    --no-o \
    --no-p \
    --no-g \
    $@ ./ hnl02:/mnt/nfs/proj/in-vitro/iterate/src/
