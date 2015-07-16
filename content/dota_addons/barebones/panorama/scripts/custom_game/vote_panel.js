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
GameEvents.Subscribe("hide_hud", OnHideHud);
function OnHideHud(){
	$('#main_panel').AddClass('hidden');
	$.Msg("OnHideHud called");
}

GameEvents.Subscribe("hero_spawned", OnHeroSpawned);
function OnHeroSpawned(event){
	$("#vote_label" + event.id).text = event.hero;
	$.Msg("OnHeroSpawned called: ID is " + event.id + " and hero is " + event.hero)
}