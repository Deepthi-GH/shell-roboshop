#!/bin/bash
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
SCRIPT_DIR=$pwd
mkdir -p $LOGS_FOLDER
echo "script started at: $(date)" |tee -a $LOG_FILE
if [ $USERID -ne 0 ] 
then
    echo "error::please run this script with root priviliges"
    exit 1
fi

VALIDATE()
{
    if [ $1 -ne 0 ] 
then
    echo -e "error::$2 ...  $R failed $N"|tee -a $LOG_FILE
    exit 1
else
    echo -e "$2 ... $Y success $N"|tee -a $LOG_FILE
fi    
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs"
id roboshop
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating user roboshop"
else
    echo -e "user already existing...$Y SKIPPING $N"    
fi

mkdir -p /app  &>>$LOG_FILE
VALIDATE $? "created /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading catalogue application"

cd /app 
VALIDATE $? "changing to app directory"
rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping the code"

npm install &>>$LOG_FILE
VALIDATE $? "downloading dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "enable catalogue"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "start catalogue"

cp mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing mongodb client"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "load products data"

systemctl restart catalogue
VALIDATE $? "restarted catalogue"

#mongosh --host MONGODB-SERVER-IPADDRESS &>>$LOG_FILE

#show dbs &>>$LOG_FILE
#use catalogue &>>$LOG_FILE
#show collections &>>$LOG_FILE
#db.products.find() &>>$LOG_FILE






