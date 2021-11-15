#!/bin/bash
packages=( inotify-tools php libapache2-mod-php )
CRON_FILE="/var/spool/cron/crontabs/root"
CHECK_CONFIGURATION="/root/config_Check.sh"

configure_Apache(){
	cp test.php /var/www/html/
	echo "DirectoryIndex test.php" >> /var/www/html/.htaccess
	sed  -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
	echo "ServerName localhost" >>  /etc/apache2/apache2.conf
}

for package in "${packages[@]}"
do
  dpkg -s "$package" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
  	echo "Installing $package..."
	apt install -y "$package"
	if [[ "$package" == "libapache2-mod-php" ]];then
		#Get the Apache version
		export apache_version=$(apache2 -version| grep -i version| awk -F '/' '{print $2}' | awk '{print $1}')
		#Configuring Apache
		configure_Apache
		echo "Restarting Apache service..."
		systemctl restart apache2

	elif [[ "$package" == "php" ]]; then
		#Get the PHP version
		export php_version=$(php -v| grep -i "^PHP"| awk '{print $2}'| awk -F '-' '{print $1}')
	fi	
  else
	echo "Package $package is already installed"
  fi
done

if [ ! -f $CRON_FILE ]; then
    echo "cron file for root doesnot exist, creating.."
    touch $CRON_FILE
    /usr/bin/crontab $CRON_FILE
fi

# Set a cron entry for config_Check.sh
grep -qi "$CHECK_CONFIGURATION" $CRON_FILE
	if [ $? != 0 ]; then
	   echo "Updating cron job"
           /bin/echo "* * * * * /bin/bash $CHECK_CONFIGURATION >/root/configure.log 2>&1" >> $CRON_FILE
	   systemctl restart cron.service
	fi

#nohup config_Check.sh > /dev/null
