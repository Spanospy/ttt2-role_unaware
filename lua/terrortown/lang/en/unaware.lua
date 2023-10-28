L = LANG.GetLanguageTableReference("english")

-- GENERAL ROLE LANGUAGE STRINGS
L[UNAWARE.name] = "Unaware"
L["info_popup_" .. UNAWARE.name .. "_alone"] = [[
    THIS TEXT SHOULD NEVER SHOW UP. Please report it to Spanospy!]]
L["info_popup_" .. UNAWARE.name] = [[
    THIS TEXT SHOULD NEVER SHOW UP. Please report it to Spanospy!]]
L["body_found_" .. UNAWARE.abbr] = "They were Unaware!"
L["search_role_" .. UNAWARE.abbr] = "This person was Unaware!"
L["target_" .. UNAWARE.name] = "Unaware"
L["ttt2_desc_" .. UNAWARE.name] = [[The Unaware is a Traitor who is not told they're one.
It is up to the other traitors to spot this and communicate to them their true role.]]

--SETTINGS STRINGS
L["label_ttt2_unaware_inform_others"] = "Warn players if there's an Unaware at start of round"
L["option_ttt2_unaware_inform_others_0"] = "No"
L["option_ttt2_unaware_inform_others_1"] = "Warn Traitors only"
L["option_ttt2_unaware_inform_others_2"] = "Warn all players"

L["label_ttt2_unaware_visible_to_traitors"] = "Role that Traitors see Unawares as"
L["option_ttt2_unaware_visible_to_traitors_0"] = "None"
L["option_ttt2_unaware_visible_to_traitors_1"] = "Traitor"
L["option_ttt2_unaware_visible_to_traitors_2"] = "Unaware"

L["label_ttt2_unaware_jam_team_comms"] = "Block Traitor communication while an Unaware is alive"

L["label_ttt2_unaware_corpse_reveal_mode"] = "Role that Unawares will be confirmed as"
L["option_ttt2_unaware_corpse_reveal_mode_0"] = "Innocent"
L["option_ttt2_unaware_corpse_reveal_mode_1"] = "Traitor"
L["option_ttt2_unaware_corpse_reveal_mode_2"] = "Unaware"

L["label_ttt2_unaware_hints_enable"] = "Unawares can receive hints to their 'True Role'"

L["label_ttt2_unaware_hints_bodies"] = "(UNFINISHED) Hints can be found by inspecting bodies"
L["option_ttt2_unaware_hints_bodies_0"] = "No"
L["option_ttt2_unaware_hints_bodies_1"] = "On bodies with Traitor DNA"
L["option_ttt2_unaware_hints_bodies_2"] = "On Traitor bodies"
L["option_ttt2_unaware_hints_bodies_3"] = "On Traitor bodies and bodies with Traitor DNA"

L["label_ttt2_unaware_hints_knife"] = "Spawn a knife on the map for each Unaware to find"
L["label_ttt2_unaware_hints_knife_fakebuy"] = "Unawares fake a purchase when they pick up their knife"

L["label_ttt2_unaware_can_be_alone"] = "(UNFINISHED) Unawares can be the only Traitors at start"

L["label_ttt2_unaware_is_extra"] = "Increase number of traitors for every Unaware"

L["label_ttt2_unaware_is_counted_as_inno"] = "[Round Info addon] - Unawares contribute towards Innocent count instead of Traitors"

L["label_ttt2_unaware_friendly_fire_percent"] = "Percentage of damage dealt to / received from Traitors"

L["label_ttt2_unaware_last_traitor_mode"] = "If Unawares are the only traitors left: "
L["option_ttt2_unaware_last_traitor_mode_0"] = "Do nothing"
L["option_ttt2_unaware_last_traitor_mode_1"] = "Unawares turn into Innocents"
L["option_ttt2_unaware_last_traitor_mode_2"] = "Unawares turn into Traitors"

L["label_ttt2_unaware_convert_from_bigkill"] = "Unawares turn into Traitors after killing high-value players (eg: Detectives)"
L["label_ttt2_unaware_convert_from_kills"] = "(UNFINISHED) Unawares turn into traitors after killing this many innocents: "

-- OTHER ROLE LANGUAGE STRINGS
L["inform_everyone_unaware"] = "Someone is unaware they're a traitor!"
L["inform_traitors_unaware"] = [[One of your comrades is unaware they're a traitor. 
Help them out by letting them know their role!]]

L["inform_unaware"] = "You've realised your true role!"

L["ttt2_teamchat_jammed_" .. UNAWARE.name] = "You cannot use the team text chat whilst a Traitor is unaware!"
L["ttt2_teamvoice_jammed_" .. UNAWARE.name] = "You cannot use the team voice chat whilst a Traitor is unaware!"

L["unaware_hint_traitor_body"] = "There's a note with your name on it: \"{flavor}\""

L["unaware_hint_traitor_dna"] = "The killer left a note for you: \"{flavor}\""

L["Unaware_hint_flavor_0"] = "Finish the job."
L["Unaware_hint_flavor_1"] = "Don't forget."
L["Unaware_hint_flavor_2"] = "You owe me."
L["Unaware_hint_flavor_3"] = "Do not let us down."
L["Unaware_hint_flavor_4"] = "You can stop playing around now."