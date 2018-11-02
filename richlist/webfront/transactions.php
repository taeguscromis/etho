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
    <title>Address Transactions</title>
    <!--      
    =============================================
    
    -->
    <!-- project stylesheets-->
    <link href="assets/styles/datatables.min.css" rel="stylesheet">
    <link href="assets/styles/styling.css" rel="stylesheet">
    <!-- project scripts-->
    <script type="text/javascript" src="assets/script/jquery.min.js"></script>
    <script type="text/javascript" src="assets/script/sprintf.min.js"></script>
    <script type="text/javascript" src="assets/script/datatables.min.js"></script>
    <script type="text/javascript" src="assets/script/transactions.js"></script>
  </head>
  <body data-spy="scroll" data-target=".onpage-navigation" data-offset="60">
    <div id="maincontent">
      <div id="richlisttable_wrapper">
        <table id="transactionstable" class="display stripe row-border hover">
          <thead>
              <tr>
                  <th>id</th>
                  <th>Block</th>
                  <th>Timestmap</th>
                  <th>From Addr.</th>
                  <th>To Addr.</th>
                  <th>Value (ETHO)</th>
              </tr>
          </thead>
        </table>
      </div>
    </div>
  </body>
</html>