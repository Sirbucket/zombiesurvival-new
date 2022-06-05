CLASS.Name = "Shade"
CLASS.TranslationName = "class_shade"
CLASS.Description = "description_shade"
CLASS.Help = "controls_shade"

CLASS.Boss = true

CLASS.KnockbackScale = 0

CLASS.NoGibs = true
CLASS.NoFallDamage = true
CLASS.NoFallSlowdown = true

CLASS.NoShadow = true
CLASS.NoAdjustPhysDamage = true

CLASS.CanTaunt = true

CLASS.Health = 1500 --1200
CLASS.Speed = 170 --125

CLASS.FearPerInstance = 1

CLASS.Points = 30

CLASS.SWEP = "weapon_zs_shade"

CLASS.Model = Model("models/player/zombie_fast.mdl")

CLASS.VoicePitch = 0.8

CLASS.BloodColor = BLOOD_COLOR_MECH

CLASS.PainSounds = {Sound("npc/barnacle/barnacle_pull1.wav"), Sound("npc/barnacle/barnacle_pull2.wav"), Sound("npc/barnacle/barnacle_pull3.wav"), Sound("npc/barnacle/barnacle_pull4.wav")}
CLASS.DeathSounds = {Sound("zombiesurvival/wraithdeath1.ogg"), Sound("zombiesurvival/wraithdeath2.ogg"), Sound("zombiesurvival/wraithdeath3.ogg"), Sound("zombiesurvival/wraithdeath4.ogg")}

local math_sin = math.sin
local math_cos = math.cos
local math_abs = math.abs
local math_Clamp = math.Clamp
local util_Effect = util.Effect
local CurTime = CurTime

local ACT_HL2MP_IDLE_MAGIC = ACT_HL2MP_IDLE_MAGIC
local ACT_HL2MP_RUN_MAGIC = ACT_HL2MP_RUN_MAGIC
local ACT_HL2MP_RUN_ZOMBIE = ACT_HL2MP_RUN_ZOMBIE
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2
local ACT_INVALID = ACT_INVALID

local HITGROUP_GEAR = HITGROUP_GEAR
local HITGROUP_GENERIC = HITGROUP_GENERIC
local HITGROUP_LEFTLEG = HITGROUP_LEFTLEG
local HITGROUP_RIGHTLEG = HITGROUP_RIGHTLEG

function CLASS:ScalePlayerDamage(pl, hitgroup, dmginfo)
	if not dmginfo:IsBulletDamage() then return true end

	if hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG or hitgroup == HITGROUP_GEAR or hitgroup == HITGROUP_GENERIC then
		dmginfo:SetDamage(dmginfo:GetDamage() * 0.6)
	end

	return true
end

function CLASS:IgnoreLegDamage(pl, dmginfo)
	return true
end

function CLASS:Move(pl, move)
	local shadeshield = pl.ShadeShield
	if shadeshield and shadeshield:IsValid() then
		move:SetMaxSpeed(35)
		move:SetMaxClientSpeed(35)
	end
end

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	return true
end

function CLASS:PlayerStepSoundTime(pl, iType, bWalking)
	return 1000
end

function CLASS:CalcMainActivity(pl, velocity)
	local shadeshield = pl.ShadeShield
	local shadecontrol = pl.ShadeControl
	if (shadecontrol and shadecontrol:IsValid()) or (shadeshield and shadeshield:IsValid()) then
		if velocity:Length2DSqr() <= 1 then
			return ACT_HL2MP_IDLE_MAGIC, -1
		end

		return ACT_HL2MP_RUN_MAGIC, -1
	end

	return ACT_HL2MP_RUN_ZOMBIE, -1
end

function CLASS:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2, true)
		return ACT_INVALID
	end
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:SetPlaybackRate(1)
	pl:SetCycle(0.35 + math_abs(math_sin(CurTime() * 1.5)) * 0.3)

	return true
end

function CLASS:OnKilled(pl, attacker, inflictor, suicide, headshot, dmginfo, assister)
	if SERVER then
		local effectdata = EffectData()
			effectdata:SetOrigin(pl:WorldSpaceCenter())
			effectdata:SetNormal(pl:GetUp())
			effectdata:SetEntity(pl)
		util_Effect("death_shade", effectdata, nil, true)
	end

	return true
end

if SERVER then
	function CLASS:OnSpawned(pl)
		pl:CreateAmbience("shadeambience")
		pl:SetRenderMode(RENDERMODE_TRANSALPHA)
	end

	function CLASS:SwitchedAway(pl)
		pl:SetRenderMode(RENDERMODE_NORMAL)
	end

	function CLASS:ProcessDamage(pl, dmginfo)
		if SERVER then
			local inflictor = dmginfo:GetInflictor()
			if inflictor:IsValid() and (inflictor:IsPhysicsModel() or inflictor.IsPhysbox) then
				return
			end

			local status = pl.status_shadeambience
			if status and status:IsValid() then
				status:SetLastDamaged(CurTime())
			end
		end
	end

	function CLASS:ShadeShield(pl)
		local shadeshield = pl.ShadeShield
		local nextshield = pl.NextShield
		local curtime = CurTime()
		if nextshield and curtime <= nextshield then return end

		if shadeshield and shadeshield:IsValid() then
			if curtime >= shadeshield:GetStateEndTime() then
				shadeshield:SetState(1)
				shadeshield:SetStateEndTime(curtime + 0.5)
			end
		elseif pl:IsOnGround() and not pl:IsPlayingTaunt() then
			local wep = pl:GetActiveWeapon()
			if wep:IsValid() and curtime > wep:GetNextPrimaryFire() and curtime > wep:GetNextSecondaryFire() then
				local status = pl:GiveStatus("shadeshield")
				if status and status:IsValid() then
					status:SetStateEndTime(curtime + 0.5)

					for _, ent in pairs(ents.FindByClass("env_shadecontrol")) do
						if ent:IsValid() and ent:GetOwner() == pl then
							ent:Remove()
							return
						end
					end
				end
			end
		end
	end

	function CLASS:AltUse(pl)
		self:ShadeShield(pl)
	end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/shadev2"
CLASS.IconColor = Color(0, 50, 255)

local ToZero = {"ValveBiped.Bip01_L_Thigh", "ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_L_Calf", "ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_R_Foot"}
function CLASS:BuildBonePositions(pl)
	for _, bonename in pairs(ToZero) do
		local boneid = pl:LookupBone(bonename)
		if boneid and boneid > 0 then
			pl:ManipulateBoneScale(boneid, vector_tiny)
		end
	end
end

local nodraw = false
local matWhite = Material("models/debug/debugwhite")
local matRefract = Material("models/spawn_effect")
local render_SupportsVertexShaders_2_0 = render.SupportsVertexShaders_2_0()
local render_SupportsPixelShaders_2_0 = render.SupportsPixelShaders_2_0()
local render_EnableClipping = render.EnableClipping
local render_PushCustomClipPlane = render.PushCustomClipPlane
local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_SuppressEngineLighting = render.SuppressEngineLighting
local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_PopCustomClipPlane = render.PopCustomClipPlane
local render_UpdateRefractTexture = render.UpdateRefractTexture

function CLASS:PreRenderEffects(pl)
	if render_SupportsVertexShaders_2_0 then
		local normal = pl:GetUp()
		render_EnableClipping(true)
		render_PushCustomClipPlane(normal, normal:Dot(pl:GetPos() + normal * 16))
	end

	if nodraw then return end

	local red = 0
	local status = pl.status_shadeambience
	if status and status:IsValid() then
		red = 1 - math_Clamp((CurTime() - status:GetLastDamaged()) * 3, 0, 1) ^ 3
	end

	render_SetColorModulation(red, 0.1, 1 - red)
	render_SetBlend(0.5 + math_abs(math_cos(CurTime())) ^ 2 * 0.1)
	render_SuppressEngineLighting(true)
	render_ModelMaterialOverride(matWhite)
end

function CLASS:PostRenderEffects(pl)
	if render_SupportsVertexShaders_2_0 then
		render_PopCustomClipPlane()
		render_EnableClipping(false)
	end

	if nodraw then return end

	render_SetColorModulation(1, 1, 1)
	render_SetBlend(1)
	render_SuppressEngineLighting(false)
	render_ModelMaterialOverride()

	if render_SupportsPixelShaders_2_0 then
		render_UpdateRefractTexture()

		matRefract:SetFloat("$refractamount", 0.01)

		render_ModelMaterialOverride(matRefract)
		nodraw = true
		pl:DrawModel()
		nodraw = false
		render_ModelMaterialOverride(0)
	end
end

function CLASS:PrePlayerDraw(pl)
	pl:RemoveAllDecals()

	self:PreRenderEffects(pl)
end

function CLASS:PostPlayerDraw(pl)
	self:PostRenderEffects(pl)
end
