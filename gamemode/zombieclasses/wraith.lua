CLASS.Name = "Wraith"
CLASS.TranslationName = "class_wraith"
CLASS.Description = "description_wraith"
CLASS.Help = "controls_wraith"

CLASS.BetterVersion = "Tormented Wraith"

CLASS.Wave = 0
CLASS.Unlocked = true

CLASS.Health = 135

CLASS.SWEP = "weapon_zs_wraith"
CLASS.Model = Model("models/player/zelpa/stalker.mdl")
CLASS.Speed = 150

CLASS.CanTaunt = true

CLASS.Points = CLASS.Health/GM.NoHeadboxZombiePointRatio

CLASS.VoicePitch = 0.65

CLASS.PainSounds = {Sound("npc/barnacle/barnacle_pull1.wav"), Sound("npc/barnacle/barnacle_pull2.wav"), Sound("npc/barnacle/barnacle_pull3.wav"), Sound("npc/barnacle/barnacle_pull4.wav")}
CLASS.DeathSounds = {Sound("zombiesurvival/wraithdeath1.ogg"), Sound("zombiesurvival/wraithdeath2.ogg"), Sound("zombiesurvival/wraithdeath3.ogg"), Sound("zombiesurvival/wraithdeath4.ogg")}

CLASS.NoShadow = true
CLASS.IgnoreTargetAssist = true
CLASS.RenderMode = RENDERMODE_TRANSALPHA -- Prevents flashlight shadows

CLASS.BloodColor = BLOOD_COLOR_MECH

local math_min = math.min
local math_Clamp = math.Clamp

local IN_SPEED = IN_SPEED
local TEAM_UNDEAD = TEAM_UNDEAD

local ACT_HL2MP_SWIM_PISTOL = ACT_HL2MP_SWIM_PISTOL
local ACT_HL2MP_IDLE_CROUCH_FIST = ACT_HL2MP_IDLE_CROUCH_FIST
local ACT_HL2MP_IDLE_KNIFE = ACT_HL2MP_IDLE_KNIFE
local ACT_HL2MP_WALK_CROUCH_KNIFE = ACT_HL2MP_WALK_CROUCH_KNIFE
local ACT_HL2MP_WALK_KNIFE = ACT_HL2MP_WALK_KNIFE
local ACT_HL2MP_RUN_KNIFE = ACT_HL2MP_RUN_KNIFE
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local PLAYERANIMEVENT_RELOAD = PLAYERANIMEVENT_RELOAD
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL
local ACT_GMOD_GESTURE_TAUNT_ZOMBIE = ACT_GMOD_GESTURE_TAUNT_ZOMBIE
local ACT_INVALID = ACT_INVALID

local g_tbl = {
	[1] = ACT_HL2MP_SWIM_PISTOL,
	[2] = ACT_HL2MP_IDLE_CROUCH_FIST,
	[3] = ACT_HL2MP_IDLE_KNIFE,
	[4] = ACT_HL2MP_WALK_CROUCH_KNIFE,
	[5] = ACT_HL2MP_WALK_KNIFE,
	[6] = ACT_HL2MP_RUN_KNIFE,
	[7] = PLAYERANIMEVENT_ATTACK_PRIMARY,
	[8] = PLAYERANIMEVENT_RELOAD,
	[9] = GESTURE_SLOT_ATTACK_AND_RELOAD,
	[10] = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL,
	[11] = ACT_GMOD_GESTURE_TAUNT_ZOMBIE,
	[12] = ACT_INVALID
}

function CLASS:Move(pl, move)
	if pl:KeyDown(IN_SPEED) then
		move:SetMaxSpeed(40)
		move:SetMaxClientSpeed(40)
	end
end

function CLASS:CalcMainActivity(pl, velocity)
	if pl:WaterLevel() >= 3 then
		return g_tbl[1], -1
	end

	local len = velocity:Length2DSqr()
	if len <= 1 then
		if pl:Crouching() and pl:OnGround() then
			return g_tbl[2], -1
		end

		return g_tbl[3], -1
	end

	if pl:Crouching() and pl:OnGround() then
		return g_tbl[4], -1
	end

	if len < 2800 then
		return g_tbl[5], -1
	end

	return g_tbl[6], -1
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
	local switch = {
		[g_tbl[7]] = function(pl) 
			pl:AnimRestartGesture(g_tbl[9], g_tbl[10], true)
			return g_tbl[12]
		end,
		[g_tbl[8]] = function(pl)
			pl:AnimRestartGesture(g_tbl[9], g_tbl[11], true)
			return g_tbl[12]
		end
	}

	return switch[event] and switch[event](pl)
end

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	return true
end

function CLASS:GetAlpha(pl)
	local wep = pl:GetActiveWeapon()
	if not wep.IsAttacking then wep = NULL end

	if wep:IsValid() and wep:IsAttacking() then
		return 0.7
	end

	local eyepos = EyePos()
	local nearest = pl:WorldSpaceCenter()
	local norm = nearest - eyepos
	norm:Normalize()
	local dot = EyeVector():Dot(norm)

	local vis = (dot * 0.4 + pl:GetVelocity():Length() / self.Speed / 2 - eyepos:Distance(nearest) / 400) * dot

	return math_Clamp(vis, MySelf:IsValid() and MySelf:Team() == TEAM_UNDEAD and 0.137 or 0, 0.7)
end

if SERVER then
	local util_Effect = util.Effect
	function CLASS:OnKilled(pl, attacker, inflictor, suicide, headshot, dmginfo, assister)
		local effectdata = EffectData()
			effectdata:SetOrigin(pl:GetPos())
			effectdata:SetNormal(pl:GetForward())
			effectdata:SetEntity(pl)
		util_Effect("death_wraith", effectdata, nil, true)

		return true
	end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/wraithv2"

local render_SetBlend = render.SetBlend
local render_SetColorModulation = render.SetColorModulation
local render_SuppressEngineLighting = render.SuppressEngineLighting

function CLASS:PrePlayerDraw(pl)

	local alpha = self:GetAlpha(pl)
	if alpha == 0 then return true end

	render_SetBlend(alpha)
	render_SetColorModulation(0.025, 0.025, 0.1)
	render_SuppressEngineLighting(true)
end

function CLASS:PostPlayerDraw(pl)
	render_SuppressEngineLighting(false)
	render_SetColorModulation(1, 1, 1)
	render_SetBlend(1)
end
