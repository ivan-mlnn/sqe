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

в файле sqe/www/model/db.rb меняем [параметры подключения к БД](https://github.com/ivan-mlnn/sqe/blob/a9e812f01db14da55048522a2a505b4a42af8e27/www/model/db.rb#L7)

## Ruby и gem'ы
> apt-get install ruby
> gem install sinatra sinatra-contrib thin unicode_utils oj faraday json sequel pg telegram-bot-ruby xxhash

## Запуск
> thin start

Также к движку прилагается бот телеграмм нужно свой токен прописать в файлах
> sqe/www/tool/bot.rb
> sqe/www/model/db.rb

и поменять ссылку в файле
> sqe/www/lib/views/profile.erb 

и добавить в переодический запуск(например по крону раз в минуту)
> sqe/www/tool/ticker.rb
