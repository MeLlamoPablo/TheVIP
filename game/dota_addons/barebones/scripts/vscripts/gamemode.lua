-- This is the primary barebones gamemode script and should be used to assist in initializing your game mode


-- Set this to true if you want to see a complete debug output of all events/processes done by barebones
-- You can also change the cvar 'barebones_spew' at any time to 1 or 0 for output/no output
BAREBONES_DEBUG_SPEW = true 

if GameMode == nil then
    DebugPrint( '[BAREBONES] creating barebones game mode')
    _G.GameMode = class({})
end

require('dotaHeroes')
-- This library allow for easily delayed/timed actions
require('libraries/timers')
-- This library can be used for advancted physics/motion/collision of units.  See PhysicsReadme.txt for more information.
require('libraries/physics')
-- This library can be used for advanced 3D projectile systems.
require('libraries/projectiles')
-- This library can be used for sending panorama notifications to the UIs of players/teams/everyone
require('libraries/notifications')
-- This library can be used for starting customized animations on units from lua
require('libraries/animations')

-- These internal libraries set up barebones's events and processes.  Feel free to inspect them/change them if you need to.
require('internal/gamemode')
require('internal/events')

-- settings.lua is where you can specify many different properties for your game mode and is one of the core barebones files.
require('settings')
-- events.lua is where you can specify the actions to be taken when any event occurs and is one of the core barebones files.
require('events')

-- Panorama listeners
CustomGameEventManager:RegisterListener("player_voted", Dynamic_Wrap(GameMode, 'OnPlayerVoted'))


--[[
  This function should be used to set up Async precache calls at the beginning of the gameplay.

  In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
  after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
  be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will 
  precache the precache{} block statement of the unit and all precache{} block statements for every Ability# 
  defined on the unit.

  This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
  time, you can call the functions individually (for example if you want to precache units in a new wave of
  holdout).

  This function should generally only be used if the Precache() function in addon_game_mode.lua is not working.
]]
function GameMode:PostLoadPrecache()
  DebugPrint("[BAREBONES] Performing Post-Load precache")    
  --PrecacheItemByNameAsync("item_example_item", function(...) end)
  --PrecacheItemByNameAsync("example_ability", function(...) end)

  --PrecacheUnitByNameAsync("npc_dota_hero_viper", function(...) end)
  --PrecacheUnitByNameAsync("npc_dota_hero_enigma", function(...) end)
end

--[[
  This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
  It can be used to initialize state that isn't initializeable in InitGameMode() but needs to be done before everyone loads in.
]]
function GameMode:OnFirstPlayerLoaded()
  DebugPrint("[BAREBONES] First Player has loaded")
end

--[[
  This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
  It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function GameMode:OnAllPlayersLoaded()
  DebugPrint("[BAREBONES] All Players have loaded into the game")
end

--[[
  This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
  if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
  levels, changing the starting gold, removing/adding abilities, adding physics, etc.

  The hero parameter is the hero entity that just spawned in
]]
radiantPlayers = {}
direPlayers = {}
radiantPlayersHeroNames = {}
direPlayersHeroNames = {}
radiantPlayersVotes = {}
direPlayersVotes = {}
function GameMode:OnHeroInGame(hero)
  DebugPrint("[BAREBONES] Hero spawned in game for first time -- " .. hero:GetUnitName() .. " and his Player ID is " .. hero:GetPlayerID())

  -- Get the player's info
  local playerID = hero:GetPlayerID()
  local player = PlayerResource:GetPlayer(playerID)
  local teamNumber = player:GetTeam()

  -- radiant/direPlayers = Stores the spawned hero's owner's id (value) along with the ID to be sent to the client (key) for later to know who's being voted.
  -- radiant/direPlayersVotes = Stores the number of votes (value) along with the ID to be sent to the client (key) for later to decide who's the VIP
  -- radiant/direPlayersHeroNames = Stores the "beautiful" hero name (value) along with the ID to be sent to the client (key) for the client to put these names on the vote buttons.
  if(teamNumber == DOTA_TEAM_GOODGUYS) then
    radiantPlayers[#radiantPlayers+1] = playerID
    radiantPlayersVotes[#radiantPlayers] = 0
    radiantPlayersHeroNames[#radiantPlayers] = dotaHeroes[hero:GetUnitName()]

    CustomGameEventManager:Send_ServerToTeam(teamNumber, "hero_spawned", radiantPlayersHeroNames)
  else if(teamNumber == DOTA_TEAM_BADGUYS) then
    direPlayers[#direPlayers+1] = playerID
    direPlayersVotes[#direPlayers] = 0
    direPlayersHeroNames[#direPlayers] = dotaHeroes[hero:GetUnitName()]

    CustomGameEventManager:Send_ServerToTeam(teamNumber, "hero_spawned", direPlayersHeroNames)
  end
  end -- I messed up something because two ends are needed here. If one is removed, an error will be caused :S

  -- This line for example will set the starting gold of every hero to 650 unreliable gold
  --hero:SetGold(650, false)

end

function GameMode:OnPlayerVoted(event)
  local votingPlayerID = event.playerID
  local votingPlayer = PlayerResource:GetPlayer(votingPlayerID)
  local votingPlayerTeam = votingPlayer:GetTeam()

  if(votingPlayerTeam == DOTA_TEAM_GOODGUYS) then
    if radiantPlayers[event.n] ~= nil then
      radiantPlayersVotes[event.n] = radiantPlayersVotes[event.n] + 1
    end
  else if(votingPlayerTeam == DOTA_TEAM_BADGUYS) then
    if direPlayers[event.n] ~= nil then
      direPlayersVotes[event.n] = direPlayersVotes[event.n] + 1
    end
  end
  end
end

--[[
  This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
  gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
  is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
radiantVIP = nil
direVIP = nil
function GameMode:OnGameInProgress()
  DebugPrint("[BAREBONES] The game has officially begun")

  --Choose the radiant VIP
  local max = radiantPlayersVotes[1]
  local maxKey = 1

  for i=1, #radiantPlayers do
    if radiantPlayersVotes[i] > max then
      max = radiantPlayersVotes[i]
      maxKey = i
    end
  end

  radiantVIP = PlayerResource:GetPlayer(radiantPlayers[maxKey])

  --Choose the dire VIP
  max = direPlayersVotes[1]
  maxKey = 1

  for i=1, #direPlayers do
    if direPlayersVotes[i] > max then
      max = direPlayersVotes[i]
      maxKey = i
    end
  end

  local direVIPKey
  if max == nil then
    direVIP = radiantVIP -- for testing purposes, where only one player in radiant loads
  else
    direVIP = PlayerResource:GetPlayer(direPlayers[maxKey])
  end  

  -- Notify the players who the VIPs are
  Notifications:TopToAll({text="The Radiant VIP is " .. dotaHeroes[radiantVIP:GetAssignedHero():GetUnitName()], duration=10, style={color="green"}})
  Notifications:TopToAll({text="The Dire VIP is "  .. dotaHeroes[direVIP:GetAssignedHero():GetUnitName()], duration=10, style={color="red"}})
  Notifications:TopToAll({text="GLHF!", duration=10})

  -- Hide the voting HUD from every player
  local event_data = nil
  CustomGameEventManager:Send_ServerToAllClients("hide_hud", event_data)

  -- Send VIP data to the clients to show VIP labels
  -- In order to do this, we must not send the maxKey values (spawn order), because the Dota HUD doesn't display players in spawn order, but in connect order. In order to do this, we use PlayerResource:GetNthPlayerIDOnTeam(teamNumber, Nth)
  -- This function isn't too well documented (yet, hopefully). You give it a team number and a position number, and it returns the player ID of the player in that position, in that team. For instance, if the HUD shows Tinker first, then Furion on the radiant side:
  -- PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, 2) will return the Player ID of the player who controls Furion
  local radiantVIPPosition
  local direVIPPosition
  for i=1, #radiantPlayers do
    if PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, i) == radiantVIP:GetPlayerID() then
      radiantVIPPosition = i
    end
  end
  for i=1, #direPlayers do
    if PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_BADGUYS, i) == direVIP:GetPlayerID() then
      direVIPPosition = i
    end
  end

  event_data = {
    radiant = radiantVIPPosition,
    dire = direVIPPosition
  }
  CustomGameEventManager:Send_ServerToAllClients("show_vip_labels", event_data)

  Timers:CreateTimer(30, -- Start this timer 30 game-time seconds later
    function()
      DebugPrint("This function is called 30 seconds after the game begins, and every 30 seconds thereafter")
      return 30.0 -- Rerun this timer every 30 game-time seconds 
    end)
end



-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function GameMode:InitGameMode()
  GameMode = self
  DebugPrint('[BAREBONES] Starting to load Barebones gamemode...')

  -- Call the internal function to set up the rules/behaviors specified in constants.lua
  -- This also sets up event hooks for all event handlers in events.lua
  -- Check out internals/gamemode to see/modify the exact code
  GameMode:_InitGameMode()

  -- Commands can be registered for debugging purposes or as functions that can be called by the custom Scaleform UI
  Convars:RegisterCommand( "command_example", Dynamic_Wrap(GameMode, 'ExampleConsoleCommand'), "A console command example", FCVAR_CHEAT )

  DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')
end

-- This is an example console command
function GameMode:ExampleConsoleCommand()
  print( '******* Example Console Command ***************' )
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      -- Do something here for the player who called this command
      PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_viper", 1000, 1000)
    end
  end

  print( '*********************************************' )
end