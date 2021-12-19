<html>
	<head>
		<title>PHP Test</title>
	</head>
	<body>
<?php
	
##########################################################

$configFilename = "config.ini";
$ini_array = parse_ini_file($configFilename);

$logger = $ini_array['logger'];
$URL = $ini_array['URL'];
$indexURL = $ini_array['indexURL'];
$serverName = $ini_array['serverName'];
$uid = $ini_array['uid'];  
$pwd = $ini_array['pwd'];
$databaseName = $ini_array['databaseName'];
$timeZone = $ini_array['timeZone'];
$statusOK = $ini_array['statusOK'];
$statusERROR = $ini_array['statusERROR'];
$mysqlStatus = $ini_array['mysqlStatus'];
$logFilename = $ini_array['logFilename'];

############################################################################### objective 3.1.2 3.1.3

try {
  $conn = new PDO("mysql:host=$serverName;dbname=$databaseName", $uid, $pwd);
  
  $conn = null;
  
  $mysql_status = $statusOK;
} catch(PDOException $e) {
  #echo "Connection failed: " . $e->getMessage() . "\n";
  $mysql_status = $statusERROR;
}

##### now datetime
$objDateTime = new DateTime('NOW', new DateTimeZone( $timeZone));
$nowTime = $objDateTime->format("Y-m-d H:i:s.u");

##### pid
$pid = getmypid();

##### sql response
$sqlStatusJson = json_encode(array($mysqlStatus => $mysql_status));
echo '<pre>' . $sqlStatusJson . '</pre>';

##### status of apache
$handle = curl_init($indexURL);
$response = curl_exec($handle);
$httpCode = curl_getinfo($handle, CURLINFO_HTTP_CODE);
curl_close($handle);

##### create log
if ( $httpCode == 200 ) {
	$log = "[$nowTime] $mysql_status:PID:$pid ,response:$sqlStatusJson";
} else {
	$log = "[$nowTime] $statusERROR:PID:$pid ,ERROR-Can't connect to $URL";
}

#echo "\n\n" . $log . "\n";

##### write log
if ( $logger ) {
	#echo "Write" . $log . "\n\tto: " . $logFilename . "\n";
	error_log( $log . "\n" , 3, $logFilename);
}

##########################################################

?>
	</body>
</html>