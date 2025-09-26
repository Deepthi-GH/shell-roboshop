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
dnf module disable redis -y &&>$LOG_FILE
VALIDATE $? "disabling redis"
dnf module enable redis:7 -y &&>$LOG_FILE
VALIDATE $? "enabling redis"
dnf install redis -y &&>$LOG_FILE
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf

systemctl enable redis &&>$LOG_FILE
VALIDATE $? "enabling redis"

systemctl start redis &&>$LOG_FILE
VALIDATE $? "starting redis"
END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "script executed at : $Y $TOTAL_TIME seconds"
