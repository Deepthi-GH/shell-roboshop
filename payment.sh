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
SCRIPT_DIR=$(pwd)
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
    echo -e "error::$2 ...  $R FAILED $N"|tee -a $LOG_FILE
    exit 1
else
    echo -e "$2 ... $Y SUCCESS $N"|tee -a $LOG_FILE
fi    
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "installing python"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating user roboshop"
else
    echo -e "user already existing...$Y SKIPPING $N"    
fi

mkdir -p /app  &>>$LOG_FILE
VALIDATE $? "created /app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading payment application"

cd /app 
VALIDATE $? "changing to app directory"
rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzipping the code"

cd /app 
pip3 install -r requirements.txt  &>>$LOG_FILE
VALIDATE $? "downloading dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "copying service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "enable payment"
systemctl restart payment &>>$LOG_FILE
VALIDATE $? "restarted payment"