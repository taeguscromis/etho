
<?php
  $config = parse_ini_file('/var/www/conf/richlist/settings.ini'); 
  // Create connection
  $conn = new mysqli($config['servername'],$config['username'],$config['password'],$config['dbname']);

  // Check connection
  if ($conn->connect_error) {
    echo "Connection failed: " . $conn->connect_error;
  } 
  else 
  {
    $result = $conn->query("SELECT count(id) as 'addrnum', sum(value) as 'supply' FROM richlist;");
    $result = $result->fetch_assoc();

    $result_data = (object) 
    [
      'addrnum' => $result["addrnum"],
      'supply' => number_format((floatval($result["supply"]) / pow(10,18)),0)
    ];
  
    echo json_encode($result_data);
  }

  $conn->close(); 
?>