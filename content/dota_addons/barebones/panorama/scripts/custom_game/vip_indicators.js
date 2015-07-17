"use strict";

//GAME EVENTS
function OnShowVipLabels(event){
	$.Msg("OnShowVipLabels called. Data recieved: " + JSON.stringify(event));
	for (var i = 1; i < 6; i++) {
		if(i != event.radiant){
			$('#vip_radiant_label' + i).AddClass('hidden');
		}
		if(i != event.dire){
			$('#vip_dire_label' + i).AddClass('hidden');
		}
	};
}
GameEvents.Subscribe("show_vip_labels", OnShowVipLabels);