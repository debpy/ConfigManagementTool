#!/bin/bash
usage() {                                 # Function: Print a help message.
  echo "Usage: $0 [ <target_host> ]  [ -f filepath ] [ -c content in quotes ] [ -u user ] [ -g group ] [ -m mode ] [ -i package names in quotes ] [ -r packag names inside quotes ]" 1>&2 
}
exit_abnormal() {                         # Function: Exit with error.
  usage
  exit 1
}

copy_Scripts(){
   ssh-keygen -t rsa -b 4096
   ssh-copy-id root@$ip
   echo "$ip" >> "$FILE"
   scp -r /root/Slack/* root@$ip:
##Install the prerequisite apache & php  packages
   ssh root@$ip "bash bootstrap.sh"
    }

do_login(){
	for ip in "$@";do
    	    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];then
                echo "IP address: $ip"
            fi
        done
	FILE="/root/Slack/hosts"
	if [[ -f  "$FILE" ]];then
	    grep "$ip" "$FILE"
	    if  [[ $? -ne 0 ]]; then
                copy_Scripts
	    fi
	else
	   copy_Scripts	
	fi
}

install_Package(){
       packages=$1
       for pkg in $packages; do
	   echo "Package $pkg"
           ssh root@$ip "dpkg -s $pkg > /dev/null 2>&1"
           if [ $? -ne 0 ]; then
               echo "Installing $pkg..."
	       ssh root@$ip "apt install $pkg"
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
           ssh root@$ip "apt remove $pkg"
       else
           echo "Package $pkg is not present"
       fi
    done   
}


#Entry point of the program
function main(){

#Check whether command line args passed to the script
if [[ ${#} -eq 0 ]]; then
   usage
fi

#Login to remote server
do_login

DIRECTORY="/var/www/html/"
#
#Parse the options and the corresponding args
while getopts ":f:c:m:u:g:i:r:t:" options; do         
  case "${options}" in      
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
	     ssh root@$ip "chown ${user} ${file_name}"
      ;;
     g)
	     group=${OPTARG}
	     ssh root@$ip "chown :${group} ${file_name}"
      ;;

     i)
	     packages=${OPTARG}
	     install_Package "$packages"
      ;;

     r)
	     packages="${OPTARG}"
	     remove_Package "${packages}"
      ;; 

    :)                                 
      	     echo "Error: -${OPTARG} requires an argument."
             exit_abnormal                   
      ;;
    ?)
	     echo "Error: -Unknown option ${OPTARG}"
	     exit_abnormal
      ;;
  esac
done
}

main
