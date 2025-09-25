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
MYSQL_HOST=mysql.deepthi.cloud
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
dnf install maven -y &>>$LOG_FILE
VALIDATE $? "installing maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating user roboshop"
else
    echo -e "user already existing...$Y SKIPPING $N"    
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating /app directory"
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading code"
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping code"
cd /app 
mvn clean package &>>$LOG_FILE
VALIDATE $? "executing clean package"
mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "moving jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "copying service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon-reload"
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "enabling shipping"
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "starting shipping"
dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "installing mysql"

#mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'  &>>$LOG_FILE
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'show databases like "cities";' | grep cities &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql  &>>$LOG_FILE
else
    echo -e "shipping  data is laready loaded.. $Y SKIPPING $N"
fi    
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restarting shipping"