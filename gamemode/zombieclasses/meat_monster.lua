CLASS.Name = "Meat Monster"
CLASS.TranslationName = "class_meat_monster"
CLASS.Description = "description_meat_monster"
CLASS.Help = "controls_meat_monster"

CLASS.Health = 745
CLASS.Speed = 150

CLASS.Wave = 3 / 6
CLASS.Unlocked = true
CLASS.CanTaunt = true

CLASS.Mass = DEFAULT_MASS * 1.5

CLASS.Points = CLASS.Health/GM.PoisonZombiePointRatio

CLASS.SWEP = "weapon_zs_meat_monster"

CLASS.Model = Model("models/player/charple.mdl")
CLASS.ModelScale = 0.95
CLASS.VoicePitch = 0.65

CLASS.PainSounds = {"npc/zombie/zombie_pain1.wav", "npc/zombie/zombie_pain2.wav", "npc/zombie/zombie_pain3.wav", "npc/zombie/zombie_pain4.wav", "npc/zombie/zombie_pain5.wav", "npc/zombie/zombie_pain6.wav"}
CLASS.DeathSounds = {"npc/zombie/zombie_die1.wav", "npc/zombie/zombie_die2.wav", "npc/zombie/zombie_die3.wav"}

local math_random = math.random
local math_min = math.min
local math_Clamp = math.Clamp
local CurTime = CurTime

local ACT_HL2MP_SWIM_PISTOL = ACT_HL2MP_SWIM_PISTOL
local ACT_HL2MP_IDLE_CROUCH_ZOMBIE = ACT_HL2MP_IDLE_CROUCH_ZOMBIE
local ACT_HL2MP_WALK_CROUCH_ZOMBIE_01 = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
local ACT_HL2MP_RUN_ZOMBIE = ACT_HL2MP_RUN_ZOMBIE
local ACT_HL2MP_IDLE_KNIFE = ACT_HL2MP_IDLE_KNIFE
local ACT_HL2MP_IDLE_CROUCH_FIST = ACT_HL2MP_IDLE_CROUCH_FIST
local ACT_HL2MP_WALK_CROUCH_KNIFE = ACT_HL2MP_WALK_CROUCH_KNIFE
local ACT_HL2MP_WALK_KNIFE = ACT_HL2MP_WALK_KNIFE
local ACT_HL2MP_RUN_KNIFE = ACT_HL2MP_RUN_KNIFE
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
local ACT_GMOD_GESTURE_TAUNT_ZOMBIE = ACT_GMOD_GESTURE_TAUNT_ZOMBIE
local ACT_INVALID = ACT_INVALID

local StepSounds = {
	"npc/zombie/foot1.wav",
	"npc/zombie/foot2.wav",
	"npc/zombie/foot3.wav"
}
function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	pl:EmitSound(StepSounds[math_random(#StepSounds)], 70)

	return true
end

function CLASS:CalcMainActivity(pl, velocity)
	if pl:WaterLevel() >= 3 then
		return ACT_HL2MP_SWIM_PISTOL, -1
	end

	local len = velocity:Length2DSqr()
	if len <= 1 then
		if pl:Crouching() and pl:OnGround() then
			return ACT_HL2MP_IDLE_CROUCH_FIST, -1
		end

		return ACT_HL2MP_IDLE_KNIFE, -1
	end

	if pl:Crouching() and pl:OnGround() then
		return ACT_HL2MP_WALK_CROUCH_KNIFE, -1
	end

	if len < 2800 then
		return ACT_HL2MP_WALK_KNIFE, -1
	end

	return ACT_HL2MP_RUN_KNIFE, -1
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	local len2d = velocity:Length()
	if len2d > 1 then
		pl:SetPlaybackRate(math_min(len2d / maxseqgroundspeed, 3))
	else
		pl:SetPlaybackRate(1)
	end

	return true
end

function CLASS:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE, true)
		return ACT_INVALID
	elseif event == PLAYERANIMEVENT_RELOAD then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_TAUNT_ZOMBIE, true)
		return ACT_INVALID
	end
end

if SERVER then
	function CLASS:OnSpawned(pl)
		pl:CreateAmbience("devourerambience")
	end
	function CLASS:AltUse(pl)
        pl:StartFeignDeath()
    end
	function CLASS:ProcessDamage(pl, dmginfo) -- Provided by HST, ty!
		local inflictor = dmginfo:GetInflictor()
		local class_health = self.Health
	
		if not IsValid(inflictor) then return end
	
		local mul = 1
		local melee = inflictor.IsMelee
		local bullet = inflictor.IsBullet
		local bleed = inflictor.IsBleed
		local explosive = inflictor.IsExplosive
		local formula = pl:Health() / class_health
		if melee or bullet then
			mul = math_Clamp(formula, 0.75, 1)
		elseif explosive then
			mul = math_Clamp(formula, 0.5, 1)
		elseif bleed then
			mul = 2
		end
	
		dmginfo:SetDamage(dmginfo:GetDamage() * mul)
	end
end

local vecSpineOffset = Vector(1, 3, 0)

local MuscularBones = {
	["ValveBiped.Bip01_R_Upperarm"] = Vector(1, 2, 3.5),
	["ValveBiped.Bip01_R_Forearm"] = Vector(1, 2.5, 3),
	["ValveBiped.Bip01_L_Upperarm"] = Vector(1, 2, 3.5),
	["ValveBiped.Bip01_L_Forearm"] = Vector(1, 2.5, 3),
	["ValveBiped.Bip01_L_Hand"] = Vector(1, 2, 4),
	["ValveBiped.Bip01_R_Hand"] = Vector(1, 2, 4),
	["ValveBiped.Bip01_L_Thigh"] = Vector(1, 2, 3),
	["ValveBiped.Bip01_R_Thigh"] = Vector(1, 2, 3),
	["ValveBiped.Bip01_L_Calf"] = Vector(1, 2, 3),
	["ValveBiped.Bip01_R_Calf"] = Vector(1, 2, 3),
	["ValveBiped.Bip01_L_Foot"] = Vector(1, 2, 3),
	["ValveBiped.Bip01_R_Foot"] = Vector(1, 2, 3),
}

local SpineBones = {
	"ValveBiped.Bip01_Spine2",
	"ValveBiped.Bip01_Spine4",
	"ValveBiped.Bip01_Spine1",
	"ValveBiped.Bip01_Neck1"
}

function CLASS:BuildBonePositions(pl)
	for _, bone in pairs(SpineBones) do
		local boneid = pl:LookupBone(bone)
		if boneid and boneid > 0 then
			pl:ManipulateBonePosition(boneid, vecSpineOffset)
		end
	end

	for bonename, newscale in pairs(MuscularBones) do
		local boneid = pl:LookupBone(bonename)
		if boneid and boneid > 0 then
			pl:ManipulateBoneScale(boneid, newscale)
		end
	end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/devourer"

local matFlesh = Material("models/flesh")
local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_SetColorModulation = render.SetColorModulation

function CLASS:PrePlayerDraw(pl)
	render_ModelMaterialOverride(matFlesh)
	render_SetColorModulation(0.65, 0.45, 0.15)
end

function CLASS:PostPlayerDraw(pl)
	render_SetColorModulation(1, 1, 1)
	render_ModelMaterialOverride()
end