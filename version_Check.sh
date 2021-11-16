#!/bin/bash
# Check last and existing Apache, PHP versions. If any changes observed restart Apache
current_php_version=$(php -v| grep -i "^PHP"| awk '{print $2}'| awk -F '-' '{print $1}')
current_apache_version=$(apache2 -version| grep -i version| awk -F '/' '{print $2}' | awk '{print $1}')
php_version=$(cat php_version)
apache_version=$(cat apache_version)
echo "PHP Version: $php_version"
echo "Current PHP Version: $current_php_version"

echo "Apache Version: $apache_version"
echo "Current Apache Version: $current_apache_version"

if [[ "$current_php_version" != "$php_version" ]] || [[ $current_apache_version !=  $apache_version ]];then
	echo "Gracefuly Restarting Apache..."
        apache2ctl restart
else
        echo "No change in Apache & PHP  versions"
fi

