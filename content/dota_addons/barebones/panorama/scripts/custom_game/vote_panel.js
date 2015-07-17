"use strict";

var heroes = new Array("Nothing", "No Hero", "No Hero", "No Hero", "No Hero", "No Hero");

function vote(number){
	for(var i = 1; i < 6; i++){
		$('#vote' + i).AddClass('hidden');
	};
	$('#voted').RemoveClass('hidden');

	var playerID = Players.GetLocalPlayer();
	$.Msg("Player ID " + playerID + " has voted for Hero " + number);
	GameEvents.SendCustomGameEventToServer( "player_voted", { playerID: playerID, n: number });
}

// GAME EVENTS
function OnHideHud(){
	$('#main_panel').AddClass('hidden');
	$.Msg("OnHideHud called");
}
GameEvents.Subscribe("hide_hud", OnHideHud);

function OnHeroSpawned(event){
	$.Msg("OnHeroSpawned called. Data recieved: " + JSON.stringify(event));
	for(var i = 1; i < 6; i++){
		$("#vote_label" + i).text = event[i];
	};
}
GameEvents.Subscribe("hero_spawned", OnHeroSpawned);