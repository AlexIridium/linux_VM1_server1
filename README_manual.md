# Инструкция по устранению неисправностей или аварийному восстановлению серверов "с нуля"

#### Данная инструкция предназначена для технического персонала. Подразумевается, что все необходимые пакеты-файлы, необходимые для установки, дополнительно хранятся отдельно на другом ПК. Технический персонал об этом знает.

Note: 

- Более подробная инсрукция находится по адресу https://github.com/AlexIridium/linux_basic_doc1/blob/main/README_manual.md

#### Важно! Вся веб инфраструктура основана на работе двух серверов/двух виртуальных машин (ВМ). Данные сервера/ВМ находятся в одной сети и имеют доступ в интернет. Общая схема инфраструктуры:

![](https://github.com/AlexIridium/linux_basic_doc1/blob/main/pictures/%D0%BE%D0%B1%D1%89%D0%B0%D1%8F%20%D1%81%D1%85%D0%B5%D0%BC%D0%B0.PNG)

IP адрес ВМ1 - 10.17.86.172

IP адрес ВМ2 - 10.17.86.141

## Сервер №1 / Виртуальная машина №1

Создайте папки и дайте им необходимые права

- mkdir /home/berd/scripts

- chmod 777 /home/berd/scripts

- mkdir /home/berd/filebeat

- chmod 777 /home/berd/filebeat

Скопировать туда файл filebeat_8.17.1_amd64-224190-a5f894.deb

- mkdir /home/berd/grafana

- chmod 777 /home/berd/grafana

Скопировать туда файл grafana_12.3.3_21957728731_linux_amd64-224190-b33d09.deb

Установить название ВМ

- sudo hostnamectl set-hostname VM1

Скопировать в папку /home/berd/scripts следующие скрипты

- install_mysql_master.sh
- install_nginx.sh
- install_apache2.sh
- install_wordpress.sh
- install_monitoring.sh
- install_filebeat.sh
- install_git_vm1.sh
- upload_to_git_vm1.sh

  Запустить скрипты

  - bash install_mysql_master.sh

  Проверить работу репликации на ВМ2, также проверить снятие бекапа с базы данных.

  Установить Nginx

  - bash install_nginx.sh и проверить на адресе 10.17.86.172 : 80

  Установить Apache2

  - bash install_apache2.sh и проверить на адресе 10.17.86.172 : 8080 и 10.17.86.172 : 8081

  Установить CSM Wordpress

  - bash install_wordpress.sh и проверить на адресе 10.17.86.172

  Установить мониторинг (Grafana + Prometheus)

  - bash install_monitoring.sh

  проверить на адресе 10.17.86.172 : 3000

  Установить Filebeat

  - bash install_filebeat.sh

  Установить GIT

  - bash install_git_vm1.sh

  Скопировать SSH-ключ в аккаунт github.com https://github.com/AlexIridium/

  Выполнить команду git clone * указать здесь код из гитахаба *

  Выгрузить файлы на github

  - bash upload_to_git_vm1.sh


  ## Сервер №2 / Виртуальная машина №2

  Создайте папки и дайте им необходимые права

  - mkdir /home/berd/scripts

  - chmod 777 /home/berd/scripts

  В папку /home/berd/scripts скопировать скрипты

  - bash install_mysql_replica.sh
  - bash mysql_replica_backup.sh
  - bash install_elk.sh
  - bash install_git_vm2.sh
  - bash upload_to_git_vm2.sh

  - mkdir /home/berd/elk

  В папку /home/berd/elk скопировать файлы

  - elasticsearch_8.17.1_amd64-224190-db972d.deb
  - filebeat_8.17.1_amd64-224190-a5f894.deb
  - kibana_8.17.1_amd64-224190-42bf22.deb
  - logstash_8.17.1_amd64-224190-40c12c.deb

  - chmod 777 /home/berd/elk

  Установить  MySQL replica

  - bash install_mysql_replica.sh

  Проверить репликацию командами

  - mysql

  - show replica status\G;

  - show databases;

  Выполнить бекап базы данных

  - bash mysql_replica_backup.sh

  Проверить наличие файлов в папке /home/berd/scripts/mysql_backup

  Установить ELK Stack

  - bash install_elk.sh

  Проверить работу ELK Stack на http://10.17.86.141:5601/

  Установить GIT

  - bash install_git_vm2.sh

  Скопировать SSH-ключ в аккаунт github.com https://github.com/AlexIridium/

  Выполнить команду git clone * указать здесь код из гитахаба *

  Выгрузить файлы на github

  - bash upload_to_git_vm2.sh

  

  

  

  

  

  

  

  

  

  

  

  

  

  

  

  

  

  




