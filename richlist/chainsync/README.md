## 1. Compilation

To compile you need to first install FPC. To do this on Ubuntu, the simplest way is to download the DEB package and install it.
the package is available [here](https://sourceforge.net/projects/lazarus/files/Lazarus%20Linux%20amd64%20DEB/Lazarus%201.8.4/fpc_3.0.4-3_amd64.deb/download).

You will also need to install mysql client lib: **sudo apt install libmysqlclient-dev**

Then go to the "chainsync" directory and simply do: **fpc -B -Fu"libs/synapse" EtherSync.lpr**
You should get and "EtherSync" executable. Thats it.

## 2. Installation

Just rename the settings.ini.sample to settings.ini and put it in the same directory as the executable.
The executable needs write permissions in that directory. It will be best if you run it as a service.
Set the settings in the ini file accordingly.

You can now also put the settings.ini file somwhere else and star the executable with "-iniFile %path_to_the_file%"

If you need the notification to Discord feature for specific addresses just check out the notify.xml.sample file (it should be self explaining). Rename it to notify.xml and set it witgh the needed addresses you would like to monitor. That is all.

```
[blockchain]
lastblock=Should be set to 1, to start at the chain beggining

[database]
ConnectorType=Set it to the mysql version you have installed 
HostName=should be localhost as the DB is probably on the same machine
DatabaseName=then name of the mysql database
UserName=mysql username
Password=mysql password

[rpc]
url=the URL of the geth rpc server
```

To run as a service use **systemctl**

```
[Unit]
Description=EtherSync

[Service]
Type=simple
# Another Type option: forking
User=ethersync
WorkingDirectory=/usr/bin
ExecStart=/usr/bin/EtherSync
Restart=on-failure
# Other Restart options: or always, on-abort, etc

[Install]
WantedBy=multi-user.target

```

Copy **EtherSync.service.sample** to **/etc/systemd/system/EtherSync.service** and edit it approprietly.

Now you can start it or stop it with:

- **start**: sudo systemctl start EtherSync
- **stop**: sudo systemctl stop EtherSync
- **print log**: journalctl -e -u EtherSync.service
- **reload conf**: systemctl daemon-reload

Not that if you run your own geth RPC you have to have it running and fully synced
