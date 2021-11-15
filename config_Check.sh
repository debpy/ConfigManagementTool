# Check last and existing Apache, PHP versions. If any changes observed restart Apache
current_php_version=$(php -v| grep -i "^PHP"| awk '{print $2}'| awk -F '-' '{print $1}')
current_apache_version=$(apache2 -version| grep -i version| awk -F '/' '{print $2}' | awk '{print $1}')
php_version='1'
apache_version='2'
echo "PHP Version: $php_version"
echo "Current PHP Version: $current_php_version"

echo "Apache Version: $apache_version"
echo "Current Apache Version: $current_apache_version"

if [[ -n "$php_version" && "$current_php_version" != "$php_version" ]] || [[ -n "$apache_version" && $current_apache_version !=  $apache_version ]];then
	echo "Gracefuly Restarting Apache..."
	apache2ctl restart
else
	echo "No change in Apache & PHP  versions"
fi

#Check any modifications made on the Apache config directory & restart Apache service accordingly
MONITORDIR="/etc/apache2"
inotifywait -q -m -r -e modify --format '%w%f' "${MONITORDIR}" | while read NEWFILE
do
        echo "$NEWFILE is modified"
	echo "Restarting Apache"
	systemctl restart apache2
done
