#!/usr/bin/env bash

sudo rsync \
    -aiH \
    --safe-links \
    --exclude="*.m~" \
    --exclude=log/ \
    --exclude=.DS_Store \
    --exclude=push.sh \
    --exclude=pull.sh \
    --chown=10145:10026 \
    $@ ./ /mnt/nfs/proj/pd/jason/iterate/src/
