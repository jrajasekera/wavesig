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
//= require local-time

let playing = false;
let player = null;

$(document).ready(function() {

});

$(document).on('turbolinks:load', function () {
    $('.multiselect').multiselect({
        enableFiltering: true,
        filterBehavior: 'text',
        enableCaseInsensitiveFiltering: true,
        nonSelectedText: 'Select friends'
    });

    player = document.getElementById('player');

    if(player) {

        let progressCircleElement = document.getElementById('progress-circle');
        let currentPlaybackTimeElement = document.getElementById("current-playback-time");
        let pauseBtnElement = document.getElementById('pause-music-btn');
        let playBtnElement = document.getElementById('play-music-btn');

        $(".progress").hover(function(){
            currentPlaybackTimeElement.style.display = "none";
            playing ? pauseBtnElement.style.display = "initial" : playBtnElement.style.display = "initial";
        }, function(){
            currentPlaybackTimeElement.style.display = "initial";
            playing ? pauseBtnElement.style.display = "none" : playBtnElement.style.display = "none";
        });

        player.addEventListener("timeupdate", function(event) {
            let duration = player.duration;
            let currentTime = player.currentTime;
            let completionPercentage = Math.round((currentTime / duration) * 100);
            progressCircleElement.setAttribute("data-value",completionPercentage.toString());
            setProgress();
            currentPlaybackTimeElement.innerText = currentTime.toString().toMMSS();
        });

        player.addEventListener("loadedmetadata", function(event) {
            document.getElementById('file-duration').innerText = player.duration.toString().toMMSS();
        });

        player.addEventListener("ended", function(event) {
            playing = false;
            progressCircleElement.setAttribute("data-value","0");
            setProgress();
            currentPlaybackTimeElement.innerText = "00:00";
            playBtnElement.style.display = "initial";
            pauseBtnElement.style.display = "none";
            currentPlaybackTimeElement.style.display = "none";
        });

    }

});

$(document).on('turbolinks:load', function(){
    let alertSuccessElement = $(".alert-success");
    let alertDangerElement = $(".alert-danger");

    alertSuccessElement.delay(2500).slideUp(500, function(){
        alertSuccessElement.alert('close');
    });
    alertDangerElement.delay(4000).slideUp(500, function(){
        alertDangerElement.alert('close');
    });
});

function showUploadSpinner() {
    if($('#file-name-field')[0].value.length > 0 && $('#browse-file-field')[0].value.length > 0) {
        $('#upload_file_btn').hide();
        $('#upload_file_spinner').show();
    }
}

function showAnalyzingSpinner() {
    if($('#browse-file-field')[0].value.length > 0) {
        $('#analyze_file_btn').hide();
        $('#analyzing_file_spinner').show();
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
        //extName = this.name.split('.').pop();
        //if ($.inArray(extName, allowedExtension) == -1) {extError=true;};
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

document.addEventListener("notifications-count-loaded", function(event) {
    let notificationsDisplayCount = event.container[0].innerText.trim();
    let iconTag = $("#notification-icon");
    let mobileBadge = $("#mobile-notification-badge");
    let oldCount = iconTag.attr('data-count');

    if(oldCount != notificationsDisplayCount) {
        let singleDigitClass = "notifications-count-single-digit";
        let doubleDigitClass = "notifications-count-double-digit";
        let hasBadgeClass = "has-badge";
        let mobileBadgeClass = "badge badge-light";

        iconTag.removeClass(`${singleDigitClass} ${doubleDigitClass} ${hasBadgeClass}`);
        mobileBadge.removeClass(mobileBadgeClass);

        if(notificationsDisplayCount == "") {
            iconTag.addClass(singleDigitClass);
        } else if(notificationsDisplayCount == "9+") {
            iconTag.addClass(`${doubleDigitClass} ${hasBadgeClass}`);
            mobileBadge.addClass(mobileBadgeClass);
        } else {
            iconTag.addClass(`${singleDigitClass} ${hasBadgeClass}`);
            mobileBadge.addClass(mobileBadgeClass);
        }

        iconTag.attr("data-count",notificationsDisplayCount);
    }
});

function setProgress() {
    let progressCircle = document.getElementById('progress-circle');
    var value = $(progressCircle).attr('data-value');
    var left = $(progressCircle).find('.progress-left .progress-bar');
    var right = $(progressCircle).find('.progress-right .progress-bar');

    if (value > 0) {
        if (value <= 50) {
            right.css('transform', 'rotate(' + percentageToDegrees(value) + 'deg)')
        } else {
            right.css('transform', 'rotate(180deg)')
            left.css('transform', 'rotate(' + percentageToDegrees(value - 50) + 'deg)')
        }
    } else {
        right.css('transform', 'rotate(0deg)');
        left.css('transform', 'rotate(0deg)');
    }
}

function percentageToDegrees(percentage) {
    return percentage / 100 * 360
}

String.prototype.toMMSS = function () {
    var sec_num = parseInt(this, 10); // don't forget the second param
    var hours   = Math.floor(sec_num / 3600);
    var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
    var seconds = sec_num - (hours * 3600) - (minutes * 60);

    if (hours   < 10) {hours   = "0"+hours;}
    if (minutes < 10) {minutes = "0"+minutes;}
    if (seconds < 10) {seconds = "0"+seconds;}
    return minutes + ':' + seconds;
}

function clickPlay() {
    if(!playing) {
        playing = true;
        document.getElementById('player').play();
        document.getElementById('play-music-btn').style.display = "none";
        document.getElementById('pause-music-btn').style.display = "initial";
    }
}

function clickPause() {
    if(playing) {
        playing = false;
        document.getElementById('player').pause();
        document.getElementById('pause-music-btn').style.display = "none";
        document.getElementById('play-music-btn').style.display = "initial";
    }
}

