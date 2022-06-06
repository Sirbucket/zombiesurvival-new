CLASS.Name = "Bloated Zombie"
CLASS.TranslationName = "class_bloated_zombie"
CLASS.Description = "description_bloated_zombie"
CLASS.Help = "controls_bloated_zombie"

CLASS.BetterVersion = "Vile Bloated Zombie"

CLASS.Wave = 2 / 6

CLASS.Health = 325
CLASS.Speed = 125
--CLASS.JumpPower = DEFAULT_JUMP_POWER * 0.811
CLASS.Mass = DEFAULT_MASS * 2

CLASS.CanTaunt = true

CLASS.Points = CLASS.Health/GM.HumanoidZombiePointRatio

CLASS.SWEP = "weapon_zs_bloatedzombie"

CLASS.Model = Model("models/player/fatty/fatty.mdl")

CLASS.DeathSounds = {"npc/ichthyosaur/water_growl5.wav"}

CLASS.VoicePitch = 0.6

CLASS.CanFeignDeath = true

CLASS.BloodColor = BLOOD_COLOR_GREEN

local math_random = math.random
local math_Rand = math.Rand
local math_min = math.min
local math_max = math.max
local math_ceil = math.ceil
local string_format = string.format
local CurTime = CurTime

local DIR_BACK = DIR_BACK
local ACT_HL2MP_ZOMBIE_SLUMP_RISE = ACT_HL2MP_ZOMBIE_SLUMP_RISE
local ACT_HL2MP_SWIM_PISTOL = ACT_HL2MP_SWIM_PISTOL
local ACT_HL2MP_IDLE_CROUCH_ZOMBIE = ACT_HL2MP_IDLE_CROUCH_ZOMBIE
local ACT_HL2MP_WALK_CROUCH_ZOMBIE_01 = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
local ACT_HL2MP_RUN_ZOMBIE = ACT_HL2MP_RUN_ZOMBIE
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local ACT_INVALID = ACT_INVALID
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local ACT_GMOD_GESTURE_TAUNT_ZOMBIE = ACT_GMOD_GESTURE_TAUNT_ZOMBIE
local PLAYERANIMEVENT_RELOAD = PLAYERANIMEVENT_RELOAD

local StepSounds = {
	"npc/zombie/foot1.wav",
	"npc/zombie/foot2.wav",
	"npc/zombie/foot3.wav"
}
local ScuffSounds = {
	"npc/zombie/foot_slide1.wav",
	"npc/zombie/foot_slide2.wav",
	"npc/zombie/foot_slide3.wav"
}
function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	if iFoot == 0 then
		pl:EmitSound("npc/zombie/foot1.wav", 70, 75)
	else
		pl:EmitSound("npc/zombie/foot2.wav", 70, 75)
	end

	return true
end

function CLASS:CalcMainActivity(pl, velocity)
	local feign = pl.FeignDeath
	if feign and feign:IsValid() then
		if feign:GetDirection() == DIR_BACK then
			return 1, pl:LookupSequence("zombie_slump_rise_02_fast")
		end

		return ACT_HL2MP_ZOMBIE_SLUMP_RISE, -1
	end

	if pl:WaterLevel() >= 3 then
		return ACT_HL2MP_SWIM_PISTOL, -1
	end

	if pl:Crouching() and pl:OnGround() then
		if velocity:Length2DSqr() <= 1 then
			return ACT_HL2MP_IDLE_CROUCH_ZOMBIE, -1
		end

		return ACT_HL2MP_WALK_CROUCH_ZOMBIE_01 - 1 + math_ceil((CurTime() / 4 + pl:EntIndex()) % 3), -1
	end

	return ACT_HL2MP_RUN_ZOMBIE, -1
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	local feign = pl.FeignDeath
	if feign and feign:IsValid() then
		if feign:GetState() == 1 then
			pl:SetCycle(1 - math_max(feign:GetStateEndTime() - CurTime(), 0) * 0.666)
		else
			pl:SetCycle(math_max(feign:GetStateEndTime() - CurTime(), 0) * 0.666)
		end
		pl:SetPlaybackRate(0)
		return true
	end

	local len2d = velocity:Length2D()
	if len2d > 1 then
		pl:SetPlaybackRate(math_min(len2d / maxseqgroundspeed, 3))
	else
		pl:SetPlaybackRate(1)
	end

	return true
end

function CLASS:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:DoZombieAttackAnim(data)
		return ACT_INVALID
	elseif event == PLAYERANIMEVENT_RELOAD then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_TAUNT_ZOMBIE, true)
		return ACT_INVALID
	end
end

function CLASS:DoesntGiveFear(pl)
	local feign = pl.FeignDeath
	return feign and feign:IsValid()
end

if SERVER then
	local util_Effect = util.Effect
	local timer_Simple = timer.Simple
    function CLASS:AltUse(pl)
        pl:StartFeignDeath()
    end

    local function Bomb(pl, pos, dir)
        if not IsValid(pl) then return end

        dir:RotateAroundAxis(dir:Right(), 30)

        local effectdata = EffectData()
            effectdata:SetOrigin(pos)
            effectdata:SetNormal(dir:Forward())
        util_Effect("explosion_fat", effectdata, true)

        for i=1, 6 do
            local ang = Angle()
            ang:Set(dir)
            ang:RotateAroundAxis(ang:Up(), math_Rand(-30, 30))
            ang:RotateAroundAxis(ang:Right(), math_Rand(-30, 30))

            local heading = ang:Forward()

            local ent = ents.CreateLimited("projectile_poisonflesh")
            if ent:IsValid() then
                ent:SetPos(pos)
                ent:SetOwner(pl)
                ent:Spawn()

                local phys = ent:GetPhysicsObject()
                if phys:IsValid() then
                    phys:Wake()
                    phys:SetVelocityInstantaneous(heading * math_Rand(120, 250))
                end
            end
        end
    end

    function CLASS:OnKilled(pl, attacker, inflictor, suicide, headshot, dmginfo, assister)
        if attacker ~= pl and not suicide then
            local pos = pl:LocalToWorld(pl:OBBCenter())
            local ang = pl:SyncAngles()
            timer_Simple(0, function() Bomb(pl, pos, ang) end)
        end
    end
end

if not CLIENT then return end
CLASS.Icon = "zombiesurvival/killicons/bloatedzombie"
