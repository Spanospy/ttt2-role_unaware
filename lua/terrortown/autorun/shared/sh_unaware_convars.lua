--ConVar syncing
CreateConVar("ttt2_unaware_inform_others", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})
CreateConVar("ttt2_unaware_visible_to_traitors", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})
CreateConVar("ttt2_unaware_jam_team_comms", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})
CreateConVar("ttt2_unaware_corpse_reveal_mode", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})
CreateConVar("ttt2_unaware_convert_from_bigkill", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})
CreateConVar("ttt2_unaware_hints_enable", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})
CreateConVar("ttt2_unaware_hints_bodies", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})
CreateConVar("ttt2_unaware_hints_knife", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})
CreateConVar("ttt2_unaware_can_be_alone", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})
CreateConVar("ttt2_unaware_friendly_fire_percent", "100", {FCVAR_ARCHIVE, FCVAR_NOTFIY, FCVAR_REPLICATED})

if CLIENT then
	hook.Add("TTT2FinishedLoading", "unaware_devicon", function()
	  AddTTT2AddonDev("76561198045840138")
	end)
end


hook.Add("TTT2SyncGlobals", "AddUnawareGlobals", function()
	SetGlobalInt("ttt2_unaware_inform_others", GetConVar("ttt2_unaware_inform_others"):GetInt())
	SetGlobalInt("ttt2_unaware_visible_to_traitors", GetConVar("ttt2_unaware_visible_to_traitors"):GetInt())
	SetGlobalBool("ttt2_unaware_jam_team_comms", GetConVar("ttt2_unaware_jam_team_comms"):GetBool())
	SetGlobalInt("ttt2_unaware_corpse_reveal_mode", GetConVar("ttt2_unaware_corpse_reveal_mode"):GetInt())
	SetGlobalBool("ttt2_unaware_convert_from_bigkill", GetConVar("ttt2_unaware_convert_from_bigkill"):GetBool())
	SetGlobalBool("ttt2_unaware_hints_enable", GetConVar("ttt2_unaware_hints_enable"):GetBool())
	SetGlobalInt("ttt2_unaware_hints_bodies", GetConVar("ttt2_unaware_hints_bodies"):GetInt())
	SetGlobalBool("ttt2_unaware_hints_knife", GetConVar("ttt2_unaware_hints_knife"):GetBool())
	SetGlobalBool("ttt2_unaware_can_be_alone", GetConVar("ttt2_unaware_can_be_alone"):GetBool())
	SetGlobalInt("ttt2_unaware_friendly_fire_percent", GetConVar("ttt2_unaware_friendly_fire_percent"):GetInt())
end)


cvars.AddChangeCallback("ttt2_unaware_inform_others", function(name, old, new)
	SetGlobalInt("ttt2_unaware_inform_others", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_unaware_can_be_seen_by_traitors", function(name, old, new)
	SetGlobalInt("ttt2_unaware_can_be_seen_by_traitors", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_unaware_jam_team_comms", function(name, old, new)
	SetGlobalBool("ttt2_unaware_jam_team_comms", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_unaware_corpse_reveal_mode", function(name, old, new)
	SetGlobalInt("ttt2_unaware_corpse_reveal_mode", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_unaware_convert_from_bigkill", function(name, old, new)
	SetGlobalBool("ttt2_unaware_convert_from_bigkill", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_unaware_hints_enable", function(name, old, new)
	SetGlobalBool("ttt2_unaware_hints_enable", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_unaware_hints_bodies", function(name, old, new)
	SetGlobalInt("ttt2_unaware_hints_bodies", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_unaware_hints_knife", function(name, old, new)
	SetGlobalBool("ttt2_unaware_hints_knife", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_unaware_can_be_alone", function(name, old, new)
	SetGlobalBool("ttt2_unaware_can_be_alone", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_unaware_friendly_fire_percent", function(name, old, new)
	SetGlobalInt("ttt2_unaware_friendly_fire_percent", tonumber(new))
end)