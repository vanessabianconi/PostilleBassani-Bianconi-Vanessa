
     $(document).ready(function() {
        for (var i = 0; i < $('.linkpost').length; i++) {
           $('.linkpost:eq(' + i + ')').text('Postilla ' + i);
        };
     });