-- Neon Error Sign (client): recolours and lights ERROR models.
-- Settings are per player (client convars), so every player chooses their own look.

local cvMode = CreateClientConVar("cl_error_mode", "0", true, false,
    "Choose error mode: 0=normal, 1=party, 2=player, 3=weapon, 4=siren, 5=customsiren", 0, 5)
local cvGlow = CreateClientConVar("cl_error_glow", "1", true, false,
    "Enable or disable the glow effect on error models", 0, 1)
local cvGlowIntensity = CreateClientConVar("cl_error_glow_intensity", "1", true, false,
    "Set the intensity of the glow effect on error models", 0, 10)
local cvMissing = CreateClientConVar("cl_error_missing", "1", true, false,
    "Also treat entities whose model you don't have mounted as errors", 0, 1)

local CurTime, FrameTime, IsValid, Color = CurTime, FrameTime, IsValid, Color
local Lerp, abs, sin, Clamp = Lerp, math.abs, math.sin, math.Clamp
local DynamicLight, LocalPlayer = DynamicLight, LocalPlayer

local ERROR_MODEL = "models/error.mdl"
local FLAT_MATERIAL = "models/debug/debugwhite"
local RED = Color(255, 0, 0)
local WHITE = Color(255, 255, 255)

local partyColors = {
    Color(0, 0, 255), Color(0, 255, 0), Color(0, 255, 255), Color(255, 0, 0),
    Color(50, 205, 50), Color(255, 69, 0), Color(0, 0, 0), Color(64, 224, 208),
    Color(25, 25, 112), Color(0, 128, 128), Color(127, 255, 212), Color(148, 0, 211),
    Color(75, 0, 130), Color(255, 0, 255), Color(255, 127, 0), Color(255, 255, 0),
    Color(255, 20, 147),
}
local sirenColors = { Color(255, 0, 0), Color(0, 0, 139) }

local BLEND_DURATION = 0.5   -- party: seconds to fade into the next colour
local SIREN_INTERVAL = 0.05  -- siren / custom siren: seconds per colour

-- Which entities show an error model. Rescanned twice a second instead of
-- walking ents.GetAll() in every render pass.
local tracked = {}
local validModel = {}
local function isError(ent)
    local model = ent:GetModel()
    if not model then return false end
    if model == ERROR_MODEL then return true end
    -- A model that isn't mounted on this client keeps its own path but draws as ERROR.
    if not cvMissing:GetBool() or model:sub(1, 7) ~= "models/" or model:sub(-4) ~= ".mdl" then return false end
    local ok = validModel[model]
    if ok == nil then
        ok = util.IsValidModel(model)
        validModel[model] = ok
    end
    return not ok
end

local function restore(ent)
    if not IsValid(ent) then return end
    ent:SetMaterial("")
    ent:SetColor(WHITE)
end

local scans = 0
local function rescan()
    -- Forget model verdicts now and then: content can be mounted mid-session.
    scans = scans + 1
    if scans % 60 == 0 then validModel = {} end
    local seen = {}
    for _, ent in ipairs(ents.GetAll()) do
        if isError(ent) then seen[ent] = true end
    end
    for ent in pairs(tracked) do
        if not seen[ent] then restore(ent) end
    end
    tracked = seen
end
timer.Create("NeonErrorRescan", 0.5, 0, rescan)
cvars.AddChangeCallback("cl_error_missing", function()
    validModel = {}
    rescan()
end, "NeonError")

-- Whose error is it? A prop-protection owner (CPPI) if there is one, else the
-- spawner the server marked, else nobody (server/map errors).
local function ownerOf(ent)
    if ent.CPPIGetOwner then
        local owner = ent:CPPIGetOwner()
        if IsValid(owner) and owner:IsPlayer() then return owner end
    end
    local owner = ent:GetNW2Entity("m2ne_owner")
    if IsValid(owner) and owner:IsPlayer() then return owner end
    return nil
end

local function playerColor(ply)
    if IsValid(ply) and ply.GetPlayerColor then return ply:GetPlayerColor():ToColor() end
    return WHITE
end

local function physgunColor(ply)
    if IsValid(ply) and ply.GetWeaponColor then return ply:GetWeaponColor():ToColor() end
    return WHITE
end

local function flash(color, amount)
    return Color(color.r * amount, color.g * amount, color.b * amount, 255)
end

-- Timing state, advanced once per frame (not once per entity per render pass,
-- which made party mode speed up with every extra error on screen).
local party = { from = partyColors[1], to = partyColors[2], index = 2, t = 0 }
local siren = { index = 1, nextSwap = 0 }

local function advance()
    local now = CurTime()
    party.t = party.t + FrameTime()
    if party.t >= BLEND_DURATION then
        party.t = 0
        party.from = party.to
        party.index = party.index % #partyColors + 1
        party.to = partyColors[party.index]
    end
    if now >= siren.nextSwap then
        siren.index = siren.index % 2 + 1
        siren.nextSwap = now + SIREN_INTERVAL
    end
end

local function colorFor(mode, ent, amount, partyColor)
    if mode == 1 then return flash(partyColor, amount) end
    if mode == 4 then return flash(sirenColors[siren.index], amount) end
    local who = ownerOf(ent) or LocalPlayer()
    if mode == 2 then return flash(playerColor(who), amount) end
    if mode == 3 then return flash(physgunColor(who), amount) end
    if mode == 5 then
        return flash(siren.index == 1 and playerColor(who) or physgunColor(who), amount)
    end
    return RED
end

hook.Add("Think", "NeonErrorColour", function()
    if next(tracked) == nil then return end
    advance()
    local mode = cvMode:GetInt()
    local amount = abs(sin(CurTime() * 5))
    local partyColor = mode == 1 and Color(
        Lerp(party.t / BLEND_DURATION, party.from.r, party.to.r),
        Lerp(party.t / BLEND_DURATION, party.from.g, party.to.g),
        Lerp(party.t / BLEND_DURATION, party.from.b, party.to.b), 255) or nil
    local glow = cvGlow:GetBool()
    local intensity = cvGlowIntensity:GetFloat()
    local eye = IsValid(LocalPlayer()) and LocalPlayer():GetPos()
    local now = CurTime()

    for ent in pairs(tracked) do
        if not IsValid(ent) then
            tracked[ent] = nil
        else
            local color = colorFor(mode, ent, amount, partyColor)
            ent:SetMaterial(mode == 0 and "" or FLAT_MATERIAL)
            ent:SetColor(color)

            if glow and eye then
                local light = DynamicLight(ent:EntIndex())
                if light then
                    local pos = ent:GetPos()
                    light.pos = pos
                    light.r, light.g, light.b = color.r, color.g, color.b
                    light.brightness = intensity * Clamp(300 / math.max(eye:Distance(pos), 1), 0.5, 3)
                    light.Decay = 1000
                    light.Size = 200
                    light.DieTime = now + 0.1
                end
            end
        end
    end
end)
