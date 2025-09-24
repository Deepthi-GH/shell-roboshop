#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-074e260911c3a2487"
ZONE_ID="Z10084241A7O0LJXGH49U"
DOMAIN_NAME="deepthi.cloud"

for INSTANCE in $@
do 
  INSTANCES_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" --query 'Instances[0].InstanceId' --output text)

if [ $INSTANCE != "frontend" ]
then
   IP=$(aws ec2 describe-instances --instance-ids $INSTANCES_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
   RECORD_NAME=$INSTANCE.$DOMAIN_NAME
else
   IP=$(aws ec2 describe-instances --instance-ids $INSTANCES_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
   RECORD_NAME=$DOMAIN_NAME
fi
echo "$INSTANCE: $IP"

aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
    "Comment": "Updating record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }
  '
done