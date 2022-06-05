CLASS.Name = "Night Devourer"
CLASS.TranslationName = "class_night_devourer"
CLASS.Description = "description_night_devourer"
CLASS.Help = "controls_night_devourer"

CLASS.Boss = true

CLASS.KnockbackScale = 0

CLASS.Health = 2000
CLASS.Speed = 180

CLASS.CanTaunt = true

CLASS.FearPerInstance = 1

CLASS.Points = 30

CLASS.SWEP = "weapon_zs_devourer"

CLASS.Model = Model("models/player/charple.mdl")
CLASS.ModelScale = 1.3
CLASS.VoicePitch = 0.65

CLASS.PainSounds = {"npc/zombie/zombie_pain1.wav", "npc/zombie/zombie_pain2.wav", "npc/zombie/zombie_pain3.wav", "npc/zombie/zombie_pain4.wav", "npc/zombie/zombie_pain5.wav", "npc/zombie/zombie_pain6.wav"}
CLASS.DeathSounds = {"npc/zombie/zombie_die1.wav", "npc/zombie/zombie_die2.wav", "npc/zombie/zombie_die3.wav"}

local math_random = math.random
local math_min = math.min
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
		pl:CreateAmbience("nightmareambience")
	end
end

if not CLIENT then return end
local math_Rand = math.Rand


CLASS.Icon = "zombiesurvival/killicons/nightmare2"

local render_SetColorModulation = render.SetColorModulation

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

local function CreateBoneOffsets(pl)
	pl.m_NightmareBoneOffsetsNext = CurTime() + math_Rand(0.02, 0.1)

	local offsets = {}
	local angs = {}
	for i=1, pl:GetBoneCount() - 1 do
		if math_random(3) == 3 then
			offsets[i] = VectorRand():GetNormalized() * math_Rand(0.5, 3)
		end
		if math_random(5) == 5 then
			angs[i] = Angle(math_Rand(-5, 5), math_Rand(-15, 15), math_Rand(-5, 5))
		end
	end
	pl.m_NightmareBoneOffsets = offsets
	pl.m_NightmareBoneAngles = angs
end

function CLASS:BuildBonePositions(pl)
	if not pl.m_NightmareBoneOffsets or CurTime() >= pl.m_NightmareBoneOffsetsNext then
		CreateBoneOffsets(pl)
	end

	local offsets = pl.m_NightmareBoneOffsets
	local angs = pl.m_NightmareBoneAngles
	for i=1, pl:GetBoneCount() - 1 do
		if offsets[i] then
			pl:ManipulateBonePosition(i, offsets[i])
		end
		if angs[i] then
			pl:ManipulateBoneAngles(i, angs[i])
		end
	end

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
function CLASS:PrePlayerDraw(pl)
	render_SetColorModulation(0.1, 0.1, 0.1)
end

function CLASS:PostPlayerDraw(pl)
	render_SetColorModulation(1, 1, 1)
end
