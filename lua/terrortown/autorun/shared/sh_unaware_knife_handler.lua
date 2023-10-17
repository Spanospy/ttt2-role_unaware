
if SERVER then

    AddCSLuaFile()

    local function SpawnKnife(ply, pos)

        local knife = ents.Create("ttt_unaware_knife_pickup")

        if not IsValid(knife) then return end

        knife:SetPos(pos + Vector (0,0,5))
        knife:SetCollisionGroup(2) --COLLISION_GROUP_DEBRIS_TRIGGER
        knife.unaware = ply

        local plys = player.GetAll()
        for i = 1, #plys do
            if plys[i] ~= ply then
                knife:SetPreventTransmit(plys[i], true)
            end
        end

        knife:Spawn()

    end

    hook.Add("TTTBeginRound", "ttt2UnawareSpawnKnife", function()
		if not (GetConVar("ttt2_unaware_hints_enable"):GetBool() and GetConVar("ttt2_unaware_hints_knife"):GetBool()) then return end

        --Check there are Unawares in play
        local plys = player.GetAll()
        local unawares = {}

		for i = 1, #plys do
			if plys[i]:GetSubRole() == ROLE_UNAWARE then
                table.insert(unawares, plys[i])
			end
		end

        if next(unawares) ~= nil then

            --get all possible spawns. Use navmesh.GetAllNavAreas() if it's not an empty table, else fallback to spawning relative to existing items - ents.FindByClass("item_*")

            local possible_spawns = navmesh.GetAllNavAreas()

            if next(possible_spawns) ~= nil then

                --for each Unaware player, spawn a knife randomly in the world that only they can see and interact with.

                for i = 1, #unawares do

                    local spawnarea = possible_spawns[math.random(#possible_spawns)]
                    local corner = spawnarea.corner
                    local opposite_corner = spawnarea.opposite_corner
                    local spawnpos = Vector( math.random(corner.x, opposite_corner.x), math.random(corner.y, opposite_corner.y), math.random(corner.z, opposite_corner.z) )

                    SpawnKnife(unawares[i], spawnpos)

                end

            else
                --If no navmesh, fallback to spawning knife relative to items

                possible_spawns = ents.FindByClass("item_*")
                if next(possible_spawns) == nil then return end

                --for each Unaware player, spawn a knife randomly in the world that only they can see and interact with.

                for i = 1, #unawares do
                    local spawn = possible_spawns[math.random(#possible_spawns)]
                    SpawnKnife(unawares[i], spawn:GetPos())
                end

            end

        end

        --local spawn = possible_spawns[math.random(#possible_spawns)]

        --pos + Vector(0,0,5)


	end)

end