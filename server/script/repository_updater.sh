#!/bin/sh
# Repository updater
# This script will called from the webhook receiver.
# 
# You can also write additional processing.
# If you want to write the yourself script, please make and write to:
# repository_updater.production.sh
# (If that file exists, It will called in preference to this file.)

GIT_PATH='/usr/bin/git'
TARGET_REPONAME='origin'
TARGET_BRANCH=$1
$GIT_PATH fetch $TARGET_REPONAME $TARGET_BRANCH
$GIT_PATH reset --hard FETCH_HEAD
