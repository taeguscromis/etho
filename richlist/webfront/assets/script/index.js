$(document).ready(function() 
{
  function getDataTableHeight()
	{
    var tableBottom = $("#richlisttable_wrapper").offset().top + $("#richlisttable_wrapper").outerHeight(true);
    return ($('.dataTables_scrollBody').height() - (tableBottom - $(window).height())) - 40;
  }

  var ImportantAddresses = 
  {
    "0XE19363FFB51C62BEECD6783A2C9C5BFF5D4679AC": "Masternode Reward Address",
    "0XE2C8CBEC30C8513888F7A95171EA836F8802D981": "Ether-1 Dev Fund Address",
    "0XFBD45D6ED333C4AE16D379CA470690E3F8D0D2A2": "Stex Exchange Wallet",
    "0x3951F8fAA758f221EBd236797d23065A83633e32": "Mercatox Echange Wallet",
    "0X548833F13D6BF156260F6E1769C847991C0F6324": "Graviex Echange Wallet"
  }

  $('#richlisttable').DataTable( 
  {
      "pageLength": 50,
      "responsive": true,
      "processing": true,
      "serverSide": true,
      "scrollCollapse": true,
      "pagingType": "full_numbers",
      "ajax": "index_load.php",
      "sScrollY": $(window).height() - 140,
      "order": [[ 2, "desc" ]],
      'columnDefs': 
      [
  			{
      			"targets": 0, 
      			"visible": false
       	},
       	{
      			"targets": 1,
			"responsivePriority": -1,
      			"render": function ( data, type, full, meta ) 
     			  {
              var addressAsStr = data

              if (ImportantAddresses[data.toUpperCase()]) {                  
                addressAsStr = vsprintf('%s<br><label class="addressLabel">%s</label>', [addressAsStr, ImportantAddresses[data.toUpperCase()]]);
              }

              return vsprintf('<a href="transactions.php?address=%s">%s</a>', [data, addressAsStr]);
   		   	  }
  			},
  			{
      			"targets": 2, 
		        "className": "text-right"
       	},
  			{
      			"targets": [ 3, 4, 5, 6, 7, 8, 9 ],
		    	  "className": "text-center"
        },
        {
            "targets": [ 3, 4, 5, 7, 8 ],
            "orderable": false
        }         
		  ]
  });

  function onWindowResizeEvent()
  {
  	$('.dataTables_scrollBody').css('height', getDataTableHeight() + 'px');
  }
  
  $('#richlisttable').DataTable().off('responsive-resize').on('responsive-resize', function ( e, datatable, columns ) 
  {
    $('.dataTables_scrollBody').css('height', getDataTableHeight() + 'px');
  });

  $(window).resize(function() 
  {
	  onWindowResizeEvent();
	});

  $.getJSON("overalls.php", function( data ) 
  {
    $("#dataAddress").html(data.addrnum);
    $("#dataSupply").html(data.supply + " ETHO");
  });	

  $.getJSON("https://min-api.cryptocompare.com/data/price?fsym=ETHO&tsyms=USD", function( data ) 
  {
    $("#dataPrice").html(data.USD + " $");
  }); 

  // add class to the search filter
  $('#richlisttable_filter input').addClass('searchFilter');
  $('#richlisttable_filter').addClass('d-none'); 
  $('#richlisttable_filter').addClass('d-lg-block');

  onWindowResizeEvent();    
});
