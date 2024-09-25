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

#This is to write an array to run it through a loop to make it more optimized and lesser lines
softwares=(geoip tor sshpass)

#This function is to check for the existence of the Nipe folder, if it's istalled, it'll mention it's installed, if it doesn't. It'll install it on its own
function installnipe()
{
	nipeinstalled=$(ls | grep -i "nipe" | wc -l)
	if [ $nipeinstalled == 1 ]
	then
		echo "[#] Nipe is already installed"
		#cd into the installed nipe folder you already have
		cd nipe
		echo "================================================================================="
	else
		echo "[X] Nipe is not installed, installing Nipe"
		#Downloads the nipe folder and changes your directory into it
		git clone https://github.com/htrgouvea/nipe && cd nipe
		#Install relevant codes/applications required to run Nipe
		cpanm --installdeps -y
		cpan install Switch JSON LWP::UserAgent Config::Simple
		sudo perl nipe.pl install
		echo "================================================================================="
	fi
	whoisdirectory=$(ls | grep whoisdirectory | wc -l)
	if [ $whoisdirectory == 0 ]
	then
		mkdir whoisdirectory
	fi
}

function runnipe()
{
	perl nipe.pl start
	#To check if an error occured when starting nipe
	error=$(perl nipe.pl status | grep ERROR | wc -l)
	#To check whether Nipe is activated or not
	status=$(perl nipe.pl status | grep false | wc -l)
	#To grep for the IP of Nipe, sed is to remove the front empty space
	nipeip=$(perl nipe.pl status | grep Ip | awk -F: '{print $2}' | sed 's/\s/''/')
	if [ $error == 1 ] 
	then
		#This is to restart the service, since error happens sometimes and to recursively run the function again to check
		perl nipe.pl restart
		runnipe
	else
		if [ $status == 1 ]
		then
			echo "You're not currently annonymous, ending script"
			exit
		else
			echo "[*]You're currently anonymous..."
			#grepping the country given and only the last word to input into a clean line.
			country=$(geoiplookup "$nipeip" | awk -F, '{print $2}')
			echo "[*]Your spoofed IP is : $nipeip, and your spoofed country : $country"
			echo "================================================================================="
		fi
	fi
}

function download()
{
	#CD into whoisdirectory that was created using a function above so that we can get the file to this location
	cd whoisdirectory
	HOST="192.168.2.129"
	USER="tc"
	PW="tc"
	ftp -inv $HOST <<EOF
	user $USER $PW
	get Who$victim
	bye
EOF
	echo "================================================================================="
	currentDirectory=$(pwd)
	#Tells the user where it's saved in
	echo "[@]Whois of $victim has been saved in $currentDirectory/Who$victim"
	#Go back to the preivous file we were from
	cd ..
}

#The function to login to the ssh and use sshpass to run the uptime, and whois command
function remotecommand()
{
	echo "[*]Connecting to Remote Server :"
	#Give it an affect that it's loading the connection
	sleep 3
	#This is to make the server run an uptime on their end and places it into a variable to echo
	#Please change all -p password, and the user@server for all to get it working for you
	uptime=$(sshpass -p tc ssh -o StrictHostKeyChecking=no tc@192.168.2.129 'uptime')
	echo "Uptime : $uptime"
	#I'm using curl and whois to get the servers ip, then using that ip on my own computer to get the country
	rmtip=$(sshpass -p tc ssh -o StrictHostKeyChecking=no tc@192.168.2.129 'curl ifconfig.io -s')
	rmtcountry=$(geoiplookup "$rmtip" | awk -F, '{print $2}' )
	echo "IP Address : $rmtip"
	echo "Country : $rmtcountry"
	echo "================================================================================="
	#I'm going to ask the user which ip/domain would they like to whois
	echo "[*]Please enter the IP/domain of the server you'd like to whois on"
	read victim
	echo "[*]Whoising $victim"
	sleep 3
	sshpass -p tc ssh -o StrictHostKeyChecking=no tc@192.168.2.129 "whois $victim > Who$victim"
	echo "================================================================================="
	download
	#After making the Remote server do your whois, delete the evidence
	echo "[*]Deleting the whois file on the remote server"
	sleep 3
	sshpass -p tc ssh -o StrictHostKeyChecking=no tc@192.168.2.129 "rm Who$victim"
	echo "================================================================================="
	#CD out of nipe to the original folder where the script is located and stop nipe
	perl nipe.pl stop
	cd ..
	log
	
}

#Once again, please change the ip here to whatever remote server you're using. 
function scanports()
{
	echo "This/these are the open ports currently"
	nmap 192.168.2.129 | grep open
	results=$(nmap 192.168.2.129 | grep open | wc -l)
	#Checks if there's any open ports here, if none end connection.
	if [ $results == 0 ]
	then
		echo "There are no open ports on this server, ending script"
		exit
	fi
	echo "================================================================================="
}

function log()
{
	#Current time now
	now=$(date)
	echo "$now whois $victim" >> logs
}

function finish()
{
	echo "================================================================================="
	echo "Thank you for using this program, all processes have been finished"
	exit
}

#This is running a for loop to check for everything in the array that I've listed on top. 
#If it's installed, it will mentioned it's installed. If it's not, it'll install it on it's own. 
for i in "${softwares[@]}"
do
	#The reason for this is because geoip is installed in a different way, the name is different from the function we use called geolookup, the package is geoip-bin
	if [ $i == "geoip" ]
	then
		existence=$(which "geoiplookup" | wc -l)
	else
		existence=$(which "$i" | wc -l)
	fi

	
	if [ $existence == 1 ]
	then
		echo "[#] $i is already installed"
	else
		echo "[X] $i is not installed, installing $i"
		if [ $i == "geoip" ]
		then
			#The flag -y is so that the machine forces a Yes input without stopping the script and asking for a User input. 
			apt-get install geoip-bin -y
		else
			apt-get install "$i" -y
		fi
	fi
	
done

#To run the function to check if nipe exists.
installnipe
runnipe
scanports
remotecommand
finish
