local v2, v3 = require("libs.vectors")()
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local interface, class = require("libs.interfaces")()
-- local hooks = require("libs.hooks")
local ffi = require("libs.protected_ffi")
local iengine = require("includes.engine")
local set     = require("libs.set")
local utils   = require("libs.utils")

---@class entity_t
---@field m_bEligibleForScreenHighlight boolean
---@field m_flMaxFallVelocity number
---@field m_flLastMadeNoiseTime number
---@field m_flUseLookAtAngle number
---@field m_flFadeScale number
---@field m_fadeMaxDist number
---@field m_fadeMinDist number
---@field m_bIsAutoaimTarget boolean
---@field m_bSpottedByMask boolean
---@field m_bSpottedBy boolean
---@field m_bSpotted boolean
---@field m_bAlternateSorting boolean
---@field m_bAnimatedEveryTick boolean
---@field m_bSimulatedEveryTick boolean
---@field m_iTextureFrameIndex number
---@field m_Collision table
---@field m_flPoseParameter table
---@field m_vecSpecifiedSurroundingMaxs vec3_t
---@field m_vecSpecifiedSurroundingMins vec3_t
---@field m_triggerBloat number
---@field m_nSurroundType number
---@field m_usSolidFlags number
---@field m_nSolidType number
---@field m_vecMaxs vec3_t
---@field m_vecMins vec3_t
---@field movetype number
---@field m_iName string
---@field m_iParentAttachment number
---@field m_hEffectEntity entity_t
---@field m_hOwnerEntity entity_t
---@field m_CollisionGroup number
---@field m_iPendingTeamNum number
---@field m_iTeamNum number
---@field m_clrRender number
---@field m_nRenderFX number
---@field m_nRenderMode number
---@field m_fEffects number
---@field m_nModelIndex number
---@field m_angRotation vec3_t
---@field m_vecOrigin vec3_t
---@field m_cellZ number
---@field m_cellY number
---@field m_cellX number
---@field m_cellbits number
---@field m_flSimulationTime number
---@field m_flAnimTime number
---@field m_viewtarget vec3_t
---@field m_blinktoggle boolean
---@field m_flexWeight table
---@field m_nWaterLevel number
---@field m_flDuckSpeed number
---@field m_flDuckAmount number
---@field m_bShouldDrawPlayerWhileUsingViewEntity boolean
---@field m_hViewEntity entity_t
---@field m_fThrowTime number
---@field m_bPinPulled boolean
---@field m_flThrowStrength number
---@field m_vphysicsCollisionState number
---@field m_hColorCorrectionCtrl entity_t
---@field m_hPostProcessCtrl entity_t
---@field m_ladderSurfaceProps number
---@field m_vecLadderNormal vec3_t
---@field m_szLastPlaceName string
---@field m_iCoachingTeam number
---@field m_hObserverTarget entity_t
---@field m_iDeathPostEffect number
---@field m_uCameraManGraphs number
---@field m_bCameraManScoreBoard boolean
---@field m_bCameraManOverview boolean
---@field m_bCameraManXRay boolean
---@field m_bActiveCameraMan boolean
---@field m_iObserverMode number
---@field m_fFlags number
---@field m_flMaxspeed number
---@field m_iBonusChallenge number
---@field m_iBonusProgress number
---@field m_iAmmo table
---@field m_lifeState number
---@field m_iHealth number
---@field m_hGroundEntity entity_t
---@field m_hUseEntity entity_t
---@field m_hVehicle entity_t
---@field m_afPhysicsFlags number
---@field m_hZoomOwner entity_t
---@field m_iDefaultFOV number
---@field m_flFOVTime number
---@field m_iFOVStart number
---@field m_iFOV number
---@field m_hTonemapController number
---@field m_flLaggedMovementValue number
---@field m_fForceTeam number
---@field m_flNextDecalTime number
---@field m_flDeathTime number
---@field m_bConstraintPastRadius boolean
---@field m_flConstraintSpeedFactor number
---@field m_flConstraintWidth number
---@field m_flConstraintRadius number
---@field m_vecConstraintCenter vec3_t
---@field m_hConstraintEntity entity_t
---@field m_vecBaseVelocity vec3_t
---@field m_vecVelocity vec3_t
---@field m_hLastWeapon entity_t
---@field m_nNextThinkTick number
---@field m_nTickBase number
---@field m_fOnTarget number
---@field m_flFriction number
---@field m_vecViewOffset vec3_t
---@field m_bAllowAutoMovement boolean
---@field m_flStepSize number
---@field m_bPoisoned boolean
---@field m_bWearingSuit boolean
---@field m_bDrawViewmodel boolean
---@field m_aimPunchAngleVel vec3_t
---@field m_aimPunchAngle vec3_t
---@field m_viewPunchAngle vec3_t
---@field m_flFallVelocity number
---@field m_nJumpTimeMsecs number
---@field m_nDuckJumpTimeMsecs number
---@field m_nDuckTimeMsecs number
---@field m_bInDuckJump boolean
---@field m_flLastDuckTime number
---@field m_bDucking boolean
---@field m_bDucked boolean
---@field m_flFOVRate number
---@field m_iHideHUD number
---@field m_chAreaPortalBits table
---@field m_chAreaBits table
---@field m_hMyWearables entity_t[]
---@field m_hMyWeapons entity_t[]
---@field m_nRelativeDirectionOfLastInjury number
---@field m_flTimeOfLastInjury number
---@field m_hActiveWeapon entity_t
---@field m_LastHitGroup number
---@field m_flNextAttack number
---@field m_flLastExoJumpTime number
---@field m_flHealthShotBoostExpirationTime number
---@field m_hSurvivalAssassinationTarget entity_t
---@field m_nSurvivalTeam number
---@field m_vecSpawnRappellingRopeOrigin vec3_t
---@field m_bIsSpawnRappelling boolean
---@field m_bHideTargetID boolean
---@field m_flThirdpersonRecoil number
---@field m_bStrafing boolean
---@field m_flLowerBodyYawTarget number
---@field m_unTotalRoundDamageDealt number
---@field m_iNumRoundKillsHeadshots number
---@field m_bIsLookingAtWeapon boolean
---@field m_bIsHoldingLookAtWeapon boolean
---@field m_nDeathCamMusic number
---@field m_nLastConcurrentKilled number
---@field m_nLastKillerIndex number
---@field m_bHud_RadarHidden boolean
---@field m_bHud_MiniScoreHidden boolean
---@field m_bIsAssassinationTarget boolean
---@field m_flAutoMoveTargetTime number
---@field m_flAutoMoveStartTime number
---@field m_vecAutomoveTargetEnd vec3_t
---@field m_iControlledBotEntIndex number
---@field m_bCanControlObservedBot boolean
---@field m_bHasControlledBotThisRound boolean
---@field m_bIsControllingBot boolean
---@field m_unFreezetimeEndEquipmentValue number
---@field m_unRoundStartEquipmentValue number
---@field m_unCurrentEquipmentValue number
---@field m_cycleLatch number
---@field m_hPlayerPing number
---@field m_hRagdoll entity_t
---@field m_flProgressBarStartTime number
---@field m_iProgressBarDuration number
---@field m_flFlashMaxAlpha number
---@field m_flFlashDuration number
---@field m_nHitboxSet number
---@field m_nHeavyAssaultSuitCooldownRemaining number
---@field m_bHasHeavyArmor boolean
---@field m_bHasHelmet boolean
---@field m_unMusicID number
---@field m_bHasParachute boolean
---@field m_passiveItems table
---@field m_rank table
---@field m_iMatchStats_EnemiesFlashed table
---@field m_iMatchStats_UtilityDamage table
---@field m_iMatchStats_CashEarned table
---@field m_iMatchStats_Objective table
---@field m_iMatchStats_HeadShotKills table
---@field m_iMatchStats_Assists table
---@field m_iMatchStats_Deaths table
---@field m_iMatchStats_LiveTime table
---@field m_iMatchStats_KillReward table
---@field m_iMatchStats_MoneySaved table
---@field m_iMatchStats_EquipmentValue table
---@field m_nPersonaDataPublicLevel table
---@field m_iMatchStats_Damage table
---@field m_iMatchStats_Kills table
---@field m_bIsPlayerGhost boolean
---@field m_flDetectedByEnemySensorTime number
---@field m_flGuardianTooFarDistFrac number
---@field m_isCurrentGunGameTeamLeader number
---@field m_isCurrentGunGameLeader number
---@field m_bCanMoveDuringFreezePeriod boolean
---@field m_flGroundAccelLinearFracLastTime number
---@field m_bIsRescuing boolean
---@field m_hCarriedHostageProp entity_t
---@field m_hCarriedHostage entity_t
---@field m_szArmsModel string
---@field m_fMolotovDamageTime number
---@field m_fMolotovUseTime number
---@field m_iNumRoundKills number
---@field m_iNumGunGameKillsWithCurrentWeapon number
---@field m_iNumGunGameTRKillPoints number
---@field m_iGunGameProgressiveWeaponIndex number
---@field m_bMadeFinalGunGameProgressiveKill boolean
---@field m_bHasMovedSinceSpawn boolean
---@field m_bGunGameImmunity boolean
---@field m_fImmuneToGunGameDamageTime number
---@field m_bResumeZoom boolean
---@field m_nIsAutoMounting number
---@field m_bIsWalking boolean
---@field m_bIsScoped boolean
---@field m_iBlockingUseActionInProgress number
---@field m_bIsGrabbingHostage boolean
---@field m_bIsDefusing boolean
---@field m_bInHostageRescueZone boolean
---@field m_bHasNightVision boolean
---@field m_bNightVisionOn boolean
---@field m_bHasDefuser boolean
---@field m_angEyeAngles vec3_t
---@field m_ArmorValue number
---@field m_iClass number
---@field m_iMoveState number
---@field m_bKilledByTaser boolean
---@field m_bInNoDefuseArea boolean
---@field m_bInBuyZone boolean
---@field m_bInBombZone boolean
---@field m_totalHitsOnServer number
---@field m_iStartAccount number
---@field m_iAccount number
---@field m_iPlayerState number
---@field m_bIsRespawningForDMBonus boolean
---@field m_bWaitForNoAttack boolean
---@field m_iThrowGrenadeCounter number
---@field m_iSecondaryAddon number
---@field m_iPrimaryAddon number
---@field m_iAddonBits number
---@field m_iWeaponPurchasesThisMatch table
---@field m_nQuestProgressReason number
---@field m_unActiveQuestId number
---@field m_iWeaponPurchasesThisRound table
---@field m_bPlayerDominatingMe boolean
---@field m_bPlayerDominated boolean
---@field m_flVelocityModifier number
---@field m_bDuckOverride boolean
---@field m_nNumFastDucks number
---@field m_iShotsFired number
---@field m_iDirection number
---@field m_flStamina number
---@field m_flNextPrimaryAttack number
---@field m_flNextSecondaryAttack number
---@field m_fLastShotTime number
---@field m_hThrower entity_t
---@field m_nExplodeEffectTickBegin number
---@field m_nGrenadeSpawnTime number
---@field m_vInitialVelocity vec3_t
---@field m_bAlive boolean[]
---@field m_iDeaths number[]
---@field m_iPing number[]
---@field m_iKills number[]
---@field m_iAssists number[]
---@field m_bConnected boolean[]

if not pcall(ffi.typeof, "struct RecvTable") then
    ffi.cdef[[
        struct RecvTable {
            void* props;
            int prop_count;
            void* decoder;
            const char* name;
        };
    ]]
end
if not pcall(ffi.typeof, "struct ClientClass") then
    ffi.cdef [[
        struct ClientClass {
            void*               create_fn;
            void*               create_event_fn;
            const char*         network_name;
            struct RecvTable*   recv_table;
            struct ClientClass* next;
            int                 class_id;
        };
    ]]
end
if not pcall(ffi.typeof, "struct StudioHitboxSet") then
    ffi.cdef[[
        struct StudioHitboxSet {
            int nameIndex;
            int numHitboxes;
            int hitboxIndex;
        };
    ]]
end
if not pcall(ffi.typeof, "struct StudioHdr") then
    ffi.cdef[[
        struct StudioHdr {
            int id;
            int version;
            int checksum;
            char name[64];
            int length;
            vector_t eyePosition;
            vector_t illumPosition;
            vector_t hullMin;
            vector_t hullMax;
            vector_t bbMin;
            vector_t bbMax;
            int flags;
            int numBones;
            int boneIndex;
            int numBoneControllers;
            int boneControllerIndex;
            int numHitboxSets;
            int hitboxSetIndex;
        };
    ]]
end
if not pcall(ffi.typeof, "struct StudioBbox") then
    ffi.cdef[[
        struct StudioBbox {
            int bone;
            int group;
            vector_t bbMin;
            vector_t bbMax;
            int hitboxNameIndex;
            vector_t offsetOrientation;
            float capsuleRadius;
            int unused[4];
        };
    ]]
end
if not pcall(ffi.typeof, "model_t") then
    ffi.cdef [[
        typedef struct{
            void*       handle;
            char        name[260];
            int         load_flags;
            int         server_count;
            int         type;
            int         flags;
            vector_t    mins;
            vector_t    maxs;
            float       radius;
            char        pad[28];
        } model_t;
    ]]
end
local IModelInfoClient = interface.new("engine", "VModelInfoClient004", {
    GetModel = { 1, "model_t*(__thiscall*)(void*, int)"},
    GetModelIndex = { 2, "int(__thiscall*)(void*, PCSTR)" },
    GetStudioModel = { 32, "struct StudioHdr*(__thiscall*)(void*, void*)" },
    FindOrLoadModel = { 39, "const model_t(__thiscall*)(void*, PCSTR)" }
})
local IBaseClient = interface.new("client", "VClient018", {
    GetAllClasses = { 8, "struct ClientClass*(__thiscall*)(void*)" },
})
local IClientEntityList = interface.new("client", "VClientEntityList003", {
    GetClientEntity = { 3, "uintptr_t(__thiscall*)(void*, int)" },
    GetClientEntityFromHandle = { 4, "uintptr_t(__thiscall*)(void*, uintptr_t)" },
    GetHighestEntityIndex = { 6, "int(__thiscall*)(void*)" },
})
local CBaseEntity = class.new({
    GetCollideable = { 3, "uintptr_t(__thiscall*)(void*)" },
    GetNetworkable = { 4, "uintptr_t(__thiscall*)(void*)" },
    GetClientRenderable = { 5, "uintptr_t(__thiscall*)(void*)" },
    GetClientEntity = { 6, "uintptr_t(__thiscall*)(void*)" },
    GetBaseEntity = { 7, "uintptr_t(__thiscall*)(void*)" },
    GetClientThinkable = { 8, "uintptr_t(__thiscall*)(void*)" },
    SetModelIndex = { 75, "void(__thiscall*)(void*,int)" },
    IsPlayer = { 158, "bool(__thiscall*)(void*)" },
    IsWeapon = { 166, "bool(__thiscall*)(void*)" },
})
local CCollideable = class.new({
    OBBMins = { 1, "vector_t*(__thiscall*)(void*)" },
    OBBMaxs = { 2, "vector_t*(__thiscall*)(void*)" },
})
-- local CClientNetworkable = class.new({
--     GetClientUnknown = {0, "uintptr_t(__thiscall*)(void*)"},
--     GetClientClass = {2, "struct ClientClass*(__thiscall*)(void*)"},
-- })

---@param index number
---@return ffi.ctype*
entitylist.get_client_entity = function(index)
    ---@diagnostic disable-next-line: undefined-field
    return IClientEntityList:GetClientEntity(index)
end
---@param steam_id string
---@return entity_t?
entitylist.get_entity_by_steam_id = function(steam_id)
    local entities = entitylist.get_entities("CCSPlayer", true)
    for _, player in pairs(entities) do
        if player:get_info().steam_id64 == steam_id then
            return player
        end
    end
end
---@return number
entitylist.get_highest_entity_index = function()
    return IClientEntityList:GetHighestEntityIndex()
end
---@param userid number
---@return entity_t?
entitylist.get_entity_by_userid = function(userid)
    local entities = entitylist.get_entities("CCSPlayer", true)
    for _, player in pairs(entities) do
        local info = player:get_info()
        if info and info.user_id == userid then
            return player
        end
    end
end
---@return entity_t?
entitylist.get_local_player_or_observed_player = function()
    local lp = entitylist.get_local_player()
    if not lp then return end
    if lp:is_alive() then
        return lp
    else
        return lp.m_hObserverTarget
    end
end

---@param handle number
---@return entity_t?
entitylist.get_entity_from_handle = function(handle)
    local entity = IClientEntityList:GetClientEntityFromHandle(handle)
    if entity == 0 or not entity then return end
    return entitylist.get(ffi.cast("int*", entity + 0x64)[0])
end

---@return entity_t?
entitylist.get_player_resource = function()
    return entitylist.get_entities("CCSPlayerResource", true)[1]
    -- for i = 0, entitylist.get_highest_entity_index() do
    --     local entity = entitylist.get(i)
    --     if entity then
    --         local client_class = entity:get_client_class()
    --         if client_class then
    --             if client_class.network_name == "CCSPlayerResource" then
    --                 print(tostring(client_class.class_id))
    --             end
    --             -- print(tostring(client_class.network_name))
    --         end
    --         if client_class and client_class.class_id == 80 then
    --             return entity
    --         end
    --     end
    -- end
end

---@param flag number
entity_t.get_flag = function(self, flag)
    return bit.band(self.m_fFlags, flag) ~= 0
end

entity_t.get_bone_matrix = function(self, bone)
    return ffi.cast("float*", ffi.cast("uintptr_t*", self[0x26A8])[0] + 0x30 * bone)
end

do
    local vector_transform = function(vec, matrix)
        return vec3_t.new(
			vec.x * matrix[0] + vec.y * matrix[1] + vec.z * matrix[2] + matrix[3],
			vec.x * matrix[4] + vec.y * matrix[5] + vec.z * matrix[6] + matrix[7],
			vec.x * matrix[8] + vec.y * matrix[9] + vec.z * matrix[10] + matrix[11]
		)
    end
    entity_t.get_player_hitbox_pos = function(self, hitbox)
		local pModel = IModelInfoClient:GetModel(self.m_nModelIndex)
        if not pModel then return end
		local pStudioHdr = IModelInfoClient:GetStudioModel(pModel)
		if not pStudioHdr then return end
        local pHitboxSet = ffi.cast("struct StudioHitboxSet*", ffi.cast("uintptr_t", pStudioHdr) + pStudioHdr.hitboxSetIndex) + self.m_nHitboxSet
        local bbox = ffi.cast("struct StudioBbox*", ffi.cast("uintptr_t", pHitboxSet) + pHitboxSet.hitboxIndex) + hitbox % pHitboxSet.numHitboxes
        local boneMatrix = self:get_bone_matrix(bbox.bone)
        if not boneMatrix then return end
        local min, max = vector_transform(bbox.bbMin, boneMatrix), vector_transform(bbox.bbMax, boneMatrix)
        return (min + max) / 2
    end
end

---@return boolean
entity_t.is_on_ground = function(self)
    return self:get_flag(1)
end

-- ---@return vec3_t
-- entity_t.get_velocity = function (self)
--     return self.m_vecVelocity
-- end

-- ---@return vec3_t
-- entity_t.get_origin = function (self)
--     return self.m_vecOrigin
-- end

entity_t.get_info = function(self)
    return iengine.get_player_info(self:get_index())
end

do
    ---@return "flashbang"|"he"|"smoke"|"decoy"|"molotov"|nil
    entity_t.get_grenade_type = function(self)
        -- local client_class = self:get_class_name()
        -- if not client_class then return end
        local index = self:get_class_id()
        local name
        if index == 77 then
            return "flashbang"
        elseif index == 9 or index == 96 then
            local model = self:get_model()
            if not model then return end
            local model_name = ffi.string(model.name)
            if not model_name:find("fraggrenade_dropped") then
                name = "flashbang"
            else
                name = "he"
            end
        elseif index == 157 or index == 156 then
            name = "smoke"
        elseif index == 48 or index == 47 then
            name = "decoy"
        elseif index == 114 or index == 99 then -- class name CIncendiaryGrenade
            name = "molotov"
        end
        return name
    end
end

do
    local ticks = {}
    ---@return number
    entity_t.get_ticks_in_dormant = function(self)
        local info = self:get_info()
        if not info then return 0 end
        local id = info.user_id
        if not ticks[id] then
            ticks[id] = 0
        end
        return ticks[id]
    end
    cbs.create_move(function()
        entitylist.get_entities("CCSPlayer", true, function(entity)
            local info = entity:get_info()
            if not info then return end
            local id = info.user_id
            if entity:is_dormant() then
                ticks[id] = ticks[id] + 1
            else
                ticks[id] = 0
            end
        end)
    end)
    cbs.event("round_prestart", function()
        for k, _ in pairs(ticks) do
            ticks[k] = math.huge
        end
    end)
end

entity_t.get_class = function(self)
    return CBaseEntity(self[0])
end

entity_t.get_networkable = function(self)
    return ffi.cast("uintptr_t*", self[8])[0]
end

entity_t.get_studio_hdr = function(self)
    local studio_hdr = ffi.cast("void**", self[0x2950]) or error("failed to get studio_hdr")
    studio_hdr = studio_hdr[0] or error("failed to get studio_hdr")
    return studio_hdr
end

if not pcall(ffi.typeof, "m_flposeparameter_t") then
    ffi.cdef [[
        typedef struct {
            char pad[8];
	        float m_start;
	        float m_end;
            float m_state;
        } m_flposeparameter_t;
    ]]
end
do
    local get_poseparam_sig = utils.find_pattern('client', '55 8B EC 8B 45 08 57 8B F9 8B 4F 04 85 C9 75 15')
    local native_get_poseparam = ffi.cast('m_flposeparameter_t*(__thiscall*)(void*, int)', get_poseparam_sig)
    if not get_poseparam_sig or not native_get_poseparam then error('failed to find get_poseparam_sig') end
    ---@param index number
    ---@return { m_start: number, m_end: number, m_state: number }
    entity_t.get_poseparam = function(self, index)
        local studio_hdr = self:get_studio_hdr()
        local param = native_get_poseparam(studio_hdr, index)
        if not param then error("failed to get pose param " .. tostring(index)) end
        return param
    end
    ---@param index number
    ---@param m_start number
    ---@param m_end number
    ---@param m_state? number
    entity_t.set_poseparam = function(self, index, m_start, m_end, m_state)
        local param = self:get_poseparam(index)
        local state = m_state
        if state == nil then
            state = ((m_start + m_end) / 2)
        end
        param.m_start, param.m_end, param.m_state = m_start, m_end, state
    end
    entity_t.restore_poseparam = function(self)
        self:set_poseparam(0, -180, 180)
        self:set_poseparam(12, -90, 90)
        self:set_poseparam(6, 0, 1, 0)
        self:set_poseparam(7, -180, 180)
    end
end

do
    ---@return "Stand"|"Move"|"Air"|"Air duck"|"Duck"|nil
    entity_t.get_condition = function(self)
        local velocity = #self.m_vecVelocity
        local is_on_ground = self:is_on_ground()
        local is_ducking = self.m_flDuckAmount > 0.25
        if velocity < 2 and is_on_ground then
            if is_ducking then
                return "Duck"
            end
            return "Stand"
        elseif velocity >= 2 and is_on_ground then
            if is_ducking then
                return "Duck"
            end
            return "Move"
        elseif velocity >= 2 and not is_on_ground then
            if is_ducking then
                return "Air duck"
            end
            return "Air"
        end
    end
end

---@return { network_name: string, class_id: number }?
entity_t.get_client_class = function(self)
    local networkable = self:get_networkable()
    if not networkable then return end
    local client_class = ffi.cast("struct ClientClass**", ffi.cast("uintptr_t*", networkable + 2 * 4)[0] + 1)[0]
    -- if not client_class then return end
    return {
        network_name = ffi.string(client_class.network_name),
        class_id = client_class.class_id,
    }
end

local is_breakable_fn = ffi.cast("bool(__thiscall*)(void*)",
    utils.find_pattern("client", "55 8B EC 51 56 8B F1 85 F6 74 68")) or error("can't find is_breakable")
entity_t.is_breakable = function(self)
    local ptr = ffi.cast("void*", self[0])
    if is_breakable_fn(ptr) then
        return true
    end
    -- local client_class = self:get_client_class()
    -- if not client_class then
    --     return false
    -- end
    return false
end

-- entity_t.is_player = function(self)
--     return self:get_client_class().class_id == 40
-- end

-- entity_t.is_weapon = function(self)
--     return self:get_class():IsWeapon()
-- end

---@return { mins: vec3_t, maxs: vec3_t }
entity_t.get_collideable = function(self)
    local collideable = CCollideable(self:get_class():GetCollideable())
    local mins = collideable:OBBMins()
    local maxs = collideable:OBBMaxs()
    return {
        mins = v3(mins),
        maxs = v3(maxs),
    }
end

entity_t.is_grenade = function(self)
    return self:get_grenade_type() ~= nil
end

entity_t.is_alive = function(self)
    local alive = self.m_iHealth > 0
    local player_resource = entitylist.get_player_resource()
    if not player_resource then return alive end
    return alive and player_resource.m_bAlive[self:get_index()]
end

entity_t.can_shoot = function(self)
    local tickbase = self.m_nTickBase * globals.interval_per_tick
    if self.m_flNextAttack > tickbase then
        return false
    end
    local weapon = self:get_weapon()
    if not weapon then return false end
    if weapon.entity.m_flNextPrimaryAttack > tickbase then
        return false
    end
    if weapon.entity.m_flNextSecondaryAttack > tickbase then
        return false
    end
    return true
end

do
    local ccsplayer = ffi.cast("int*", utils.find_pattern("client", "55 8B EC 83 E4 F8 83 EC 18 56 57 8B F9 89 7C 24 0C", 0x47) or error("wrong ccsplayer sig"))
    local raw_get_abs_origin = ffi.cast("float*(__thiscall*)(void*)", ffi.cast("int*", ccsplayer[0] + 0x28)[0])
    ---@return vec3_t?
    entity_t.get_abs_origin = function(self)
        local address = self[0]
        if address == 0 then return end
        local origin = raw_get_abs_origin(ffi.cast("void*", address))
        return v3(origin[0], origin[1], origin[2])
    end
end

entity_t.get_eye_pos = function(self)
    return self:get_origin() + self.m_vecViewOffset
end

local IEngineServerStringTable = interface.new("engine", "VEngineClientStringTable001", {
    FindTable = { 3, "void*(__thiscall*)(void*, PCSTR)" }
})
local PrecachedTableClass = class.new({
    AddString = { 8, "int(__thiscall*)(void*, bool, PCSTR, int, const void*)" }
})
-- local imdlcache_raw = se.create_interface("datacache.dll", "MDLCache004") or error("couldn't find MDLCache004")
-- local imdlcache_vmt = hooks.vmt.new(imdlcache_raw)
-- local findmdl
-- findmdl = imdlcache_vmt:hookMethod("unsigned short(__thiscall*)(void*, char*)", function(thisptr, path)
--     print("TEST")
--     return findmdl(thisptr, path)
-- end, 10)
-- cbs.unload(function ()
--     imdlcache_vmt:unHookAll()
-- end)
---@param path string
---@return number
local precache_model = errors.handler(function(path)
    local rawprecache_table = IEngineServerStringTable:FindTable("modelprecache") or
        error("couldnt find modelprecache", 2)
    if rawprecache_table and rawprecache_table ~= nil then
        local precache_table = PrecachedTableClass(rawprecache_table)
        if precache_table then
            IModelInfoClient:FindOrLoadModel(path)
            local idx = precache_table:AddString(false, path, -1, nil)
            return idx
        end
    end
    return -1
end, "precache_model")
---@param self entity_t
---@param path string
entity_t.set_model = errors.handler(function(self, path)
    local index = IModelInfoClient:GetModelIndex(path)
    if index == -1 then
        index = precache_model(path)
    end
    if index == -1 then
        error("couldn't precache model")
    end
    local ragdoll = self.m_hRagdoll
    if ragdoll and ragdoll ~= nil then
        local cbaseentity = ragdoll:get_class()
        if cbaseentity then
            cbaseentity:SetModelIndex(index)
        end
    end
    local cbaseentity = self:get_class()
    if cbaseentity then
        cbaseentity:SetModelIndex(index)
    end
end, "entity_t.set_model")

---@return { handle: any, name: any, load_flags: number, server_count: number, type: number, flags: number, mins: vec3_t, maxs: vec3_t, radius: number }
entity_t.get_model = function(self)
    return ffi.cast("model_t**", self[0x6C])[0]
end


if not pcall(ffi.typeof, "animlayer_t") then
    ffi.cdef [[
        typedef struct {
            char pad0x0[ 20 ];
            int	order;
            int	sequence;
            float previous_cycle;
            float weight;
            float weight_delta_rate;
            float playback_rate;
            float cycle;
            void* owner;
            char pad0x1[ 4 ];
        } animlayer_t;
    ]]
end
---@param index number
---@return { order: number, sequence: number, previous_cycle: number, weight: number, weight_delta_rate: number, playback_rate: number, cycle: number }?
entity_t.get_animlayer = function(self, index)
    return ffi.cast("animlayer_t**", self[0x2990])[0][index]
end

---@param attacker entity_t
---@param extrapolate_ticks? number
entity_t.is_hittable_by = function(self, attacker, extrapolate_ticks)
    --!SELF IS THE VICTIM
    --!IN BEST CASE ATTACKER SHOULD BE THE LOCAL PLAYER
    if extrapolate_ticks == nil then
        extrapolate_ticks = 0
    end
    local interval = globals.interval_per_tick * extrapolate_ticks
    local from = attacker:get_eye_pos() + attacker.m_vecVelocity * interval + v3(0, 0, 10)
    local to = self:get_player_hitbox_pos(0)
    if not to then return end
    local trace_result = engine.trace_line(from, to, attacker, 0x46004003)
    if trace_result.entity:get_index() == self:get_index() then
        return true
    end
    return false
end

local cached_ranks = {}
entity_t.set_rank = function(self, rank)
    local index = self:get_index()
    local playerresource = entitylist.get_player_resource()
    if not playerresource then return end
    local info = self:get_info()
    if not info then return end
    local id = info.user_id
    if not cached_ranks[id] then
        cached_ranks[id] = {
            real = playerresource.m_nPersonaDataPublicLevel[index],
        }
        cached_ranks[id].fake = rank
    end
    if rank == nil then
        rank = cached_ranks[id].real
        cached_ranks[id] = nil
    end
    if playerresource.m_nPersonaDataPublicLevel[index] ~= rank then
        playerresource.m_nPersonaDataPublicLevel[index] = rank
    end
end
cbs.paint(function()
    if not globals.is_connected then
        cached_ranks = {}
        return
    end
    local entities = entitylist.get_entities("CCSPlayer", true, function(player)
        local info = player:get_info()
        if info then
            local userid = info.user_id
            if cached_ranks[userid] then
                player:set_rank(cached_ranks[userid].fake)
            end
        end
    end)
end)
register_callback("unload", function()
    if not engine.is_connected() then
        cached_ranks = {}
        return
    end
    for userid, rank in pairs(cached_ranks) do
        local player = entitylist.get_entity_by_userid(userid)
        if player then
            player:set_rank(rank.real)
        end
    end
end)

---@param cmd? user_cmd_t
entity_t.is_shooting = function(self, cmd)
    local is_shooting = (self.m_iShotsFired >= 1) and not self:can_shoot()
    return is_shooting
end

if not pcall(ffi.typeof, "struct WeaponInfo_t") then
    ffi.cdef [[
        struct WeaponInfo_t{
            char pad1[6];
            uint8_t class;
            char pad2[13];
            int max_clip;
            char pad3[12];
            int max_ammo;
            char pad4[96];
            char* hud_name;
            char* name;
            char pad5[56];
            int type;
            char pad6[4];
            int price;
	        char pad7[8];
	        float cycle_time;
            char pad8[12];
	        bool fullAuto;
	        char pad9[3];
	        int damage;
            float headshot_multiplier;
            float armor_ratio;
            int bullets;
            float penetration;
	        char pad10[8];
            float range;
            float range_modifier;
            float throw_velocity;
        };
    ]]
end
do
    local raw_get_weapon_data = ffi.cast("struct WeaponInfo_t*(__thiscall*)(void*)",
            utils.find_pattern("client", "55 8B EC 81 EC ? ? ? ? 53 8B D9 56 57 8D 8B ? ? ? ? 85 C9 75 04")) or
        error("failed to find get_weapon_data")
    local weapon_groups = {
        "knife",
        "pistols",
        "smg",
        "rifle",
        "shotguns",
        "sniper",
        "rifle",
        "c4",
        "placeholder",
        "grenade",
        "unknown"
    }
    local group_by_name = {
        awp = "awp",
        ssg08 = "scout",
        g3sg1 = "auto",
        scar20 = "auto",
        deagle = "deagle",
        taser = "taser",
        c4 = "c4"
    }
    ---@alias weapon_t { entity: entity_t, class: number, name: string, type: number, group: "knife"|"pistols"|"smg"|"rifle"|"shotguns"|"sniper"|"awp"|"auto"|"deagle"|"taser"|"scout"|"rifle"|"c4"|"placeholder"|"grenade"|"revolver"|"unknown", damage: number, bullets: number, price: number, armor_ratio: number, range: number, range_modifier: number, throw_velocity: number }
    ---@param index? number
    ---@return weapon_t?
    entity_t.get_weapon = function(self, index)
        local weapon
        if index ~= nil then
            weapon = self.m_hMyWeapons[index]
        else
            weapon = self.m_hActiveWeapon
        end
        if not weapon then return end
        local data = raw_get_weapon_data(ffi.cast("void*", weapon[0]))
        local name = ffi.string(data.name):gsub("weapon_", "")
        local group = weapon_groups[data.type + 1]
        if group_by_name[name] then
            group = group_by_name[name]
        end
        if ffi.string(data.hud_name):find("REVOLVER") then
            group = "revolver"
        end
        return {
            entity = weapon,
            class = data.class,
            name = name,
            type = data.type,
            group = group,
            damage = data.damage,
            bullets = data.bullets,
            price = data.price,
            armor_ratio = data.armor_ratio,
            range = data.range,
            range_modifier = data.range_modifier,
            throw_velocity = data.throw_velocity
        }
    end
end

do
    ---@param hitgroup number
    local get_damage_multiplier = function(hitgroup)
        if hitgroup == iengine.hitgroups.head then
            return 4
        end
        if hitgroup == iengine.hitgroups.stomach then
            return 1.25
        end
        if hitgroup == iengine.hitgroups.left_leg or hitgroup == iengine.hitgroups.right_leg then
            return 0.75
        end
        return 1
    end
    ---@param hitgroup number
    ---@param helmet boolean
    local is_armored = function(hitgroup, helmet)
        if hitgroup == iengine.hitgroups.head then
            return helmet
        end
        if hitgroup == iengine.hitgroups.chest
            or hitgroup == iengine.hitgroups.stomach
            or hitgroup == iengine.hitgroups.left_arm
            or hitgroup == iengine.hitgroups.right_arm then
            return true
        end
        return false
    end
    ---@param hitgroup number
    ---@param attacker entity_t
    ---@param weapon weapon_t
    ---@return number?
    entity_t.get_max_damage = function(self, attacker, hitgroup, weapon)
        if not weapon or not hitgroup then return end
        local start_pos = attacker:get_eye_pos()
        local hitbox_pos = self:get_player_hitbox_pos(iengine.hitgroup_to_hitbox(hitgroup))
        if not hitbox_pos then return end
        local end_pos = start_pos + start_pos:angle_to(hitbox_pos):to_vec() * weapon.range
        local trace_info = engine.trace_line(start_pos, end_pos, attacker, 0x46004003)
        local is_taser = weapon.group == "taser"
        local range = math.pow(weapon.range_modifier, trace_info.fraction * weapon.range / 500)
        local multiplier = (not is_taser) and get_damage_multiplier(hitgroup) or 1
        local damage = weapon.damage * multiplier * range
        local armor_ratio = weapon.armor_ratio / 2
        if not is_taser and is_armored(hitgroup, self.m_bHasHelmet) then
            local armor_value = self.m_ArmorValue
            local armor
            if armor_value < damage * armor_ratio / 2 then
                armor = armor_value * 4
            else
                armor = damage
            end
            damage = damage - armor * (1 - armor_ratio)
        end
        return damage
    end
end

local netvar_table_list = {
    "DT_BaseEntity", "DT_BasePlayer", "DT_BaseAnimating", "DT_CSRagdoll"
}
do
    local current_client_class = IBaseClient:GetAllClasses()
    while current_client_class ~= nil do
        local recv_table = current_client_class.recv_table
        if recv_table and recv_table.name then
            local name = ffi.string(recv_table.name)
            netvar_table_list[#netvar_table_list + 1] = name
        end
        current_client_class = current_client_class.next
    end
end

---@alias __netvar_t { type: string, offset: number, table_type?: string }
---@type table<string, __netvar_t>
local netvar_cache = {
    m_flPoseParameter = { type = "table" },
    m_flEncodedController = { type = "table" },
    m_flexWeight = { type = "table" },
    m_iAmmo = { type = "table" },
    m_bCPIsVisible = { type = "table" },
    m_flLazyCapPerc = { type = "table" },
    m_iTeamIcons = { type = "table" },
    m_iTeamOverlays = { type = "table" },
    m_iTeamReqCappers = { type = "table" },
    m_flTeamCapTime = { type = "table" },
    m_iPreviousPoints = { type = "table" },
    m_bTeamCanCap = { type = "table" },
    m_iTeamBaseIcons = { type = "table" },
    m_iBaseControlPoints = { type = "table" },
    m_bInMiniRound = { type = "table" },
    m_iWarnOnCap = { type = "table" },
    m_flPathDistance = { type = "table" },
    m_iNumTeamMembers = { type = "table" },
    m_iCappingTeam = { type = "table" },
    m_iTeamInZone = { type = "table" },
    m_bBlocked = { type = "table" },
    m_iOwner = { type = "table" },
    m_iMatchStats_Kills = { type = "table" },
    m_iMatchStats_Damage = { type = "table" },
    m_iMatchStats_EquipmentValue = { type = "table" },
    m_iMatchStats_MoneySaved = { type = "table" },
    m_iMatchStats_KillReward = { type = "table" },
    m_iMatchStats_LiveTime = { type = "table" },
    m_iMatchStats_Deaths = { type = "table" },
    m_iMatchStats_Assists = { type = "table" },
    m_iMatchStats_HeadShotKills = { type = "table" },
    m_iMatchStats_Objective = { type = "table" },
    m_iMatchStats_CashEarned = { type = "table" },
    m_iMatchStats_UtilityDamage = { type = "table" },
    m_iMatchStats_EnemiesFlashed = { type = "table" },
    m_hMyWeapons = { type = "table" },
    m_nPersonaDataPublicLevel = { type = "table" },
    m_bAlive = { type = "table" },
    m_iDeaths = { type = "table" },
    m_iPing = { type = "table" },
    m_iKills = { type = "table" },
    m_iAssists = { type = "table" },
    m_bConnected = { type = "table" },
    m_ArmorValue = { type = "int" },
    m_vecViewOffset = {
        type = "vector",
        offset = 264
    },
    m_fLastShotTime = { type = "float" },
    m_nGrenadeSpawnTime = {
        type = "float",
        offset = engine.get_netvar_offset("DT_BaseCSGrenadeProjectile", "m_vecExplodeEffectOrigin") + 12
    },
    m_vecVelocity = {
        type = "vector",
        offset = engine.get_netvar_offset("DT_BasePlayer", "m_vecVelocity[0]") + 0
    }
}
local netvar_types = {
    b = "bool",
    i = "int",
    f = "float",
    v = "vector",
    a = "angle",
    h = "entity",
    n = "int"
}
local netvar_offsets = {
    bool = 1,
    int = 4,
    float = 4,
    vector = 4 * 3,
    angle = 4 * 3
}

---@param netvar string
---@return __netvar_t?
local initialize_netvar = function(netvar)
    if netvar_cache[netvar] and netvar_cache[netvar].offset then
        return netvar_cache[netvar]
    end
    for _, table_name in pairs(netvar_table_list) do
        local offset = engine.get_netvar_offset(table_name, netvar)
        if offset and offset ~= 0 then
            local netvar_type = netvar_types[netvar:sub(3, 3)]
            if netvar_type == "float" and netvar:sub(3, 4) ~= "fl" then
                netvar_type = "int"
            end
            if netvar_cache[netvar] then
                if netvar_cache[netvar].type == "table" then
                    netvar_cache[netvar] = {
                        offset = offset,
                        type = "table",
                        table_type = netvar_type
                    }
                    return netvar_cache[netvar]
                end
                if netvar_cache[netvar].type then
                    netvar_type = netvar_cache[netvar].type
                end
            end
            netvar_cache[netvar] = {
                offset = offset,
                type = netvar_type
            }
            return netvar_cache[netvar]
        end
    end
end

do
    local get_typed_pointer = function(netvar_type, pointer)
        if netvar_type == "int" or netvar_type == "float" or netvar_type == "bool" then
            return ffi.cast(netvar_type .. "*", pointer)
        end
        if netvar_type == "entity" then
            return {[0] = entitylist.get_entity_from_handle(ffi.cast("int*", pointer)[0])}
        end
        if netvar_type == "vector" or netvar_type == "angle" then
            local vec = ffi.cast("vector_t*", pointer)
            if not vec then return error("couldn't get " .. netvar_type .. " netvar: " .. pointer) end
            if netvar_type == "angle" then
                return {[0] = angle_t.new(vec.x, vec.y, vec.z)}
            end
            return {[0] = v3(vec.x, vec.y, vec.z)}
        end
        return error("unknown netvar type: " .. netvar_type)
    end
    local set_netvar_value = function(netvar_type, pointer, value)
        if not value then return end
        if netvar_type == "int" or netvar_type == "float" or netvar_type == "bool" then
            get_typed_pointer(netvar_type, pointer)[0] = value
            return value
        end
        if netvar_type == "vector" or netvar_type == "angle" then
            if value.x == nil or value.y == nil or value.z == nil then
                return error("vector or angle expected")
            end
            local vec = ffi.cast("vector_t*", pointer)
            if not vec then return error("couldn't get " .. netvar_type .. " netvar: " .. pointer) end
            vec.x, vec.y, vec.z = value.x, value.y, value.z
            return value
        end
        return error("unknown netvar type: " .. netvar_type)
    end
    local netvar_table_mt = {
        ---@param self { netvar: __netvar_t, entity: entity_t }
        __index = errors.handler(function(self, key)
            if type(key) ~= "number" then
                error("netvar table index must be a number")
            end
            local offset = self.netvar.offset + key * netvar_offsets[self.netvar.table_type]
            return get_typed_pointer(self.netvar.table_type, self.entity[offset])[0]
        end, "netvar_table_t.__index"),
        __newindex = function(self, key, value)
            if type(key) ~= "number" then
                error("netvar table index must be a number")
            end
            local offset = self.netvar.offset + key * netvar_offsets[self.netvar.table_type]
            return set_netvar_value(self.netvar.table_type, self.entity[offset], value)
        end
    }
    local netvar_table_t = {
        new = function(entity, netvar)
            return setmetatable({
                netvar = netvar,
                entity = entity,
            }, netvar_table_mt)
        end
    }

    ---@param prop string
    entity_t.__get_prop = errors.handler(function(self, prop)
        local netvar = initialize_netvar(prop)
        if not netvar then
            error("failed to init " .. prop .. " netvar")
        end
        if netvar.type == "table" then
            return netvar_table_t.new(self, netvar)
        end
        return get_typed_pointer(netvar.type, self[netvar.offset])[0]
    end, "entity_t.__get_prop")
    ---@param prop string
    ---@param value any
    entity_t.__set_prop = errors.handler(function(self, prop, value)
        local netvar = initialize_netvar(prop)
        if not netvar then
            error("failed to init " .. prop .. " netvar")
        end
        if netvar.type == "table" then
            error("cannot set netvar table")
        end
        return set_netvar_value(netvar.type, self[netvar.offset], value)
    end, "entity_t.__set_prop")
    local entity_mt
    local initialize_entity_mt = function()
        local lp = entitylist.get_local_player()
        if not lp then return end
        entity_mt = getmetatable(lp)
        local old_index = entity_mt.__index
        ---@param self entity_t
        entity_mt.__index = function(self, key)
            if type(key) == "number" then return old_index(self, key) end
            local result = entity_t[key]
            if result then return result end
            return entity_t.__get_prop(self, key)
        end
        ---@param self entity_t
        entity_mt.__newindex = function(self, key, value)
            if type(key) == "number" then error("cannot set entity index") end
            -- local result = entity_t[key]
            -- if result then error("cannot set entity property") end
            return entity_t.__set_prop(self, key, value)
        end
    end

    if not entity_mt then
        initialize_entity_mt()
        if not entity_mt then
            cbs.paint(function()
                if not entity_mt then initialize_entity_mt() end
            end)
            cbs.frame_stage(function()
                if not entity_mt then initialize_entity_mt() end
            end)
            cbs.create_move(function()
                if not entity_mt then initialize_entity_mt() end
            end)
        end
    end
end
