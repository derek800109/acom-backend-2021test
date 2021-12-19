#!/bin/bash
trap '' 2  # ignore control + c

##### SQL
DB_NAME="objective2"
TABLE_NAME="packets"
USER="root"
PASSWORD="0000"

##### column
DATE_COL="Date"
TIME_COL="Time"
USEC_COL="usec"
SIP_COL="SourceIP"
SPT_COL="SourcePort"
DIP_COL="DestinationIP"
DPT_COL="DestinationPort"
FQDN_COL="FQDN"

##### pagination
ROWS_OF_PAGE=50


#####
while true
do
  clear # clear screen for each loop of menu
  echo "===================================================================="
  echo "CLI menu to search the database by the following fields:"
  echo "===================================================================="
  echo "Enter 1 to query by Source IP:"
  echo "Enter 2 to query by Time range (from ~ to):"
  echo "Enter 3 to query by FQDN:"
  echo "Enter q to quit q:"
  echo -e "Enter your selection here and hit <return> .. c"
  read answer  # create variable to retains the answer
  case "$answer" in
	1)
		echo -e "Enter source_ip and hit <return> .. c"
		read source_ip  # create variable to retains the answer
		
		count_cmd="USE ${DB_NAME};
				SELECT count(*) FROM ${TABLE_NAME} 
				WHERE INSTR(${SIP_COL}, '${source_ip}')"
		
		command="USE ${DB_NAME};
				SELECT * FROM ${TABLE_NAME} 
				WHERE INSTR(${SIP_COL}, '${source_ip}') 
				ORDER BY ${DATE_COL},${TIME_COL},${USEC_COL} ASC"
		
		echo "Entered" $source_ip
		;;
	2)
		echo -e "Enter time_from(format: 00:00:00) and hit <return> .. c"
		read time_from  # create variable to retains the answer
		echo -e "Enter time_to(format: 23:59:59) and hit <return> .. c"
		read time_to  # create variable to retains the answer
		
		count_cmd="USE ${DB_NAME};
				SELECT count(*) FROM ${TABLE_NAME} 
				WHERE ${TIME_COL} BETWEEN '${time_from}' AND '${time_to}"
		
		command="USE ${DB_NAME};
				SELECT * FROM ${TABLE_NAME} 
				WHERE ${TIME_COL} BETWEEN '${time_from}' AND '${time_to}'
				ORDER BY ${DATE_COL},${TIME_COL},${USEC_COL} ASC"
		
		echo "Entered" $time_from $time_to
		;;
	3)
		echo -e "Enter FQDN and hit <return> .. c"
		read fqdn  # create variable to retains the answer
		
		count_cmd="USE ${DB_NAME};
				SELECT count(*) FROM ${TABLE_NAME} 
				WHERE INSTR(${FQDN_COL}, '${fqdn}')"
		
		command="USE ${DB_NAME};
				SELECT * FROM ${TABLE_NAME} 
				WHERE INSTR(${FQDN_COL}, '${fqdn}') 
				ORDER BY ${DATE_COL},${TIME_COL},${USEC_COL} ASC"
		
		echo "Entered" $fqdn
		;;
	q) exit ;;
	esac
  
	if [ "$command" != "" ]; then
		count=$(mysql -u "$USER" -p0000 -s -e "$count_cmd")
		page_number=$((count / ROWS_OF_PAGE + 1))
		page=0
		
		echo "Count: ${count} ${page} ${page_number}"
		while [ $page -lt $page_number ]
		do
			skip_row=`expr $page \\* $ROWS_OF_PAGE`
			
			#####
			page_cmd="${command} LIMIT ${skip_row},${ROWS_OF_PAGE}"
			mysql -u "$USER" -p0000 -e "$page_cmd"
			
			##### stop to see
			page=`expr $page + 1`
			echo -e "Hit the <return> key to see next page(${page}/${page_number}).. c"
			read input ##This cause a pause so we can read the output
		done
	fi
  
  echo -e "Hit the <return> key to continue.. c"
  read input ##This cause a pause so we can read the output
  #of the selection before the loop clear the screen
done

