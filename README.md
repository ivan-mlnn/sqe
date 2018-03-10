# Установка
## База данных
У меня работает в postgres, теоретически можно допилить и на другие.
в качестве суррогата ORM используется [sequel](http://sequel.jeremyevans.net/) .

 - Создаем базу и пользователя
 > create user sqe encrypted password 'sqe'; 

> create database sqe owner  sqe encoding 'UTF8';
 - Подключаемся к созданной базе и импортируем дамп 
> psql sqe -d localhost -U sqe -W < sqe.sql
 - И  создаем админа движка
 > insert into users(login,password,admin) values('admin','adminpass',true);
