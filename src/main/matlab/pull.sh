#!/usr/bin/env bash

    #--chown=jwhite:admin \
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
    --exclude=.nfs.* \
    --exclude=*.swp \
    --no-p \
    --no-o \
    --no-g \
    $@ dirac-login:/mnt/nfs/proj/in-vitro/iterate/src/ ./
