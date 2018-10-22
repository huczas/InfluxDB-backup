# InfluxDB-backup
My simple script used for backup all InfluxDB databases, tarr it and send to mounted NAS. There is a lot comments, all should be clear. 
Script assumes that sending emails are properly configured on system level, same with mounting part in fstab.
For the recort, my /etc/fstab looks like that:

`//192.168.1.2/RaspberryPi /home/pi/backup_drive cifs auto,password= 0 0`