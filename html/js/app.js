var money = Intl.NumberFormat('en-US', {
	style: 'currency',
	currency: 'USD',
	minimumFractionDigits: 0
});

(() => {
    Kashacter = {};

    Kashacter.ShowUI = function(data) {
        let currentTimestamp = Date.now()
        let finalTimestamp = currentTimestamp - data.created_at 
        let days = Math.ceil(finalTimestamp/(1000 * 3600 * 24))
        console.log(data.created_at, finalTimestamp, currentTimestamp)

        $('body').css({"display":"grid"});
        $('.main-container').css({"display":"grid"});
        $('.name').html(data.firstname +' '+ data.lastname)
        $('[data-charid=1]').html(
            '<div>' +
                '<p><h1>Su Peakville da:</h1><span>' + days + ' ' + (days === 1 ? 'giorno' : 'giorni') + '</span></p>' +
                '<p><h1>Data di nascita:</h1><span>' + data.dateofbirth + '</span></p>' +
                '<p><h1>Abitudine:</h1><span>' + data.light_constraint + '</span></p>' +
                '<p><h1>Vincolo morale:</h1><span>' + data.heavy_constraint + '</span></p>' +
                '<p><h1>Aspirazione:</h1><span>' + data.goal + '</span></p>' +
            '</div>'
        ).attr("data-ischar", "true");
    };

    Kashacter.CloseUI = function() {
        $('body').css({"display":"none"});
        $('.main-container').css({"display":"none"});
		$('[data-charid=1]').html('<h3 class="character-fullname"></h3><div class="character-info"><p class="character-info-new"></p></div>');
    };

    window.onload = function(e) {
        window.addEventListener('message', function(event) {
            switch(event.data.action) {
                case 'openui':
                    Kashacter.ShowUI(event.data.character);
                    break;
				case 'closeui':
					Kashacter.CloseUI();
					break;
            }
        })
    }

})();
