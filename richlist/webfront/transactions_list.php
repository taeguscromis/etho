
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
    $address = $_GET['address'];
    $toBlock = intval($_GET['toBlock']);
    $fromBlock = intval($_GET['fromBlock']);
    // main query for the actuall table data
    $sql = "SELECT * FROM transactions WHERE (fromaddr = '$address' OR toaddr = '$address') AND (block > $fromBlock AND block < $toBlock) ORDER BY block";
    $result = $conn->query($sql);
    $table_data = (object) [];
    $rows_data = array();


    if ($result->num_rows > 0) 
    {
      // output data of each row
      while($row = $result->fetch_assoc()) 
      {
        $data_object = (object) [];
        $data_object->id = $row["id"];
        $data_object->block = $row["block"];
        $data_object->txhash = $row["txhash"];
        $data_object->timestamp = $row["timestamp"];
        $data_object->fromaddr = $row["fromaddr"];
        $data_object->toaddr = $row["toaddr"];
        $data_object->value = $row["value"];
        array_push($rows_data, $data_object);
      }
    }

    // return the table data
    $table_data->data = $rows_data;
    echo json_encode($table_data);
  }

  $conn->close(); 
?>
