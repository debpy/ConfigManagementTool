#!/bin/bash
WORKDIR="/root/Slack"
scripts=("bootstrap.sh" "config_Check.sh" "configure.sh" "version_Check.sh")
usage() {                                 # Function: Print a help message.
  echo "Usage: $0 [ -t target_host ]  [ -f filepath ] [ -c content in quotes ] [ -u user ] [ -g group ] [ -m mode ] [ -i package names in quotes ] [ -r packag names inside quotes ] [ -p PHPApp ]" 1>&2 
}

exit_abnormal() {                         # Function: Exit with error.
  usage
  exit 1
}

sync_Remote_Script(){
	for script in "${scripts[@]}"; do
		scp $WORKDIR/$script root@$ip:
	done
}

copy_Scripts(){
   ssh-keygen -t rsa -b 4096
   ssh-copy-id root@$ip
   scp -r /root/Slack/*.sh root@$ip:
   ssh root@$ip "./bootstrap.sh"
   echo "$ip" >> /root/Slack/hosts 
    }


install_Package(){
       packages=$1
       for pkg in $packages; do
           ssh root@$ip "dpkg -s $pkg > /dev/null 2>&1"
           if [ $? -ne 0 ]; then
               echo "Installing $pkg..."
	       ssh root@$ip "apt install -y $pkg"
           else
               echo "Package $pkg already installed"
           fi
       done
}

remove_Package(){
    packages=$1
    for pkg in $packages; do
       ssh root@$ip "dpkg -s $pkg > /dev/null 2>&1"
       if [ $? -eq 0 ]; then
           echo "Removing $pkg..."
           ssh root@$ip "apt remove -y $pkg"
       else
           echo "Package $pkg is not present"
       fi
    done   
}

##Check whether command line args passed to the script
#if [ "$#" -eq 0 ]; then
#   echo "Please mention the necessary options or args"
#   exit_abnormal
#fi
#
##Parse IP address
#echo "Print all command line args: $@"
#for ipAddr in "$@";do
#    if [[ $ipAddr =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];then
#	export ip=$ipAddr
#        echo "IP address: $ip"
#    fi
#done

function remote_Access(){

    FILE="/root/Slack/hosts"
    if [[ -f  "$FILE" ]];then
        echo "Matching $ip in the file $FILE"
        grep "$ip" "$FILE"
        if  [[ $? -ne 0 ]]; then
            echo "No entry of the Host with $ip in the hosts file"
            echo "Invoking the copy_Scripts function..."
            copy_Scripts
	else
	    echo "Host present in $FILE"
	    echo "Syncing the remote $ip with local scripts..."
	    sync_Remote_Script
	    #cd $WORKDIR && rsync -aPvzhe ssh  --include '*.sh' --exclude '*' root@$ip:
            #cd $WORKDIR && scp "*.sh" root@$ip:
	    echo "Invoking ./bootstrap.sh..."
	    ssh root@$ip "./bootstrap.sh"
        fi
    else
        echo "hosts file NOT yet created"
        echo "Invoking the copy_Scripts function..."
	copy_Scripts
    fi
}

#Parse the options and the corresponding args
echo "Parse the options and the corresponding args"

while getopts ":t:f:c:m:u:g:i:r:p:" options; do         
  case "${options}" in 
     t)	    export ip=${OPTARG}
      ;;
     f)                                   
	    file_name=${OPTARG}
	    ssh root@$ip "touch ${file_name}"	    
      ;;
     c)                                 
            content=${OPTARG}
	    if [ -n ${file_name} ]; then
	        ssh root@$ip "echo ${content} > ${file_name}" 
	    else
		echo "Specify -f <file_name>"
	    fi
      ;;
     m)
	     mode=${OPTARG}
	     if [ -n ${file_name} ]; then
	         ssh root@$ip "chmod ${mode} ${file_name}"
             else
		 echo "Specify -f <file_name>"
	     fi
      ;;
     u)
	     user=${OPTARG}
	     ssh root@$ip "getent passwd $user"
	     if [ $? -ne 0 ];then
		echo "User $user doesn't exist"
	     else
	     	ssh root@$ip "chown ${user} ${file_name}"
	     fi
      ;;
     g)
	     group=${OPTARG}
	     ssh root@$ip "getent group $group"
	     if [ $? -ne 0 ];then
                echo "Group $group doesn't exist"
             else
	     	ssh root@$ip "chown :${group} ${file_name}"
	     fi
      ;;

     i)
	     packages=${OPTARG}
	     install_Package "$packages"
      ;;

     r)
	     packages="${OPTARG}"
	     remove_Package "${packages}"
      ;;
     p)
	    php_file="${OPTARG}"
	    remote_Access
	    scp "$php_file" root@$ip:/var/www/html/  
      ;;
    :)                                 
      	     echo "Error: -${OPTARG} requires an argument."
             exit_abnormal                   
      ;;
    ?)
	     echo "Error: -Unknown option ${OPTARG}"
	     exit_abnormal
      ;;
    *)	     exit_abnormal
      ;;
  esac
done

#echo "Calling config_Check.sh..."
#nohup ./config_Check.sh > config.log &
