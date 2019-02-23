
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
    $toBlock = $_GET['to'];
    $fromBlock = $_GET['from'];
    // main query for the actuall table data
    $sql = "SELECT * FROM transactions WHERE (fromaddr = '" . $_GET['address'] . "') OR (toaddr = '" . $_GET['address'] . "') AND ($fromBlock <= BLOCK) AND ($toBlock >= BLOCK)";
    $result = $conn->query($sql);
    $table_data = (object) [];

    if ($result->num_rows > 0) 
    {
      $rows_data = array();

      // output data of each row
      while($row = $result->fetch_assoc()) 
      {
        $data_object = (object) [];
        $data_object->id = $row["id"];
        $data_object->block = $row["block"];
        $data_object->timestamp = $row["timestamp"];
        $data_object->fromaddr = $row["fromaddr"];
        $data_object->toaddr = $row["toaddr"];
        $data_object->value = $row["value"];
        array_push($rows_data, $data_object);
      }
    } else {
      echo "Error: " . $sql . "<br>" . $conn->error;
    }

    // return the table data
    $table_data->data = $rows_data;
    echo json_encode($table_data);
  }

  $conn->close(); 
?>