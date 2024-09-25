#!/bin/bash

#This is an if function to check if the current user using this is root, which is ID 0, if it is, it'll go on as usual, if it isn't, it'll force exit
#the script using exit as it's breaking point in the if function
if [ "$EUID" -ne 0 ]
	then 		
		echo "================================================================================="
		echo "Please make sure you're running this script in sudo, ex 'sudo bash <script.sh>'"
		echo "================================================================================="
	exit
fi

echo "================================================================================="
echo "------------------------------------------------------------------"
echo "IMPORTANT NOTICE"
echo "Please only use this on IP addresses you have full authority to nmap."
echo "If not you might be facing legal charges"
echo "------------------------------------------------------------------"
echo "================================================================================="

function ip()
{
	#This is an integer to launch an infinite while loop on the occurence that it's not expected
	valid=0
	read -p "Please enter an IP address that you'd like to use : " ipadd
	#Checks if IP has 4 octets, and makes sure each octet is lesser than 256
	if [[ $ipadd =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]
	then
		valid=1
	else
	#While loop to rerun the same read as long as it's not within expected range
		while [ $valid -eq 0 ]
			do
				read -p "Not a valid IP, please re-enter : " ipadd
				if [[ $ipadd =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]
					then
						valid=1
				fi
			done
	fi
	echo "----------------------------------------------------------------------------------"
}

function oname()
{
	#Just a simple function to store the directory's name into dname
	read -p "Please enter a name for the output directory : " dname
	echo "Output directory's name has been set as $dname"
	echo "----------------------------------------------------------------------------------"
}

function BorF()
{
	#Selection variable for further function to figure if it's Basic/Full
	Selection=0
	#Checks if the input is indeed 1,2 or 3. If it doesn't sends you into an abyss of re-entering
	read -p "Please enter 1(Basic), 2(Full) or 3(Info) to choose your scan type : " BFC
	re='^[1-3]+$'
	while ! [[ $BFC =~ $re ]]
			do
				read -p "Not a valid choice, please re-enter : " BFC
			done
	#Seperates the different codes given for each code. 
	if [ $BFC == "1" ]
	then
		echo "You have slected basic scan"
		Selection=1
	elif [ $BFC == "2" ]
	then
		echo "You have selected Full scan"
		Selection=2
	else
		echo "----------------------------------------------------------------------------------"
		echo "Basic"
		echo "TCP scan"
		echo "UDP scan"
		echo "Service versions of ports"
		echo "Weak password scans"
		echo "----------------------------------------------------------------------------------"
		echo "Full"
		echo "TCP scan"
		echo "UDP scan"
		echo "Service versions of ports"
		echo "Weak password scans"
		echo "Vulnerability analysis"
		echo "----------------------------------------------------------------------------------"
		#Recalls it's own function to replay the entire thing again
		BorF
	fi
}
function portscanning(){	
	#This pulls the variable out of the ip function and uses it for nmap scans
	echo "[#]Nmap scan is occuring now, this might take awhile"
	nmap -sV -p- $ipadd > "nmapscan"
	echo "[!]Nmap scan has completed"
	#Asks if user wants to print the results or move on
	read -p "Would you like to see the results? 1(Yes) if not enter anything : " Choice
	echo "----------------------------------------------------------------------------------"
	if [ $Choice == 1 ]
	then
		cat "nmapscan"
	fi
	echo "================================================================================="
	echo "----------------------------------------------------------------------------------"
	echo "================================================================================="
	echo "[#]UDP scan is occuring now, this might take awhile"
	masscan -pU:1-65535 --rate=10000 $ipadd > "masscan"
	echo "----------------------------------------------------------------------------------"
	echo "[!]UDP scan has completed"
	#Asks if user wants to print the results or move on
	read -p "Would you like to see the results? 1(Yes) if not enter anything : " Choice
	echo "----------------------------------------------------------------------------------"
	if [ $Choice == 1 ]
	then
		cat "masscan"
	fi
	echo "----------------------------------------------------------------------------------"
}

function users(){
	#Function to create basic list
	echo "admin" > user.lst
	echo "msfadmin" >> user.lst
	echo "user" >> user.lst
	echo "kali" >> user.lst
}

function pwlist(){
	#Checks if there's the required defualt pw list, if not download it
	exist=$(ls | grep best110.txt | wc -l)
	if [ $exist == 0 ]
	then
		echo "[#]Retreiving default pw list this program requires"
		echo "----------------------------------------------------------------------------------"
		wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-500.txt -O best110.txt
		echo "----------------------------------------------------------------------------------"
	fi
}

function servicecheck(){
	#Creates an empty array for me to input what service is present to run it through a for loop
	svcs=()
	sshexist=$(cat nmapscan | grep -i "ssh" | wc -l)
	rdpexist=$(cat nmapscan | grep -i "rdp" | wc -l)
	ftpexist=$(cat nmapscan | grep -i "ftp" | wc -l)
	telnetexist=$(cat nmapscan | grep -i "telnet" | wc -l)
	if [[ sshexist -gt 0 ]]
	then
		svcs+=('ssh')
	fi
	if [[ rdpexist -gt 0 ]]
	then
		svcs+=('rdp')
	fi
	if [[ ftpexist -gt 0 ]]
	then
		svcs+=('ftp')
	fi
	if [[ telnetexist -gt 0 ]]
	then
		svcs+=('telnet')
	fi
	#Checks if there's anything even in the array, if there isn't. Well, there's nothing to check. 
	if [ ${#svcs[@]} -eq 0 ]
	then
		echo "There is no login service available on this machine"
	else
		brute
	fi
}

#Function to run the hydra on all users in the default userlist
function brute(){
	#This is to ask user if they'd like to use their own password list
	read -p "Would you like to use your own password list? 1(Yes) if not type anything else : " Choice
	echo "$Choice"
	if [ $Choice == 1 ]
	then
		#Tells user where to input in their own file, and rename it properly. Can be done mid script. 
		whereAmI=$(pwd)
		read -p "If so, please put in any .txt file and rename it specifically ownlist.txt into $whereAmI, once ready enter any button : " nothing
		for i in ${svcs[@]}
		do
			echo "I am now running hydra for $i service"
			echo "---------------------------------------------"
			hydra -L user.lst -P ownlist.txt $ipadd $i -o hydralist.txt
			echo "----------------------------------------------------------------------------------"
		done
	else
	#This is a for loop to run through everything that's in the array
		for i in ${svcs[@]}
		do
			echo "I am now running hydra for $i service"
			echo "---------------------------------------------"
			hydra -L user.lst -P best110.txt $ipadd $i -o hydralist.txt
			echo "----------------------------------------------------------------------------------"
		done
		read -p "Hydra execution has been run on any login services available on client, please press enter to start finding exploits"
	fi
}

#Function to search for all exploits found on the database
function sersploit(){
	#this cats the nmapscan, and removes everything except the version and services by cutting 29 characters infront
	cat nmapscan | grep open | cut -c 29- | sed '/^$/d' > services.txt
	services=services.txt
	echo "----------------------------------------------------------------------------------"
	echo "Searching for exploits for services on open port of targeted machine"
	echo "----------------------------------------------------------------------------------"
	sleep 5
	#Reads the file and prints it line by line
	while read -r LINE
	do
		#Tells the machine if there's 3 No Results line showing for said service, if 3 shows, it means there's absolutely no results. 
		exploitexist=$(searchsploit $LINE | wc -l)
		if [ $exploitexist != "3" ]
		then
			searchsploit $LINE
			#Saves the data into a txt to view later
			searchsploit $LINE >> searchsploit.txt
		fi
	done < "$services"
}

function Basic(){
	#Calls the function to create file and cd into it to save the outputs of all the different scans
	oname
	Directoryexists=$(ls | grep -w "$dname" | wc -l)
	if [ $Directoryexists == 1 ]
	then
		echo "Directory already exists, entering said directory"
		echo "----------------------------------------------------------------------------------"
	else
		mkdir $dname
	fi
	cd $dname
	pwd
	echo "----------------------------------------------------------------------------------"
	users
	pwlist
	ip
	portscanning
	servicecheck
}

function main(){
	BorF
	#Pulls out the selection from BorF to check whether Basic or Full was selected
	if [ $Selection == "1" ]
	then
		Basic
	else
	#Full has an extra Sersploit function
		Basic
		sersploit
	fi
	rm user.lst
	rm best110.txt
	echo "================================================================================="
	echo "Thank you for using this software, I hope you did nothing illegal"
	whereamI=$(pwd)
	echo "All logs have been saved into $whereamI"
	echo "================================================================================="
}
main
