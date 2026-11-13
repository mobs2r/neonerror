-- Neon Error Sign (server): remembers who spawned what, so each player's
-- client can colour an ERROR by its spawner's player / physgun colour.
-- Skipped when a CPPI prop-protection addon already networks owners.

local function mark(ply, ent)
    if not IsValid(ent) or not IsValid(ply) then return end
    if ent.CPPIGetOwner then return end
    ent:SetNW2Entity("m2ne_owner", ply)
end

hook.Add("PlayerSpawnedProp", "NeonErrorOwner", function(ply, _, ent) mark(ply, ent) end)
hook.Add("PlayerSpawnedRagdoll", "NeonErrorOwner", function(ply, _, ent) mark(ply, ent) end)
hook.Add("PlayerSpawnedEffect", "NeonErrorOwner", function(ply, _, ent) mark(ply, ent) end)
hook.Add("PlayerSpawnedSENT", "NeonErrorOwner", mark)
hook.Add("PlayerSpawnedNPC", "NeonErrorOwner", mark)
hook.Add("PlayerSpawnedVehicle", "NeonErrorOwner", mark)
hook.Add("PlayerSpawnedSWEP", "NeonErrorOwner", mark)
