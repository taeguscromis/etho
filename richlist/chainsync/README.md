##1. Compilation

To compile you need to first install FPC. To do this on Ubuntu, the simplest way is to download the DEB package and install it.
the package is available here: https://sourceforge.net/projects/lazarus/files/Lazarus%20Linux%20amd64%20DEB/Lazarus%201.8.4/fpc_3.0.4-3_amd64.deb/download

Then go to the "chainsync" directory and simply do: **fpc -B -Fu"libs/synapse" EtherSync.lpr**
You should get and "EtherSync" executable. Thats it.

##2. Installation

Just rename the settings.ini.sample to settings.ini and put it in the same directory as the executable.
The executable needs write permissions in that directory. It will be best if you run it as a service.
Set the settings in the ini file accordingly.

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



