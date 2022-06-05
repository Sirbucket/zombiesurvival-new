CLASS.Base = "meat_monster"

CLASS.Name = "Dried Meat Monster"
CLASS.TranslationName = "class_dried_meat_monster"
CLASS.Description = "description_dried_meat_monster"
CLASS.Help = "controls_dried_meat_monster"

CLASS.Health = 950
CLASS.Speed = 165

CLASS.Wave = 5 / 6

CLASS.Mass = DEFAULT_MASS

CLASS.Points = CLASS.Health/GM.PoisonZombiePointRatio

CLASS.SWEP = "weapon_zs_dried_meat_monster"

CLASS.Model = Model("models/player/charple.mdl")
CLASS.ModelScale = 1

if SERVER then 
    local math_Clamp = math.Clamp
    function CLASS:ProcessDamage(pl, dmginfo) -- Provided by HST, ty!
    local inflictor = dmginfo:GetInflictor()
    local class_health = self.Health

    if not IsValid(inflictor) then return end

    local mul = 1
    local melee = inflictor.IsMelee
    local bullet = inflictor.IsBullet
    local explosive = inflictor.IsExplosive
    local formula = pl:Health() / class_health

    if melee or bullet then
        mul = math_Clamp(formula, 0.75, 0.9)
    elseif explosive then
        mul = math_Clamp(formula, 0.5, 1)
    end

    dmginfo:SetDamage(dmginfo:GetDamage() * mul)
end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/devourer"

local matFlesh = Material("models/flesh")
local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_SetColorModulation = render.SetColorModulation

function CLASS:PrePlayerDraw(pl)
	render_ModelMaterialOverride(matFlesh)
	render_SetColorModulation(0.1, 0.1, 0.1)
end

function CLASS:PostPlayerDraw(pl)
	render_SetColorModulation(1, 1, 1)
	render_ModelMaterialOverride()
end