$(document).ready(function() 
{
  var getUrlParameter = function getUrlParameter(sParam) 
  {
      var sPageURL = decodeURIComponent(window.location.search.substring(1)),
      sURLVariables = sPageURL.split('&'),
      sParameterName,
      i;

    for (i = 0; i < sURLVariables.length; i++) 
    {
        sParameterName = sURLVariables[i].split('=');

        if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true : sParameterName[1];
        }
    }
  };

 	function getDataTableHeight()
	{
    	var tableBottom = $("#transactionstable_wrapper").offset().top + $("#transactionstable_wrapper").outerHeight(true);
    	return ($('.dataTables_scrollBody').height() - (tableBottom - $(window).height())) - 20;
    }

    $('#transactionstable').DataTable( 
    {
        "searching": false,
        "pageLength": 50,
        "processing": true,
        "serverSide": true,
        "scrollCollapse": true,
        "pagingType": "full_numbers",
        "ajax": vsprintf('transactions_load.php?address=%s', [getUrlParameter('address')]),
        "sScrollY": $(window).height() - 140,
        'columnDefs': 
        [
    			{
        			"targets": 0, 
        			"visible": false
         	},
          {
              "targets": [ 3, 4 ],
              "render": function ( data, type, full, meta ) 
              {
                return vsprintf('<a href="transactions.php?address=%s">%s</a>', [data, data]);    
              }
          },
    			{
        			"targets": [ 1, 2, 3, 4 ],
    		    	"className": "text-center"
        	},
          {
              "targets": 5, 
              "className": "text-right"
          }
   		]
    });

    function onWindowResizeEvent()
    {
    	$('.dataTables_scrollBody').css('height', getDataTableHeight() + 'px');
    }
    
    $('#transactionstable').DataTable().off('responsive-resize').on('responsive-resize', function ( e, datatable, columns ) 
    {
      $('.dataTables_scrollBody').css('height', getDataTableHeight() + 'px');
    });

    $(window).resize(function() 
	{
		onWindowResizeEvent();
	});

	onWindowResizeEvent();    
});