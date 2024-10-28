CreateConVar("cl_error_mode", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Choose error mode: 0=normal, 1=party, 2=player, 3=weapon, 4=siren, 5=customsiren")
CreateConVar("cl_error_glow", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable or disable the glow effect on error models") 
CreateConVar("cl_error_glow_intensity", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Set the intensity of the glow effect on error models")

local partyColors = {
    Color(0, 0, 255),    
    Color(0, 255, 0),    
    Color(0, 255, 255),  
    Color(255, 0, 0),    
    Color(50, 205, 50),  
    Color(255, 69, 0),   
    Color(0, 0, 0),      
    Color(64, 224, 208), 
    Color(25, 25, 112),  
    Color(0, 128, 128),  
    Color(127, 255, 212),
    Color(148, 0, 211),  
    Color(75, 0, 130),   
    Color(255, 0, 255),  
    Color(255, 127, 0),  
    Color(255, 255, 0),  
    Color(255, 20, 147), 
}

local sirenColors = {
    Color(255, 0, 0),
    Color(0, 0, 139),
}

local flatMaterial = Material("models/debug/debugwhite")

local lastColor = partyColors[1]
local nextColor = partyColors[2]
local blendTime = 0
local blendDuration = 0.5
local sirenBlendDuration = 0.2
local lastChangeTime = 0
local colorIndex = 1
local changeInterval = 0.1
local sirenChangeInterval = 0.05

local function LerpColor(t, from, to)
    return Color(
        Lerp(t, from.r, to.r),
        Lerp(t, from.g, to.g),
        Lerp(t, from.b, to.b),
        Lerp(t, from.a, to.a)
    )
end

local function SimulateFlash(color)
    local flashAlpha = math.abs(math.sin(CurTime() * 5))
    return Color(color.r * flashAlpha, color.g * flashAlpha, color.b * flashAlpha, 255)
end

local function GetPlayerModelColor(ply)
    if IsValid(ply) and ply.GetPlayerColor then
        return ply:GetPlayerColor():ToColor()
    end
    return Color(255, 255, 255)
end

local function GetPlayerPhysgunColor(ply)
    if IsValid(ply) and ply.GetWeaponColor then
        return ply:GetWeaponColor():ToColor()
    end
    return Color(255, 255, 255)
end

hook.Add("PostDrawOpaqueRenderables", "ErrorColorMode", function()
    local ply = LocalPlayer()
    for _, ent in pairs(ents.GetAll()) do
        if ent:GetModel() == "models/error.mdl" then
            local mode = GetConVar("cl_error_mode"):GetInt()
            local blendedColor

            if mode == 0 then
                ent:SetMaterial("")
                ent:SetColor(Color(255, 0, 0))
            else
                ent:SetMaterial(flatMaterial:GetName())

                if mode == 1 then
                    if CurTime() - lastChangeTime > changeInterval then
                        blendTime = blendTime + FrameTime()
                        if blendTime >= blendDuration then
                            blendTime = 0
                            lastColor = nextColor
                            colorIndex = colorIndex + 1
                            if colorIndex > #partyColors then
                                colorIndex = 1
                            end
                            nextColor = partyColors[colorIndex]
                        end
                    end
                    blendedColor = LerpColor(blendTime / blendDuration, lastColor, nextColor)
                    ent:SetColor(SimulateFlash(blendedColor))

                elseif mode == 2 then
                    local modelColor = GetPlayerModelColor(ply)
                    ent:SetColor(SimulateFlash(modelColor))

                elseif mode == 3 then
                    local physColor = GetPlayerPhysgunColor(ply)
                    ent:SetColor(SimulateFlash(physColor))

                elseif mode == 4 then
                    if CurTime() - lastChangeTime > sirenChangeInterval then
                        colorIndex = colorIndex + 1
                        if colorIndex > #sirenColors then
                            colorIndex = 1
                        end
                        lastChangeTime = CurTime()
                    end
                    ent:SetColor(SimulateFlash(sirenColors[colorIndex]))

                elseif mode == 5 then
                    local playerColor = GetPlayerModelColor(ply)
                    local weaponColor = GetPlayerPhysgunColor(ply)
                    if CurTime() - lastChangeTime > sirenChangeInterval then
                        colorIndex = colorIndex + 1
                        if colorIndex % 2 == 0 then
                            ent:SetColor(SimulateFlash(playerColor))
                        else
                            ent:SetColor(SimulateFlash(weaponColor))
                        end
                        lastChangeTime = CurTime()
                    end
                end
            end

            if GetConVar("cl_error_glow"):GetBool() then
                local light = DynamicLight(ent:EntIndex())
                if light then
                    local brightness = GetConVar("cl_error_glow_intensity"):GetFloat()
                    local distance = ply:GetPos():Distance(ent:GetPos())
                    brightness = brightness * math.Clamp(300 / distance, 0.5, 3)

                    light.pos = ent:GetPos()
                    local glowColor = ent:GetColor()
                    light.r = glowColor.r
                    light.g = glowColor.g
                    light.b = glowColor.b

                    light.brightness = brightness
                    light.Decay = 1000
                    light.Size = 200
                    light.DieTime = CurTime() + 0.1
                end
            end
        end
    end
end)