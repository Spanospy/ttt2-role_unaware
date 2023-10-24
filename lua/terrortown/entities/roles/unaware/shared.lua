--TODOS:
--# Implement all convars
--# Look into edge cases, eg if a traitor tries to transfer credits to an unaware
--# Prevent Unawares from being told via mstack who the jester/swapper is.
--# Ideas for other role hints?


if SERVER then
    AddCSLuaFile()
	util.AddNetworkString("TTT2UnawareNotify")
	util.AddNetworkString("TTT2UnawareConvertNetMsg")
	util.AddNetworkString("TTT2UnawareResetNetMsg")
end

function ROLE:PreInitialize()
	--Innocent's colour:
	--self.color                    = Color(80, 173, 59, 255)
	--Unaware's colour:
	self.color                      = Color(173, 80, 59, 255)

	self.abbr                       = "unaware"
	self.surviveBonus               = 0
	self.score.killsMultiplier      = 4
	self.score.teamKillsMultiplier  = -5
	self.preventFindCredits         = true
	self.preventKillCredits         = true
	self.preventTraitorAloneCredits = true
	self.preventWin                 = false
	self.unknownTeam                = true
	self.disableSync                = true
	--self.disabledTeamChat           = true
	--self.disabledTeamChatRecv       = true
	--self.disabledTeamVoice          = true
	--self.disabledTeamVoiceRecv      = true
	--self.visibleForTeam             = {TEAM_TRAITOR}

	self.defaultEquipment           = INNO_EQUIPMENT
	self.defaultTeam                = TEAM_TRAITOR
	self.conVarData = {
		pct          = 0.15, -- necessary: percentage of getting this role selected (per player)
		maximum      = 1, -- maximum amount of roles in a round
		minPlayers   = 7, -- minimum amount of players until this role is able to get selected
		credits      = 0, -- the starting credits of a specific role
		togglable    = true, -- option to toggle a role for a client if possible (F1 menu)
		shopFallback = SHOP_FALLBACK_TRAITOR,
		random       = 15
	}
end

function ROLE:Initialize()
	roles.SetBaseRole(self, ROLE_TRAITOR)
end

local function GetUnawareConvarLookups()

	local ConvarRoles = {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_UNAWARE}
	local ConvarTeams = {TEAM_INNOCENT, TEAM_TRAITOR, TEAM_TRAITOR}
	local ConvarColors = {INNOCENT.color, TRAITOR.color, UNAWARE.color}

	return {roles = ConvarRoles, teams = ConvarTeams, colors = ConvarColors}
end

local function FakeBuyKnife(ply, knife, is_item, traitors)

	if ply.fake_brought_knife then return end
	ply.fake_brought_knife = true

	net.Start("TEBN_ItemBought")
	net.WriteEntity(ply)
	net.WriteString(knife)
	net.WriteBool(is_item)
	net.Send(traitors)
end

local function CheckKillForPromotion(victim, infl, attacker)

	if not (IsValid(attacker) and attacker:IsPlayer()) then return end

	if attacker:GetSubRole() ~= ROLE_UNAWARE then return end
	if attacker.is_aware then return end

	local roleDataAttacker = attacker:GetSubRoleData()
	local roleDataVictim = victim:GetSubRoleData()

	local convertFromBigKill = GetConVar("ttt2_unaware_convert_from_bigkill"):GetBool()
	local convertFromKills = GetConVar("ttt2_unaware_convert_from_kills"):GetInt()

	if convertFromBigKill and roleDataVictim.isPublicRole and roleDataVictim.defaultTeam == TEAM_INNOCENT then
		ConvertUnaware(attacker, true)
		SendFullStateUpdate()
	elseif convertFromKills then
		--TODO
	end

end

local function CheckIfLastTraitorDied(victim, infl, attacker)
	print("LastTraitorTriggered")
	if not (IsValid(victim) and victim:IsPlayer()) then return end
	if victim:GetSubRole() == ROLE_UNAWARE then return end --An Unaware doesn't count
	if victim:GetTeam() == TEAM_TRAITOR then
		print("Person who died is a traitor, are any others alive?")
		--Check how many non-unaware traitors are still alive
		--If it's zero, read what the convar has to say and convert Unawares appropriately

		local plys = player.GetAll()
		local unawares = {}
		local traitorLives = false

		for _, ply in ipairs(plys) do

			local rle = ply:GetSubRole()

			if rle == ROLE_UNAWARE and ply:Alive() then
				table.insert(unawares, ply)
			end

			if traitorLives == false and rle ~= ROLE_UNAWARE and ply:GetTeam() == TEAM_TRAITOR and ply ~= victim and ply:Alive() then
				print("Yep.",ply:Nick())
				traitorLives = true
			end

		end

		local convertFromDeath = GetConVar("ttt2_unaware_last_traitor_mode"):GetInt()

		if traitorLives == false and convertFromDeath > 0 then
			print("Nope, Setting timer")
			timer.Simple(3, function() --Timer to avoid race conditions

				for _, unaware in pairs(unawares) do
					ConvertUnaware(unaware, convertFromDeath - 1)
				end
				SendFullStateUpdate()

			end)
		end
	end
end

function ConvertUnaware(ply, convertToTraitor)

	--Don't do anything if the player has already been converted
	if ply.is_aware then return end

	--If we're converting to innocent, just change their team.
	if not convertToTraitor then
		ply:UpdateTeam(TEAM_INNOCENT)
	else
		--If we're converting to traitor, try to just change things on their client to see themselves as a traitor. (ie ply.is_aware = true)
		ply.is_aware = true
		--Also, give them credits if they start with none.
		if(GetConVar("ttt_unaware_credits_starting"):GetInt() == 0) then 
			ply:AddCredits(GetConVar("ttt_traitor_credits_starting"):GetInt()) 
		end
		net.Start('TTT2UnawareConvertNetMsg')
		net.Send(ply)
		timer.Simple(1, function()
			LANG.Msg(ply, "inform_unaware", nil, MSG_MSTACK_ROLE)
		end)
	end
	ply:ResetConfirmPlayer()
end

if SERVER then

	--Global variables
	local GV_UnawareDistribution = 0

	hook.Add("TTTPrepareRound", "UnawarePrepareRound", function()

		roles.GetByIndex(ROLE_UNAWARE).isOmniscientRole = false
		roles.GetByIndex(ROLE_UNAWARE).unknownTeam = true

		for _, unaware in ipairs(player.GetAll()) do
			unaware.ttt2_unaware = false
			unaware.is_aware = false
		end

		net.Start('TTT2UnawareResetNetMsg')
		net.Broadcast()
		
	end)


	hook.Add("TTTBeginRound", "UnawareBeginRound", function()

		--Ironically, We need to tell clients if they're an Unaware in order for some client-sided behaviour to work.
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetSubRole() == ROLE_UNAWARE then
				net.Start("TTT2UnawareNotify")
				net.WriteBool(true)
				net.Send(ply)
				ply.ttt2_unaware = true
			end
		end

		--Tell players that there's an unaware, if applicable.
		local inform_mode = GetConVar("ttt2_unaware_inform_others"):GetInt()

		if inform_mode > 0 then 

			local plys = player.GetAll()
			local UnawareInPlay = false
			
			--Check an unaware is in play
			for _, ply in ipairs(plys) do
				local rle = ply:GetSubRole()

				if rle == ROLE_UNAWARE and ply:Alive() then
					UnawareInPlay = true
					break
				end
			end

			if UnawareInPlay == true then
				for _, ply in ipairs(plys) do

					if inform_mode >= 1 and ply:GetTeam() == TEAM_TRAITOR and ply:GetSubRole() ~= ROLE_UNAWARE then
						LANG.Msg(ply, "inform_traitors_unaware", nil, MSG_MSTACK_WARN)
					elseif inform_mode >= 2 then
						LANG.Msg(ply, "inform_everyone_unaware", nil, MSG_MSTACK_WARN)
					end
	
				end
			end
		
		end

		

	end)

	hook.Add("TTT2ModifyFinalRoles", "TTT2UnawareContribution", function(finalroles)

		if GetConVar("ttt2_unaware_is_extra"):GetBool() == false then return end

		--Stores the indexes of all innocents for later, potentially
		local innocents = {}

		GV_UnawareDistribution = 0

		print("Final role count:")
		local rlekeys = table.GetKeys(finalroles)
		print(#rlekeys)

		for ply, rle in pairs(finalroles) do

			print("ply: ",ply,"| Role: ",rle)

			if rle == ROLE_UNAWARE then
				print("+1 to Unawares")
				GV_UnawareDistribution = GV_UnawareDistribution + 1
			end

			if rle == ROLE_INNOCENT then
				print("+1 to Innocents")
				table.insert(innocents, ply)
			end
		end
		print("Done checking roles.")

		if GV_UnawareDistribution > 0 then
			print("Re-rolls required.")
			--For each Unaware, re-roll one of the innocents into a plain traitor.
			for i=1, GV_UnawareDistribution do
				print("Attempting re-roll")
				if #innocents then
					local ino = math.random(#innocents)
					finalroles[innocents[ino]] = ROLE_TRAITOR
					table.remove(innocents, ino)
				end
			end
		end
		print("End.")
	end)

	hook.Add("TTTAModifyRolesTable", "TTTAUnawareRoundInfo", function(rls, printrls)

		print("Modify role count?")

		if GetConVar("ttt2_unaware_is_counted_as_inno"):GetBool() == true then 
			print("Yep. # of unawares:",GV_UnawareDistribution)
			rls[ROLE_TRAITOR] = rls[ROLE_TRAITOR] - GV_UnawareDistribution
			rls[ROLE_INNOCENT] = rls[ROLE_INNOCENT] + GV_UnawareDistribution
		end
		
	end)

	hook.Add("TTT2TellTraitors", "TTT2UnawareHideTraitorMessage", function(traitornicks, ply)

		if ply:GetSubRole() ~= ROLE_UNAWARE then
			local visible_to_traitors = GetConVar("ttt2_unaware_visible_to_traitors"):GetInt()
			if visible_to_traitors == 0 then
				local plys = player.GetAll()
				for i = 1, #plys do
					local v = plys[i]
					if v:GetSubRole() == ROLE_UNAWARE then
						for i = 1, #traitornicks do
							if traitornicks[i] == v:Nick() then 
								table.remove(traitornicks, i) 
							end
						end
					end
				end
			end

			return true

		end

		--Prevent the Unaware being told who the traitors are
		return false

	end)

	hook.Add("TTT2JesterShouldShow","TTT2UnawareDontShowJester", function(ply)
		if ply:GetSubRole() ~= ROLE_UNAWARE then return end
		return false
	end)

	hook.Add("PlayerTakeDamage", "UnawareTeamDamage", function(ply, inflictor, killer, amount, dmginfo)

		if not IsValid(ply) or not IsValid(attacker) or not attacker:IsPlayer() then return end
		if SpecDM and (ply.IsGhost and ply:IsGhost() or (attacker.IsGhost and attacker:IsGhost())) then return end


		if (inflictor:GetSubRole() == ROLE_UNAWARE and ply:GetTeam() == TEAM_TRAITOR) or (inflictor:GetTeam() == TEAM_TRAITOR and ply:GetSubRole() == ROLE_UNAWARE) then
			local dmult = GetConVar("ttt2_unaware_friendly_fire_percent"):GetInt()
			dmginfo:ScaleDamage(0.01 * dmult)
		end
	end)

	hook.Add("TTT2CanSeeChat","TTT2UnawareTeamChat", function(text, teamOnly, listener, sender)
		if listener:GetSubRole() ~= ROLE_UNAWARE then return end
		if teamOnly and sender:GetTeam() == TEAM_TRAITOR then
			if listener.is_aware then return true
			else return false end
		end
	end)



	hook.Add("TTT2ModifyRadarRole", "TTT2UnawareModifyRadarRole", function(ply, target)
		local visible_to_traitors = GetConVar("ttt2_unaware_visible_to_traitors"):GetInt()
		if visible_to_traitors == 0 then
			if ply:GetTeam() == TEAM_TRAITOR and target:GetSubRole() == ROLE_UNAWARE and not ply.is_aware then
				return ROLE_INNOCENT, TEAM_INNOCENT
			end
		end
	end)

	hook.Add("TTT2AvoidTeamChat", "TTT2UnawareJamTraitorChat", function(sender, tm, msg)
		if GetConVar("ttt2_unaware_jam_team_comms"):GetBool() == false then return end
		if tm == TEAM_TRAITOR then
			for _, unaware in ipairs(player.GetAll()) do
				if unaware:IsTerror() and unaware:Alive() and unaware:GetSubRole() == ROLE_UNAWARE and not unaware.is_aware then
					LANG.Msg(sender, "ttt2_teamchat_jammed_" .. UNAWARE.name, nil, MSG_CHAT_WARN)

					return false
				end
			end
		end
	end)

	hook.Add("TTT2CanUseVoiceChat", "TTT2UnawareJamTraitorVoice", function(speaker, isTeamVoice)

		if GetConVar("ttt2_unaware_jam_team_comms"):GetBool() == false then return end

		-- only jam traitor team voice
		if not isTeamVoice or not IsValid(speaker) or speaker:GetTeam() ~= TEAM_TRAITOR then return end

		-- ToDo prevent team voice overlay from showing on the speaking players screen
		for _, unaware in ipairs(player.GetAll()) do
			if unaware:IsTerror() and unaware:Alive() and unaware:GetSubRole() == ROLE_UNAWARE and not unaware.is_aware then
				LANG.Msg(speaker, "ttt2_teamvoice_jammed_" .. UNAWARE.name , nil, MSG_CHAT_WARN)
				return false
			end
		end
	end)

	hook.Add("TTTCanSearchCorpse", "TTT2UnawareChangeCorpse", function(ply, corpse)

		if corpse and corpse.was_role == ROLE_UNAWARE then
			local corpse_convar = GetConVar("ttt2_unaware_corpse_reveal_mode"):GetInt() + 1
			local convar_ref = GetUnawareConvarLookups()
			corpse.was_role = convar_ref.roles[corpse_convar]
			corpse.was_team = convar_ref.teams[corpse_convar]
			corpse.role_color = convar_ref.colors[corpse_convar]
			corpse.is_unaware_corpse = true
		end
	end)

	hook.Add("TTT2ConfirmPlayer", "TTT2UnawareConfirm", function(confirmed, finder, corpse)

		if IsValid(confirmed) and corpse and corpse.is_unaware_corpse then
			confirmed:ConfirmPlayer(true)
			local corpse_convar = GetConVar("ttt2_unaware_corpse_reveal_mode"):GetInt() + 1
			local convar_ref = GetUnawareConvarLookups()
			SendRoleListMessage(convar_ref.roles[corpse_convar], convar_ref.teams[corpse_convar], {confirmed:EntIndex()})
			corpse.was_role = convar_ref.roles[corpse_convar]
			events.Trigger(EVENT_BODYFOUND, finder, corpse)
			return false
		end
	end)




	hook.Add("TTT2UpdateSubrole", "UnawareUpdateSubrole", function(ply, oldSubrole, subrole)
		
		if GetRoundState() ~= ROUND_ACTIVE then
			return
		end

		--If they are no longer an Unaware, tell the client that.
		if oldSubrole == ROLE_UNAWARE and subrole ~= ROLE_UNAWARE then
			net.Start("TTT2UnawareNotify")
			net.WriteBool(false)
			net.Send(ply)
			ply.ttt2_unaware = false
		end

	end)

	hook.Add("TTT2SpecialRoleSyncing", "TTT2UnawareDisplayRole", function(ply, tbl)

		--How Unawares see players (including themself)
		if ply:GetSubRole() == ROLE_UNAWARE then
			for ply_i in pairs(tbl) do
				if ply == ply_i then
					if ply.is_aware then
						tbl[ply_i] = {ROLE_TRAITOR, TEAM_TRAITOR}
					else
						tbl[ply_i] = {ROLE_INNOCENT, TEAM_INNOCENT}
					end
				elseif ply_i:GetTeam() == TEAM_TRAITOR then
					if ply.is_aware then
						tbl[ply_i] = {ROLE_TRAITOR, TEAM_TRAITOR}
					else
						tbl[ply_i] = {ROLE_NONE, TEAM_NONE}
					end
				end
			end

		--How Traitors see Unawares
		elseif ply:GetTeam() == TEAM_TRAITOR then
			for ply_i in pairs(tbl) do
				if ply_i:GetSubRole() == ROLE_UNAWARE then
					local visible = GetConVar("ttt2_unaware_visible_to_traitors"):GetInt() + 1
					local visible_role = {ROLE_NONE, ROLE_TRAITOR, ROLE_UNAWARE}
					local visible_team = {TEAM_NONE, TEAM_TRAITOR, TEAM_TRAITOR}
					tbl[ply_i] = {visible_role[visible], visible_team[visible]}
				end
			end
		end
	end)

	hook.Add("TTT2JesterModifySyncedRole", "TTT2UnawareJesterSync", function(ply, syncPly)
		if ply:GetSubRole() == ROLE_UNAWARE then
			if ply.is_aware then
				return {ROLE_JESTER, TEAM_JESTER}
			else
				return {ROLE_NONE, TEAM_NONE}
			end
		end
	end)

	hook.Add("PlayerCanPickupWeapon", "TTT2UnawareKnifeCanPickup", function(ply, wep, dropBlockingWeapon, isPickupProbe)

		if WEPS.GetClass(wep) ~= "ttt_unaware_knife_pickup" then return end

		if ply == wep.unaware then

			--fake-buy a real knife instead and remove the wep
			--TODO convar for whether picking up the knife fakes a buy alert

			local traitors = {}
			for _, ply in ipairs(player.GetAll()) do
				if ply:IsActive() and ply:GetTeam() == TEAM_TRAITOR and ply:GetSubRole() ~= ROLE_UNAWARE then
					traitors[#traitors + 1] = ply
				end
			end
			local knife = "weapon_ttt_knife"
			local is_item = items.IsItem(knife)

			FakeBuyKnife(ply, knife, is_item, traitors)


			ply:GiveEquipmentWeapon(knife)
			wep:Remove()

			return false
		end

		return false

	end)

	hook.Add("PlayerDeath", "UnawareDeathCheck", function(victim, infl, attacker)

		local convertFromBigKill = GetConVar("ttt2_unaware_convert_from_bigkill"):GetBool()
		local convertFromKills = GetConVar("ttt2_unaware_convert_from_kills"):GetInt()
		local convertFromDeath = GetConVar("ttt2_unaware_last_traitor_mode"):GetInt()

		if convertEnabled == false and convertFromDeath == 0 then return end

		if not IsValid(victim) then return end

		if convertFromBigKill or convertFromKills > 0 then
			CheckKillForPromotion(victim, infl, attacker)
		end

		if convertFromDeath then
			CheckIfLastTraitorDied(victim, infl, attacker)
		end

	end)

--	hook.Add("TTTKarmaGivePenalty", "TTT2UnawareTeamkillKarma", function(ply, penalty, victim)
--
--		if ply:GetSubRole == ROLE_UNAWARE and victim:GetTeam == TEAM_TRAITOR then return end
--
--		if ply:GetTeam == TEAM_TRAITOR and victim:GetSubRole == ROLE_UNAWARE then
--			local visible = GetConVar("ttt2_unaware_visible_to_traitors"):GetInt()
--			if visible == 0 then return false end
--		end
--	end)

end



if CLIENT then

	function ROLE:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_roles_additional")
	
		form:MakeComboBox({
			serverConvar = "ttt2_unaware_inform_others",
			label = "label_ttt2_unaware_inform_others",
			choices = {
				{value = "0", title = LANG.GetTranslation("option_ttt2_unaware_inform_others_0")},
				{value = "1", title = LANG.GetTranslation("option_ttt2_unaware_inform_others_1")},
				{value = "2", title = LANG.GetTranslation("option_ttt2_unaware_inform_others_2")}
			}
		})

		form:MakeComboBox({
			serverConvar = "ttt2_unaware_visible_to_traitors",
			label = "label_ttt2_unaware_visible_to_traitors",
			choices = {
				{value = "0", title = LANG.GetTranslation("option_ttt2_unaware_visible_to_traitors_0")},
				{value = "1", title = LANG.GetTranslation("option_ttt2_unaware_visible_to_traitors_1")},
				{value = "2", title = LANG.GetTranslation("option_ttt2_unaware_visible_to_traitors_2")}
			}
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_unaware_jam_team_comms",
			label = "label_ttt2_unaware_jam_team_comms"
		})

		form:MakeComboBox({
			serverConvar = "ttt2_unaware_corpse_reveal_mode",
			label = "label_ttt2_unaware_corpse_reveal_mode",
			choices = {
				{value = "0", title = LANG.GetTranslation("option_ttt2_unaware_corpse_reveal_mode_0")},
				{value = "1", title = LANG.GetTranslation("option_ttt2_unaware_corpse_reveal_mode_1")},
				{value = "2", title = LANG.GetTranslation("option_ttt2_unaware_corpse_reveal_mode_2")}
			}
		})

		--form:MakeHelp({
		--	label = "ttt2_unaware_convert_desc"
		--})

		local hintMaster

		hintMaster = form:MakeCheckBox({
			serverConvar = "ttt2_unaware_hints_enable",
			label = "label_ttt2_unaware_hints_enable"
		})

		form:MakeComboBox({
			serverConvar = "ttt2_unaware_hints_bodies",
			label = "label_ttt2_unaware_hints_bodies",
			choices = {
				{value = "0", title = LANG.GetTranslation("option_ttt2_unaware_hints_bodies_0")},
				{value = "1", title = LANG.GetTranslation("option_ttt2_unaware_hints_bodies_1")},
				{value = "2", title = LANG.GetTranslation("option_ttt2_unaware_hints_bodies_2")},
				{value = "3", title = LANG.GetTranslation("option_ttt2_unaware_hints_bodies_3")}
			},
			master = hintMaster
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_unaware_hints_knife",
			label = "label_ttt2_unaware_hints_knife",
			master = hintMaster
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_unaware_can_be_alone",
			label = "label_ttt2_unaware_can_be_alone"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_unaware_is_extra",
			label = "label_ttt2_unaware_is_extra"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_unaware_is_counted_as_inno",
			label = "label_ttt2_unaware_is_counted_as_inno"
		})

		form:MakeSlider({
			serverConvar = "ttt2_unaware_friendly_fire_percent",
			label = "label_ttt2_unaware_friendly_fire_percent",
			min = 0,
			max = 100,
			decimal = 0
		})

		form:MakeComboBox({
			serverConvar = "ttt2_unaware_last_traitor_mode",
			label = "label_ttt2_unaware_last_traitor_mode",
			choices = {
				{value = "0", title = LANG.GetTranslation("option_ttt2_unaware_last_traitor_mode_0")},
				{value = "1", title = LANG.GetTranslation("option_ttt2_unaware_last_traitor_mode_1")},
				{value = "2", title = LANG.GetTranslation("option_ttt2_unaware_last_traitor_mode_2")}
			}
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_unaware_convert_from_bigkill",
			label = "label_ttt2_unaware_convert_from_bigkill"
		})

	end

	hook.Add("TTT2FinishedLoading", "unaware_devicon", function()
		AddTTT2AddonDev("76561198045840138")
	end)

	net.Receive("TTT2UnawareNotify", function()
		--EPOP:AddMessage({text = "DEBUG: You're unaware!", color = UNAWARE.color}, "", 6)
		LocalPlayer().ttt2_unaware = true
	end)

	-- Set 'true role' flags for Client
	net.Receive('TTT2UnawareConvertNetMsg', function()
		roles.GetByIndex(ROLE_UNAWARE).isOmniscientRole = true
		roles.GetByIndex(ROLE_UNAWARE).unknownTeam = false
		LocalPlayer().is_aware = true
	end)

	-- Reset 'true role' flags for Client
	net.Receive('TTT2UnawareResetNetMsg', function()
		roles.GetByIndex(ROLE_UNAWARE).isOmniscientRole = false
		roles.GetByIndex(ROLE_UNAWARE).unknownTeam = true

		local lply = LocalPlayer()
		lply.ttt2_unaware = false
		lply.is_aware = false

	end)

	--hook.Add("TTT2PreventAccessShop", "TTT2UnawareShopAccess", function(ply)
    --
	--	if ply:GetSubRole() ~= ROLE_UNAWARE then return end
    --
	--	if ply.is_aware then return false end
	--	return true
	--	
	--end)

	hook.Add("TTTBodySearchPopulate", "TTT2UnawareDisplayHint", function(search, raw)
		local lply = LocalPlayer()
		if lply.ttt2_unaware then

			if not raw.owner then return end
			if not raw.owner:IsPlayer() then return end

			local highest_id = 0
			for _, v in pairs(search) do
			  highest_id = math.max(highest_id, v.p)
			end

		end
	end)

end