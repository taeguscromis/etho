## 1. Installation

To run the web front you need apache with php and mysql modules installed. I won't go into installation process here.
Simply copy the content of webfront to **/var/www/html** into the folder of your choice and setup apache accordingly.

Then copy the **conf/settings.ini.sample** to **/var/www/conf/richlist/settings.ini**
Then set the settings to your environment.

```
[database]
servername=localhost
username=mysqlusername
password=mysqlpassword
dbname=thenameofthedb

```

After that the richlist page should be accessible