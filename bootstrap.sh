#!/bin/bash
#packages=( inotify-tools php libapache2-mod-php apache2)
CRON_FILE="/var/spool/cron/crontabs/root"
packages=( inotify-tools php libapache2-mod-php)
CHECK_CONFIGURATION="/root/config_Check.sh"
APACHE_CONFIG="/etc/apache2/apache2.conf"
HTACCESS="/var/www/html/.htaccess"
APACHE_CONFIG_COMMAND=$(sed  -n '/<Directory \/var\/www\/>/,/<\/Directory>/p' /etc/apache2/apache2.conf | grep AllowOverride| grep -i None)
#HTACCESS_COMMAND=$(cat /var/www/html/.htaccess | grep "DirectoryIndex" | grep -v ".php")
configure_Apache_Config(){
	sed  -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' "$APACHE_CONFIG"
	echo "ServerName localhost" >>  "$APACHE_CONFIG"
}

configure_HTACCESS(){
	echo "DirectoryIndex test.php" >> "$HTACCESS"
}

for package in "${packages[@]}"
do
  dpkg -s "$package" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
  	echo "Installing $package..."
	apt install -y "$package"

	if [[ "$package" == "libapache2-mod-php" ]] ;then	
		
		#Set the Apache version as env variable
		apache_version=$(apache2 -version| grep -i version| awk -F '/' '{print $2}' | awk '{print $1}')
		echo "$apache_version" > apache_version
	elif [[ "$package" == "php" ]]; then

                #Set the PHP version as env variable
                php_version=$(php -v| grep -i "^PHP"| awk '{print $2}'| awk -F '-' '{print $1}')
                echo "$php_version" > php_version
	else
               echo "Package $package is already installed..."
        fi
   fi
done

		#Configure Apache if apache2.conf and .htaccess is absent
		if [ ! -f $APACHE_CONFIG ];then
		   echo "Configuring Apache..."
	           configure_Apache_Config
		fi
		if [ ! -f $HTACCESS ]; then
		    echo "Configure HTACCESS..."
	            configure_HTACCESS
		fi
		if [ -f $APACHE_CONFIG ];then
		   if [[ $APACHE_CONFIG_COMMAND ]]; then
                   	echo "Configuring Apache..."
			configure_Apache_Config
                   	
		   fi
		fi
		if [ -f $HTACCESS ]; then
		   echo "HTACCESS file path: $HTACCESS"
		   cat /var/www/html/.htaccess | grep "DirectoryIndex" | grep -v ".php"
		   if [[ $? -ne 0 ]]; then
		       echo "Configure HTACCESS..."
                       configure_HTACCESS
		   fi
		fi

		echo "Restarting Apache service..."
		systemctl restart apache2


#	elif [[ "$package" == "php" ]]; then
#		
#		#Set the PHP version as env variable
#		php_version=$(php -v| grep -i "^PHP"| awk '{print $2}'| awk -F '-' '{print $1}')
#		echo "$php_version" > php_version
#
#	fi	
#  else
#	echo "Package $package is already installed..."
#  fi
#done

#if [ ! -f $CRON_FILE ]; then
#    echo "cron file for root doesnot exist, creating.."
#    touch $CRON_FILE
#    /usr/bin/crontab $CRON_FILE
#fi

#Invoke version_Check.sh
echo "Calling version_Check.sh..."
./version_Check.sh


#Invoke config_Check.sh
echo "Calling config_Check.sh..."
#nohup bash config_Check.sh  </dev/null >/dev/null 2>&1  &
nohup bash config_Check.sh > /root/configure.log  2>&1 &


#nohup ./config_Check.sh > config.log  &


#if [ ! -f $CRON_FILE ]; then
#    echo "cron file for root doesnot exist, creating.."
#    touch $CRON_FILE
#    /usr/bin/crontab $CRON_FILE
#fi
#
### Set a cron entry for config_Check.sh
#pattern=$(grep -v "^#" $CRON_FILE| grep -qi "$CHECK_CONFIGURATION")
#if [[ $? -eq 1 ]]; then
#    echo "Updating cron entry with the script config_Check.sh..."
#    /bin/echo "1 * * * * /bin/bash $CHECK_CONFIGURATION >/root/configure.log 2>&1" >> $CRON_FILE
#    systemctl restart cron.service
#fi
#
#nohup config_Check.sh > /dev/null
