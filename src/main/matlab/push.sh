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
    --no-p \
    --no-o \
    --no-g \
    $@ ./ dirac-login:/mnt/nfs/proj/in-vitro/iterate/src/
