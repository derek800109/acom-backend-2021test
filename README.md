# acom-backend-2021test

############################################################################################

Author: Derek Hsu \
Context: This github is for the remote testing purpose \
language: PERL, SHELL SCRIPT, PHP, SQL \
Duration: 48 hr \
Tool: PUTTY, WINSCP \
Editor: Notepad++ \

############################################################################################ File Architecture

1. url
   1. http://159.223.71.86/
   2. http://159.223.71.86/healthy.php
2. objective1
   1. StressTestReport.pdf
3. objective 2
   1. /root/import.pl
   2. /root/Search.sh
5. objective 3
   1. /var/www/acom-objective3-derek/html/healthy.php
   2. /var/www/acom-objective3-derek/html/monitor.sh
   3. /var/www/acom-objective3-derek/html/config.ini
   4. /home/logs/objective3-derek.log

############################################################################################ OBJECTIVE 1

1. Use MySQL benchmark tools to do stress test (such as sysbench and provide a report
    1. before going to far, do yum update first

############################################################################################ OBJECTIVE 2

1. Title: Write a program in PERL to decode and process PCAP files into a database table
    1. reference
        1. https://www.itread01.com/p/1204468.html
        2. https://www.itread01.com/content/1550324734.html
    2. Come down and separate this challange into 2 parts
        1. extract pcap (packet capture)
        2. insert the data into SQL
    3. The process of this section
        1. Start a SQL table
            a. drop out the exist table before creating new one
        3. File::PCAP::Reader
        4. next_packet()
        5. NetPacket::Ethernet::strip
        6. NetPacket::IP->decode
            a. Getting source IP and destination IP from here
        6. NetPacket::TCP->decode
            a. Getting source PORT and destination PORT from here
        7. NetPacket::UDP->decode
            a. FQDN is supposed to be extracted from here, however, i still can't get ride of special character
        9. INSERT PCAP data to SQL
            a. actually extracted PCAP hash is directly inserted into SQL because the amount of a PCAP data is too large
   4. difficulty
        1. for the argument of subroutines, you have to be very carefully about "pass by value" and "passive by reference"
        2. the amount of single PCAP is just too large to use TcpDumpLog. It will cause "out of memory"
2. Build a shell script as C LI menu to search the database by the following fields:
    1. hint
        1. use "instr" instead of "equal" so that you can get greater amount of result
4. The Search function should list the following fields in a table:
    1. difficulty
        1. separate sql command to 2 parts. one is for getting the total count of rows, another is for getting the actual output
        2. because we are under SQL server, we would like to use LIMIT to do pagination rather than SKIP and FETCH

############################################################################################ OBJECTIVE 3

1. Write a program monitor in PERL to monitor the local Web service and PHP MySQL connection status
    1. hint
        1. remember to install php7. php5 is not that friendy to do the connection between php and sql
        2. remember to start the mysql before trying to connect to it
        3. hide the important data, ex pid,pw, to config.ini for better security
        4. using PDO rather than mysqli to connect php and mysql is an easier way
        5. remember to close the connection after PDO command, otherwise, the server will be overloaded
        6. while doing "curl_init", you will get an infinitive loop if its URL is as same as the current file name
    2. ISSUE
       1. i didn't look into the logical architecture carefully and so functions are missing places
       2. healthy.php do the most of the things including write logs
       3. rather then the origin use of Monitor.pl, i simply use monitor.sh do to the crantab
2. Use Crontab to set this monitor program auto run every 5 mins
    1. issue
       1. for some reason, i can't make the crontab running
       2. the command is the following
          1. content of /etc/crontab
             1. 5 * * * * root /var/www/acom-objective3-derek/html/monitor.sh
          3. systemctl start crond

############################################################################################
