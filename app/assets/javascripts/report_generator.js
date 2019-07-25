$(document).on('show.bs.modal', '#generate-report-modal', function(event) {
    var buttonData = $(event.relatedTarget).data();

    $('#generate-report-button').off('click.reportGenerator').on('click.reportGenerator', function(clickEvent) {
        clickEvent.preventDefault();

        var reportData = {
            send_email: $('#report-email').is(':checked')
        };

        $.each(buttonData, function(key, value) {
            if (key.indexOf('report') >= 0) {
                reportData[key] = value
            }
        });

        $(':input.report-data-field').each(function() {
            if (this.value) {
                var name = this.name.replace(/\[\]$/, '');
                reportData[name] = $(this).val();
            }
        });

        var data = { report_download: reportData };

        $.post(buttonData.reportUrl, data, function() {
            $('#generate-report-modal').modal('hide');
        });
    });
});
