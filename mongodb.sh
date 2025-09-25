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
    echo -e "error::$2 installation $R failed $N"|tee -a $LOG_FILE
    exit 1
else
    echo -e "$2 installation is $Y success $N"|tee -a $LOG_FILE
fi    
}
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo Repo"
dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing Mongo DB"
systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enable mongodb" 
systemctl start mongod &>>$LOG_FILE
VALIDATE $? "start mongodb"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "allowing remote connections to mongodb"
systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "restarting mongodb"