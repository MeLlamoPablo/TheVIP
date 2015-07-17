"use strict";

function vote(number){
	//Hide every button
	for(var i = 1; i < 6; i++){
		$('#vote' + i).AddClass('hidden');
	};
	//Show the "you have voted" message
	$('#voted').RemoveClass('hidden');

	//Send vote to the server
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
		if(typeof event[i] != 'undefined'){
			$("#vote_label" + i).text = event[i];
		}else{
			$("#vote_label" + i).text = "Waiting..."
		}
	};
}
GameEvents.Subscribe("hero_spawned", OnHeroSpawned);