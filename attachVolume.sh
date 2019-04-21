#!/usr/bin/env bash

# Script gets availability zone of instance, creates volume from most recent snapshot

# install jq in order to parse the returns for the latest snapshot
sudo yum -y install jq

# get snapshots for the instance, and parse to the latest version
SNAPSHOT=$(aws ec2 describe-snapshots --filters Name=tag-value,Values=opsJenkins | jq -r '. [] | max_by(.StartTime) | .SnapshotId')
# create var that stores the current instances availability zone
AVAIL_ZONE=$(curl -q http://169.254.169.254/latest/dynamic/instance-identity/document|grep availabilityZone|awk -F\" '{print $4}')
# creates volume from snapshot, adds tags for name and enable daily backup
/usr/bin/aws ec2 create-volume --size 1000 --region us-east-1 --availability-zone $AVAIL_ZONE --snapshot-id $SNAPSHOT --volume-type gp2 --tag-specifications 'ResourceType=volume,Tags=[{Key=jenkinsBU,Value=opsJenkins},{Key=DailyBackup,Value=True}]'
# wait 1 minute for the volume to instantiate
sleep 1m 
# get volumeid, assigns to var
VOLUMEID=$(aws ec2 describe-volumes --filters Name=tag-value,Values=opsJenkins Name=availability-zone,Values=$AVAIL_ZONE | jq -r '. [] | max_by(.StartTime) | .VolumeId')
# get instance id, assigns to var
INSTANCE_ID=$(curl -q http://169.254.169.254/latest/dynamic/instance-identity/document | grep instanceId | awk -F\" '{print $4}') 
# attach volume
/usr/bin/aws ec2 attach-volume --device /dev/sdf --instance-id $INSTANCE_ID --volume-id $VOLUMEID
# allow 1 minute for the attach 
sleep 1m
# mount volume
sudo mount /dev/xvdf /opt/
# add volume mount entry to fstab file
sudo echo "/dev/xvdf    	/opt 	ext4    defaults,nofail	0 2" >> /etc/fstab
# set delete on termination flag
/usr/bin/aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --block-device-mappings "[{\"DeviceName\": \"/dev/sdf\",\"Ebs\":{\"DeleteOnTermination\":true}}]"

