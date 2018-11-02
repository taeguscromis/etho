
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
    $record_start = intval($_GET['start']);
    $record_limit = intval($_GET['length']);
    
    // main query for the actuall table data
    $sql = "SELECT * FROM transactions WHERE (fromaddr = '" . $_GET['address'] . "') OR (toaddr = '" . $_GET['address'] . "') ORDER BY id DESC LIMIT $record_limit OFFSET $record_start";
    $result = $conn->query($sql);

    // count of total rows in the richlist table
    $count = $conn->query("SELECT count(*) as 'total_rows' FROM richlist");
    $count = $count->fetch_assoc();


    $table_data = (object) 
    [
      'draw' => $_GET['draw'],
      'recordsTotal' => $count["total_rows"],
      'recordsFiltered' => $count["total_rows"]
    ];

    if ($result->num_rows > 0) 
    {
      $rows_data = array();

      // output data of each row
      while($row = $result->fetch_assoc()) 
      {
        $row_data = array();
        array_push($row_data, $row["id"]);
        array_push($row_data, $row["block"]);
        array_push($row_data, $row["timestamp"]);
        array_push($row_data, $row["fromaddr"]);
        array_push($row_data, $row["toaddr"]);
        array_push($row_data, number_format(floatval($row["value"]) / pow(10,18),2)); 
        array_push($rows_data, $row_data);
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