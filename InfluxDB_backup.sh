#!/usr/bin/env bash
#Author Hubert Witkowski github.com/huczas twitter: @huczas
#This script is for full backup InfluxDB and send tarred archive to NAS disc. 
#For recovery database first untar last archive and
#restore all databases found within the backup directory:
#influxd restore -portable path-to-backup
#
#SETUP MAIL only if your system is capable to sending mails.
MAIL='mail@gmail.com'
BDIR=/home/pi/InfluxDB_backup                 #Temporary backup directory
MDIR=/home/pi/backup_drive                    #Mounting point directory
BFILE=InfluxDB_backup_$(date +%Y%m%d_%H%M%S)  #Name your backup file with date
DAYS=10                                       #How many days backup files should be keept

echo -e "Starting InfluxDB backup process!"
echo -e "Unmounting NAS drive" 
sudo umount ${MDIR} | echo -n "\e[OK]"
echo -e "Mounting NAS drive"
sudo mount ${MDIR} | echo -n "\e[OK]"
# Check if backup directory exists
if [ ! -d "$BDIR" ];
    then
        echo -e "Backup directory $BDIR doesn't exist, creating it now!"
        mkdir $BDIR
        echo -n "\e[OK]"
fi
# Begin the backup process
echo -e "Backing up InfluxDB to $BDIR."
echo -e "This will take some time depending on your disc performance. Please wait..."
influxd backup -portable $BDIR > /dev/null
# Wait for backup process to finish and catch result
RESULT=$?
# If command has completed successfully, delete previous backups and exit
if [ $RESULT = 0 ];
    then
        echo -e "Delete old local backup file"
        sudo rm -f ~/InfluxDB_backup_*.tar.gz
        ls $MDIR -tp |grep -v / | sed -e '1,${DAYS}d' | xargs -d '\n' rm
        echo -n "\e[OK]"
        echo -e "Backup is being tarred. Please wait..."
        tar zcfP ~/$BFILE.tar.gz $BDIR
        echo -e "Moving backup to NAS"
        sudo rsync -a ~/$BFILE.tar.gz $MDIR/
        echo -n "\e[OK]"
        echo -e "Tarred files being deleted..."
        rm -rf $BDIR/$(date +%Y%m%d)*
        echo -n "\e[OK]"
        echo -e "InfluxDB backup process completed! FILE: ${BFILE}.tar.gz"#| mail -s "InfluxDB backup successful" ${MAIL}
        echo -e "Unmounting NAS drive" 
        sudo umount ${MDIR} | echo -n "[OK]"
        exit 0
# Else remove attempted backup file
    else
        echo -e "Backup failed! Previous backup files untouched."
        echo -e "Please check there is sufficient space on the HDD."
        echo -e "Tarred files being deleted..."
        rm -rf $BDIR
        echo -n "\e[OK]"
        echo -e "InfluxDB backup process failed!"| mail -s "InfluxDB backup failed!" ${MAIL}
        echo -e "Unmounting NAS drive" 
        sudo umount ${MDIR} | echo -e "\e[OK]"
        exit 1
fi
