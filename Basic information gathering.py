#!/usr/bin/python3

#Importing all the required libraries for this script
import os
import socket
import time

#Function to display the OS system details
def displayOS():
	
	print("=================================")
	print("These are the details of your current machine you're running this script on.")
	print("---------------------------------")
	#Storing the fields of the function os.uname()
	uname_fields = ["sysname", "nodename", "release", "version", "machine"]
	#Store the information of the system on the variable u
	u = os.uname()
	#Prints out the information in a clear manner using a for loop, capitalize is to capitalize the field names
	for field in uname_fields:
		print(f"{field.capitalize()}: {getattr(u, field)}")
	print("---------------------------------")
	print("=================================")

#Function for getting local, public and gateway
def IPs():
	
	print("These are the IP's your machine possesses")
	print("---------------------------------")
	print("Your local IP address is: ")
	#Uses the Linux system configuration to get the local IP using ifconfig
	os.system("ifconfig | grep broadcast | awk '{print $2}'")
	print("Your public IP address is: ")
	#Uses the curl function to get the public IP address
	os.system("curl ifconfig.io")
	print("Your default gateway is: ")
	#Uses ip route to get your gateway and prints it out
	os.system("ip route | grep default | awk '{print $3}'")
	print("---------------------------------")
	print("=================================")

#Function to get Dark disk space free and used
def hardDisk():
	
	print("These are your hard disk sizes, free and used space")
	print("---------------------------------")
	#This just pulls out the Hard Disk information
	os.system("df -h")
	print("---------------------------------")
	print("=================================")
	
#Function to get the top 5 directories from your root folder, there was an error on the last 2 lines, but I couldn't fix it due to lack of knowledge
def top5():
	
	print("These are your 5 biggest directories and their sizes")
	print("---------------------------------")
	#Gets the Information from /* sorts it in numerics, and gets the top 5 by using head
	os.system("du -ah /* 2>&1 | sort -rn | head -5")
	print("Please ignore the last 2 lines, it's an error in scripting that I can't seem to remove")
	print("---------------------------------")
	print("=================================")
	
#Function used for getting CPU usage every 10 seconds
def cpuUsage():
	#No instructions on a stoppage, so I put in a counter that'll last it 10*999999 seconds, or 999999 cycles of 10 seconds
	endlessCounter=1
	#While loop to make sure that as long as the Counter is not 999999, it will not stop.
	while endlessCounter < 999999:
		print("---------------------------------")
		print("These are your current's cycle CPU usage")
		print("You're on cycle " , endlessCounter, ", please press Ctrl+C on your terminal to exit the script")
		print("---------------------------------")
		#Gets the system information
		os.system("mpstat | grep -v Linux")
		print(" ")
		#Using the time module, time.sleep allows me to sleep the script for 10 seconds
		time.sleep(10)
		#Increments endlesscounter by 1
		endlessCounter+=1
		print("---------------------------------")
		print("=================================")
	#Assuming you really run this script for 999999 cycles, it will end so that there would be no memory leaks
	exit()
	
#All the different defintions for the extra calculator, takes in the paranthesis a and b
def addition(a, b):
	print(a+b)
def subtraction(a, b):
	print(a-b)
def division(a, b):
	print(a/b)
def multiplication(a, b):
	print(a*b)
	
	
#The main function that calls on everything
def main():
	#This while loop is to check if the user only inputs the right choices, 1 or 2. Everything else is invalid
	userInput=(input("Please pick which function you'd like to use, 1 for the project details or 2 for the extra Calculator function: "))
	while userInput !="1" and userInput !="2":
		userInput=input("Please only enter 1(Project) or 2(Extra calculator): ")
	#These if conditions are to check which choices the user inputs
	if userInput == "1":
		#The functions that were explained on top, I'm calling them here
		displayOS()
		IPs()
		hardDisk()
		top5()
		cpuUsage()	
	#Option 2 for the extra calculator function
	if userInput =="2":
		option="Option"
		#These is to tell the script which function should I use based of the users choice, and as if they want to exit by entering 0
		while option != "0":
			print("=================================")
			#As usual, this while loop is to check if the user input only 1, 2, 3, 4 or 0. Everything else is invalid
			option=input("Please pick which function you'd like to use, 1(Addition), 2(Subtraction), 3(Division), 4(Multiplication) or 0(Exit): ")
			while option.isnumeric() == False or (option !="0" and option !="1" and option !="2" and option !="3" and option !="4"):
				print("=================================")
				option=input("Please only enter a number 1, 2, 3, 4 or 0: ")
			if option != "0":
				#Once again, these while loops are to check if the user input a numeric value, and not a alpha
				#After checking if they are numeric, I change the input variables into int to run them through the function
				a = input("Please pick your first number: ")
				while a.isnumeric() == False:
					a = input("Please only put in a numerical value: ")
				a=int(a)
				b = input("Please pick your second number: ")
				while b.isnumeric() == False:
					b = input("Please only put in a numerical value: ")
				b=int(b)
				if option == "1":
					addition(a, b)
				if option == "2":
					subtraction(a, b)
				if option == "3":
					division(a, b)
				if option == "4":
					multiplication(a, b)
			
				
		print("=================================")
		print("Thank you for using our calculator")
#The calling of the main function, and exit() in the rare occurence the script still runs after main to prevent a memory leak
main()
exit()
