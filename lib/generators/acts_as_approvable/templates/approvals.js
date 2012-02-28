$(function() {
  // Assignment
  $('form.assignment').each(function() {
    var form = $(this),
        spinner = $('.spinner', this);

    form.ajaxForm({
      dataType: 'json',
      beforeSubmit: function() {
        spinner.show();
      },
      success: function(data, status, jqx) {
        spinner.hide();

        if (!data.success) {
          alert('There was an issue assigning this approval!')
        }
      },
      error: function(jqx, status, error) {
        spinner.hide();
        alert('There was an issue assigning this approval!')
      },
    });

    $('select', this).change(function() {
      form.submit();
    });
  });

  // Approval and Rejection
  var actionLinks = $('td.actions a');

  actionLinks.click(function() {
    if ($(this).hasClass('disabled')) return false;

    var verbing = ($(this).hasClass('approve') ? 'approving' : 'rejecting'),
        row = $(this).parents('tr'),
        settings = {
          dataType: 'json',
          url: $(this).attr('href'),
          beforeSubmit: function() {
            actionLinks.addClass('disabled');
          },
          success: function(data) {
            actionLinks.removeClass('disabled');

            if (!data.success) {
              if (data.message) {
                alert(data.message);
              } else {
                alert('There was an issue ' + verbing + ' the approval.');
              }
            } else {
              row.fadeOut('fast', row.remove);
            }
          },
          error: function() {
            actionLinks.removeClass('disabled');
            alert('There was an issue ' + verbing + ' the approval.');
          }
        };

    if ($(this).hasClass('reject')) {
      var reason = prompt('Reason for rejection');
      if (reason) settings['data'] = {reason: reason};
    }

    $.ajax(settings);
    return false;
  });
});
