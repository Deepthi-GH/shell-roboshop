#!/bin/bash
set -euo pipefail
trap 'echo "there is an error in $LINENO and command is $BASH_COMMAND"' err
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"
LOGS_FOLDER=/var/log/shell-roboshop
SCRIPT_NAME=$( echo $0|cut -d "." -f1 )
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME.log
MONGODB_HOST=mongodb.deepthi.cloud
SCRIPT_DIR=$(pwd)
mkdir -p $LOGS_FOLDER
echo "script started at: $(date)" |tee -a $LOG_FILE
if [ $USERID -ne 0 ] 
then
    echo "error::please run this script with root priviliges"
    exit 1
fi
dnf module disable nodejs -y &>>$LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE
dnf install nodejs -y &>>$LOG_FILE

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    
else
    echo -e "user already existing...$Y SKIPPING $N"    
fi

mkdir -p /app  &>>$LOG_FILE
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
cd /app 
rm -rf /app/*
unzip /tmp/catalogue.zip &>>$LOG_FILE
npm install &>>$LOG_FILE
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongoshhhh -y &>>$LOG_FILE
INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ] 
then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else
    echo -e "already catalogue products loaded ...$Y SKIPPING $N"
fi    

systemctl restart catalogue
