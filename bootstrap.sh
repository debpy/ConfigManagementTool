#!/bin/bash
packages=( inotify-tools apache2 php libapache2-mod-php )
CRON_FILE="/var/spool/cron/crontabs/root"
CHECK_CONFIGURATION="/root/config_Check.sh"
APACHE_CONFIG="/etc/apache2/apache2.conf"
HTACCESS="/var/www/html/.htaccess"
DOCROOT="/var/www/html/"

configure_Apache(){
	cp test.php "$DOCROOT"
	echo "DirectoryIndex test.php" >> "$HTACCESS"
	sed  -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' "$APACHE_CONFIG"
	echo "ServerName localhost" >>  "$APACHE_CONFIG"
	echo "Restarting Apache service..."
        systemctl restart apache2
}

for package in "${packages[@]}"
do
  dpkg -s "$package" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
  	echo "Installing $package..."
	apt install -y "$package"

	if [[ "$package" == "libapache2-mod-php" ]] ||  [[ "$package" == "apache2" ]];then	
		#Set the Apache version as env variable
		export apache_version=$(apache2 -version| grep -i version| awk -F '/' '{print $2}' | awk '{print $1}')
		#Configure Apache if apache2.conf and .htaccess is absent
		if [ ! -f $APACHE_CONFIG ] && [ ! -f $HTACCESS ];then
		   echo "Configuring Apache..."
	           configure_Apache
		else
		   echo "Restarting Apache service..."
		   systemctl restart apache2
		fi
	elif [[ "$package" == "php" ]]; then
		#Set the PHP version as env variable
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
	   echo "Updating cron job..."
           /bin/echo "* * * * * /bin/bash $CHECK_CONFIGURATION >/root/configure.log 2>&1" >> $CRON_FILE
	   systemctl restart cron.service
	fi

#nohup config_Check.sh > /dev/null
