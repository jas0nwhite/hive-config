#!/usr/bin/env bash

    #--chown=10145:10026 \
#sudo 
rsync \
    -aiH \
    --safe-links \
    --exclude="*.m~" \
    --exclude=log/ \
    --exclude=.DS_Store \
    --exclude=push.sh \
    --exclude=pull.sh \
    $@ ./ dirac-login:/mnt/nfs/proj/in-vitro/iterate/src/
