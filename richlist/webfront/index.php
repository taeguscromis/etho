<!DOCTYPE html>
<html lang="en-US" dir="ltr">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
  	<!--  
    Document Title
    =============================================
    -->
    <title>Ether1 Rich List</title>
    <!--      
    =============================================
    
    -->
    <!-- project stylesheets-->
    <link href="assets/styles/bootstrap.min.css" rel="stylesheet">
    <link href="assets/styles/datatables.min.css" rel="stylesheet">
    <link href="assets/styles/datatable-dark.css" rel="stylesheet">
    <link href="assets/styles/styling.css" rel="stylesheet">
    <link href="assets/styles/theme.css" rel="stylesheet">
    <!-- project scripts-->
    <script type="text/javascript" src="assets/script/jquery.min.js"></script>
    <script type="text/javascript" src="assets/script/bootstrap.min.js"></script>
    <script type="text/javascript" src="assets/script/sprintf.min.js"></script>
    <script type="text/javascript" src="assets/script/datatables.min.js"></script>
    <script type="text/javascript" src="assets/script/index.js"></script>
  </head>
  <body data-spy="scroll" data-target=".onpage-navigation" data-offset="60">
    <div id="maincontent">
      <div class="container-fluid d-none d-lg-block" id="richlisttable_header">
        <div class="row">
          <div class="col-sm-3 card text-center">
            <div class="card-body" id="pageLogo">
              <img src="assets/images/logo.png">
            </div>
          </div>
          <div class="col-sm-3 card text-center">
            <div class="card-body">
              <h5 class="card-title">All Addresses</h5>
              <p id="dataAddress" class="card-text">N/A</p>
            </div>
          </div>
          <div class="col-sm-3 card text-center">
            <div class="card-body">
              <h5 class="card-title">Current Supply</h5>
              <p id="dataSupply" class="card-text">N/A</p>
             </div>
          </div>
          <div class="col-sm-3 card text-center">
            <div class="card-body">
              <h5 class="card-title">Current Price</h5>
              <p id="dataPrice" class="card-text">N/A</p>
             </div>
          </div>
        </div>
      </div>
      <div id="richlisttable_wrapper">
        <table id="richlisttable" class="display stripe row-border hover">
          <thead>
              <tr>
                  <th>id</th>
                  <th>Address</th>
                  <th>Balance (ETHO))</th>
                  <th>% of Coins</th>
                  <th>First In</th>
                  <th>Last In</th>
                  <th>Deposits</th>
                  <th>First Out</th>
                  <th>Last Out</th>
                  <th>Withdrawals</th>
              </tr>
          </thead>
        </table>
      </div>
    </div>
  </body>
</html>
