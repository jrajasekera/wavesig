// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require_tree .
//= require jquery3
//= require popper
//= require bootstrap
//= require bootstrap-multiselect
//= require chartkick
//= require Chart.bundle

$(document).ready(function() {

});

$(document).on('turbolinks:load', function () {
    $('.multiselect').multiselect({
        enableFiltering: true,
        filterBehavior: 'text',
        enableCaseInsensitiveFiltering: true,
        nonSelectedText: 'Select friends'
    });
});

// slide alerts away after 2 seconds
$(function() {
    setTimeout(function(){
        $('.alert').slideUp(500);
    }, 2000);
});

function showUploadSpinner() {
    if($('#file-name-field')[0].value.length > 0 && $('#browse-file-field')[0].value.length > 0) {
        $('#upload_file_btn').hide();
        $('#upload_file_spinner').show();
    }
}

function invertArrow(card_id) {
    let arrow = $("#" + card_id + " > h2 > button > div.collapse-arrow > i")
    if (arrow.hasClass("down")) {
        arrow.removeClass("down").addClass("up");
    } else {
        arrow.removeClass("up").addClass("down");
    }
}

function validateFiles(inputFile) {
    var extName;
    var maxFileSize = $(inputFile).data('max-file-size');
    var sizeExceeded = false;
    var extError = false;

    var maxExceededMessage = `This file exceeds the maximum allowed file size ${maxFileSize/1048576} MB`;
    var extErrorMessage = "Only audio files with extension .wav is allowed";
    var allowedExtension = ["wav"];

    $.each(inputFile.files, function() {
        if (this.size && maxFileSize && this.size > parseInt(maxFileSize)) {sizeExceeded=true;};
        extName = this.name.split('.').pop();
        if ($.inArray(extName, allowedExtension) == -1) {extError=true;};
    });
    if (sizeExceeded) {
        window.alert(maxExceededMessage);
        $(inputFile).val('');
    };

    if (extError) {
        window.alert(extErrorMessage);
        $(inputFile).val('');
    };
}