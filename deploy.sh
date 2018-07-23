#!/bin/bash

PROJECT="https://github.com/mdn/beginner-html-site.git"
PROJECT_PATH = "/usr/sites/project"
DATA_DIR="/opt/datadir"

install_docker () {
   apt update && apt upgrade -y && curl -fsSL get.docker.com -o get-docker.sh && bash get-docker.sh && usermod -aG docker ubuntu
}

install_git () {
   apt update && apt upgrade -y && apt install git
}

install_packages () {
   apt-get update
   apt-get upgrade -y
   apt-get distr-upgrade -y
   apt-get install -y  aptitude
   aptitude purge  mysql-client -y
   aptitude install mysql-client nginx mc htop vim -y || true 
}

git_clone () {
	mkdir  /usr/sites/project || true && cd /usr/sites/project || true && git clone $PROJECT .
}

run_nginx () {
    # запускаем сайт с эмблемой файрфокса http://172.17.8.11/
	#TODO: Почему то не работает на 80 порту и с переменной $PROJECT_PATH!!!
	#запускаю так:  docker run --name project-nginx -p 80:80  -v $PROJECT_PATH:/usr/share/nginx/html:ro -d nginx
	
	docker run --name project-nginx -p 8080:80  -v /usr/sites/project:/usr/share/nginx/html:ro -d nginx
	
	#TODO: пофиксить 403 ошибку, программист утверждает что если заранее клонировать репу с проектом вручную то все заработает
	#TODO: вобщем что то с нжинксом поэтому сайт доступен только по http://172.17.8.11:8080/, а надо на 80 порту
} 

run_mysql () {
	mkdir -p $DATA_DIR || true 
    docker run --name mymysql  -p 3306:3306 -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:5.6
	#TODO: было бы хорошо персистентное хранилище сделать в $DATA_DIR , а не каждый раз заливать дамп при пересоздании докера с базой
}

cd /tmp
install_docker
install_packages
install_git
git_clone 
run_nginx
run_mysql && sleep 30

cat <<EOT >> /tmp/dump.sql
create database simplesite;
use simplesite
create table SUBJECT
(
  SUBJ_ID   NUMERIC not null,
  SUBJ_NAME VARCHAR(60),
  HOUR      NUMERIC,
  SEMESTER   NUMERIC
)

alter table SUBJECT
  add primary key (SUBJ_ID);

create table UNIVERSITY
(
  UNIV_ID   NUMERIC not null,
  UNIV_NAME VARCHAR(160),
  RATING    NUMERIC,
  CITY      VARCHAR(60)
);

alter table UNIVERSITY
  add primary key (UNIV_ID);

EOT

mysql -h 127.0.0.1 -u root -pmy-secret-pw < /tmp/dump.sql
#TODO: пофиксить ERROR You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '' at line 1

mysql -h 127.0.0.1 -u root -pmy-secret-pw simplesite -e "show table;"
#TODO: пофиксить ERROR 1064 (42000) at line 1: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '' at line 1

#TODO: сделать возможность пользователю vagrant просматривать запущенные докер контейнеры

#TODO: оптимизировать скрипт деплоя!!!


