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
START_TIME=$(date +%s)
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

dnf install mysql-server -y &>>$LOG_FILE
