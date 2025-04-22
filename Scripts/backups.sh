#!/bin/bash
# Cifrar backups con Borg
docker stop nextcloud
borg create /mnt/backups::nextcloud-$(date +%Y-%m-%d) /var/lib/docker/volumes/nextcloud_data
docker start nextcloud
