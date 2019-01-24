
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
    // the current circulating supply of ETHO
    $supply = $conn->query("SELECT sum(value) as 'supply' FROM richlist");
    $supply = $supply->fetch_assoc();

    $totalSupply = $supply['supply']/pow(10,18);
    echo $totalSupply;
  }
  $conn->close();
?>
