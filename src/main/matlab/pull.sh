#!/usr/bin/env bash

sudo rsync \
    -aiH \
    --safe-links \
    --exclude="*.m~" \
    --exclude=log/ \
    --exclude=.DS_Store \
    --exclude=push.sh \
    --exclude=pull.sh \
    --exclude=.nfs.* \
    --chown=jwhite:admin \
    $@ /mnt/nfs/proj/pd/jason/iterate/src/ ./
