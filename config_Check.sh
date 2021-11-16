#Check any modifications made on the Apache config directory & restart Apache service accordingly
MONITORDIR="/etc/apache2"
echo "Monitoring Apache config dir $MONITORDIR"
inotifywait  -m -r -e modify --format '%w%f' "${MONITORDIR}" | while read NEWFILE
do
        echo "$NEWFILE is modified"
	echo "Testing Apache config"
	apachectl configtest
	echo "Restarting Apache"
	systemctl restart apache2
	if [ $? -ne 0 ];then
	       echo "Failed to restart, Fixing it..."
       	       systemctl reset-failed apache2.service	       
	       systemctl restart apache2
	fi
done
