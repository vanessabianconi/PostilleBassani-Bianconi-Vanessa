
$('.aggiungi').on('click', aggiungi);
    $('.rimuovi').on('click', rimuovi);

function aggiungi() {
    if(parseInt($('#totale_input').val()) == 10){
        $('#errore').show();
        $('.aggiungi').attr('disabled',true);
    }
    else {
  var nuovo_totale = parseInt($('#totale_input').val()) + 1;
  var nuovo_input = "<input type='text' id='new_" + nuovo_totale + "' name='input' class='form-control aggiuntivi' required></input>";

  $('#nuovoinput').append(nuovo_input);
  
  $('#totale_input').val(nuovo_totale);
    }
}

function rimuovi() {
  var numero_input = parseInt($('#totale_input').val());

  if (parseInt(numero_input) > 1 && parseInt(numero_input) <= 10) {
    $('#new_' + numero_input).remove();
    $('#totale_input').val(numero_input - 1);
    $('.aggiungi').attr('disabled',false);
    $('#errore').hide();
  } 
    
}


