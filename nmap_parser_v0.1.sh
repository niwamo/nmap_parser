#!/bin/bash


#================================================================
#||                         parse_nmap                         ||
#||                            v0.1                            ||
#================================================================
#||                                                            ||
#||                Written by: Nicholas Morris                 ||
#||             Contact: https://github.com/nm2438             ||
#||                                                            ||
#||                      Date: 13AUG2020                       ||
#||                                                            ||
#================================================================
#||    Given the output of an nmap scan -- formatted in t      ||
#||    he typical 'open ports per host' layout, prints ou      ||
#||    t a re-formatted scan result in the 'hosts listeni      ||
#||    ng per service' format                                  ||
#================================================================


#receives path to file via the command line
target_file=$1


################################################################################
#Section One - Input
#Reads the file line-by-line
#ends with the 'blocks' array containing exactly one string per host
#each host-string takes the form '[IP] [service 0] [service 1] ... [service n]'
#'blocks' = block of text in the nmap report
################################################################################


declare -a blocks
declare -i count
count=0


#while loop reads line-by-line so long as there are lines remaining
while read line;
do
	#search the current line for an IP
	rslt=$(echo $line | grep -E -o "([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})$")
	
	#if line contains an IP, start a new 'blocks' entry and add the IP
	if [[ ! -z "$rslt" ]]; 
	then
		count+=1
		blocks[$count]+=$rslt

	#if the line does not contain an IP, but the script is currently parsing a block,
	#search for the nmap service table syntax. if present, capture and return the service
	elif [ "$count" -gt "0" ]; 
	then
		grepped=$(echo $line | grep -E "\w{1,4}/\w{3}\s+\w{4}\s+(\w+)" | grep -E -o "(\w+-*)+$")
		if [[ ! -z "$grepped" ]];
		then
			blocks[$count]+=' '$grepped
		fi
	fi
done < $target_file


#Debug statements
#echo "${blocks[5]}"
#echo "${blocks[*]}"
#echo "${#blocks[*]}"


################################################################################
#Section Two - Re-formatting
#takes the 'services per IP' format and returns 'hosts per service'
#key output is services associative array
#each entry is keyed with a service name, and has a value of:
# [ip 1] [ip 2] ... [ip n]
################################################################################


declare -A services


#iterate through hosts
for host in "${blocks[@]}"
do
	lst=( $host )
	hostIP=$(echo ${lst[0]})
	
	#debug statements
	#echo "I am in the host-blocks loop"
	#echo "${lst[*]}"

	new_lst="${lst[@]:1}"
	serv_lst=( $new_lst )

	#debug statements
	#echo $hostIP
	#echo "${serv_lst[@]}"
	#printf "\n"
	#echo "${listed_services[@]}"

	#iterate through the services listed under each host
	#for each service, append the host's ip to the relevant
	#services array entry
	for serv in "${serv_lst[@]}"
	do
		new_str=$hostIP' '
		services[$serv]+=$new_str

		#debug statements
		#echo "inside listed services loop"
		#echo $serv
		#echo $new_str
		#echo "${services[$serv]}"
		#echo $serv
	done
done

#debug statements
#http_ips="${services['http']}"
#http_list=( $http_ips )
#for ip in "${http_list[@]}"
#do 
#	printf $ip"\n"
#done


################################################################################
#Section Three - Output
#iterates through all services
#prints out a list of IPs for each service
################################################################################


#enumerate all of the service-keys used in the associative array
keys="${!services[*]}"
keys_lst=( $keys )


#debug statements
#echo "${services[*]}"
#echo "${keys[@]}"


#for each service, return the IP list
for service_key in "${keys_lst[@]}"
do
	ips="${services[$service_key]}"
	ips_list=( $ips )

	#debug
	#echo "${ips_list[@]}"

	count="${#ips_list[@]}"
	printf "==========================="
	printf "\n"
	printf "Service: "$service_key
	printf "\n"
	printf "Count: "$count
	printf "\n"
	printf "==========================="
	printf "\n"

	#print each ip from the ip list on its own line
	for ip in "${ips_list[@]}"
	do
		printf $ip
		printf "\n"
	done
	printf "==========================="
	printf "\n\n"
done
