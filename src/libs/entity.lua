local v2, v3 = require("libs.vectors")()
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local interface, class = require("libs.interfaces")()
-- local hooks = require("libs.hooks")
local ffi = require("libs.protected_ffi")

---@class entity_t
---@field m_bEligibleForScreenHighlight number 
---@field m_flMaxFallVelocity number 
---@field m_flLastMadeNoiseTime number 
---@field m_flUseLookAtAngle number 
---@field m_flFadeScale number 
---@field m_fadeMaxDist number 
---@field m_fadeMinDist number 
---@field m_bIsAutoaimTarget number 
---@field m_bSpottedByMask table 
---@field m_bSpottedBy table 
---@field m_bSpotted number 
---@field m_bAlternateSorting number 
---@field m_bAnimatedEveryTick number 
---@field m_bSimulatedEveryTick number 
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
---@field m_blinktoggle number 
---@field m_flexWeight table 
---@field m_nWaterLevel number 
---@field m_flDuckSpeed number 
---@field m_flDuckAmount number 
---@field m_bShouldDrawPlayerWhileUsingViewEntity number 
---@field m_hViewEntity entity_t 
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
---@field m_bCameraManScoreBoard number 
---@field m_bCameraManOverview number 
---@field m_bCameraManXRay number 
---@field m_bActiveCameraMan number 
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
---@field m_bConstraintPastRadius number 
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
---@field m_bAllowAutoMovement number 
---@field m_flStepSize number 
---@field m_bPoisoned number 
---@field m_bWearingSuit number 
---@field m_bDrawViewmodel number 
---@field m_aimPunchAngleVel vec3_t 
---@field m_aimPunchAngle vec3_t 
---@field m_viewPunchAngle vec3_t 
---@field m_flFallVelocity number 
---@field m_nJumpTimeMsecs number 
---@field m_nDuckJumpTimeMsecs number 
---@field m_nDuckTimeMsecs number 
---@field m_bInDuckJump number 
---@field m_flLastDuckTime number 
---@field m_bDucking number 
---@field m_bDucked number 
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
---@field m_bIsSpawnRappelling number 
---@field m_bHideTargetID number 
---@field m_flThirdpersonRecoil number 
---@field m_bStrafing number 
---@field m_flLowerBodyYawTarget number 
---@field m_unTotalRoundDamageDealt number 
---@field m_iNumRoundKillsHeadshots number 
---@field m_bIsLookingAtWeapon number 
---@field m_bIsHoldingLookAtWeapon number 
---@field m_nDeathCamMusic number 
---@field m_nLastConcurrentKilled number 
---@field m_nLastKillerIndex number 
---@field m_bHud_RadarHidden number 
---@field m_bHud_MiniScoreHidden number 
---@field m_bIsAssassinationTarget number 
---@field m_flAutoMoveTargetTime number 
---@field m_flAutoMoveStartTime number 
---@field m_vecAutomoveTargetEnd vec3_t 
---@field m_iControlledBotEntIndex number 
---@field m_bCanControlObservedBot number 
---@field m_bHasControlledBotThisRound number 
---@field m_bIsControllingBot number 
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
---@field m_nHeavyAssaultSuitCooldownRemaining number 
---@field m_bHasHeavyArmor number 
---@field m_bHasHelmet number 
---@field m_unMusicID number 
---@field m_bHasParachute number 
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
---@field m_bIsPlayerGhost number 
---@field m_flDetectedByEnemySensorTime number 
---@field m_flGuardianTooFarDistFrac number 
---@field m_isCurrentGunGameTeamLeader number 
---@field m_isCurrentGunGameLeader number 
---@field m_bCanMoveDuringFreezePeriod number 
---@field m_flGroundAccelLinearFracLastTime number 
---@field m_bIsRescuing number 
---@field m_hCarriedHostageProp entity_t 
---@field m_hCarriedHostage entity_t 
---@field m_szArmsModel string 
---@field m_fMolotovDamageTime number 
---@field m_fMolotovUseTime number 
---@field m_iNumRoundKills number 
---@field m_iNumGunGameKillsWithCurrentWeapon number 
---@field m_iNumGunGameTRKillPoints number 
---@field m_iGunGameProgressiveWeaponIndex number 
---@field m_bMadeFinalGunGameProgressiveKill number 
---@field m_bHasMovedSinceSpawn number 
---@field m_bGunGameImmunity number 
---@field m_fImmuneToGunGameDamageTime number 
---@field m_bResumeZoom number 
---@field m_nIsAutoMounting number 
---@field m_bIsWalking number 
---@field m_bIsScoped number 
---@field m_iBlockingUseActionInProgress number 
---@field m_bIsGrabbingHostage number 
---@field m_bIsDefusing number 
---@field m_bInHostageRescueZone number 
---@field m_bHasNightVision number 
---@field m_bNightVisionOn number 
---@field m_bHasDefuser number 
---@field m_angEyeAngles vec3_t 
---@field m_ArmorValue number 
---@field m_iClass number 
---@field m_iMoveState number 
---@field m_bKilledByTaser number 
---@field m_bInNoDefuseArea number 
---@field m_bInBuyZone number 
---@field m_bInBombZone number 
---@field m_totalHitsOnServer number 
---@field m_iStartAccount number 
---@field m_iAccount number 
---@field m_iPlayerState number 
---@field m_bIsRespawningForDMBonus number 
---@field m_bWaitForNoAttack number 
---@field m_iThrowGrenadeCounter number 
---@field m_iSecondaryAddon number 
---@field m_iPrimaryAddon number 
---@field m_iAddonBits number 
---@field m_iWeaponPurchasesThisMatch table 
---@field m_nQuestProgressReason number 
---@field m_unActiveQuestId number 
---@field m_iWeaponPurchasesThisRound table 
---@field m_bPlayerDominatingMe table 
---@field m_bPlayerDominated table 
---@field m_flVelocityModifier number 
---@field m_bDuckOverride number 
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

local IClientEntityList = interface.new("client", "VClientEntityList003", {
    GetClientEntity = {3, "uintptr_t(__thiscall*)(void*, int)"},
})
local CBaseEntity = class.new({
    GetCollideable = {3, "uintptr_t(__thiscall*)(void*)"},
    GetNetworkable = {4, "uintptr_t(__thiscall*)(void*)"},
    GetClientRenderable = {5, "uintptr_t(__thiscall*)(void*)"},
    GetClientEntity = {6, "uintptr_t(__thiscall*)(void*)"},
    GetBaseEntity = {7, "uintptr_t(__thiscall*)(void*)"},
    GetClientThinkable = {8, "uintptr_t(__thiscall*)(void*)"},
    SetModelIndex = {75, "void(__thiscall*)(void*,int)"},
    IsPlayer = {158, "bool(__thiscall*)(void*)"},
    IsWeapon = {166, "bool(__thiscall*)(void*)"},
})
--check if clientclass struct exists
if not pcall(ffi.typeof, "struct ClientClass") then
    ffi.cdef[[
        struct ClientClass {
            void*   m_pCreateFn;
            void*   m_pCreateEventFn;
            char*   network_name;
            void*   m_pRecvTable;
            void*   m_pNext;
            int     class_id;
        };
    ]]
end
local CClientNetworkable = class.new({
    -- GetClientUnknown = {0, "uintptr_t(__thiscall*)(void*)"},
    -- GetClientClass = {2, "struct ClientClass*(__thiscall*)(void*)"},
})

---@param index number
---@return ffi.ctype*
entitylist.get_client_entity = function(index)
    ---@diagnostic disable-next-line: undefined-field
    return IClientEntityList:GetClientEntity(index)
end
local entitylist_get_players_o = entitylist.get_players
entitylist.get_players = function (type)
    local players = entitylist_get_players_o(type)
    local new = {}
    for i = 1, #players do
        new[i] = players[i]
    end
    return new
end
---@param steam_id string
---@return entity_t?
entitylist.get_entity_by_steam_id = function (steam_id)
    for _, player in pairs(entitylist.get_players(2)) do
        if player:get_info().steam_id64 == steam_id then
            return player
        end
    end
end
---@param userid number
---@return entity_t?
entitylist.get_entity_by_userid = function (userid)
    for _, player in pairs(entitylist.get_players(2)) do
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
---@return entity_t?
entitylist.get_player_resource = function()
    return entitylist.get_entities_by_class_name("CCSPlayerResource")[1]
    -- for i = 0, entitylist.get_highest_entity_index() do
    --     local entity = entitylist.get_entity_by_index(i)
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
entity_t.get_flag = function (self, flag)
    return bit.band(self.m_fFlags, flag) ~= 0
end

---@return boolean
entity_t.is_on_ground = function (self)
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

entity_t.update = function(self)
    return entitylist.get_entity_by_index(self:get_index())
end

entity_t.get_info = function (self)
    return engine.get_player_info(self:get_index())
end

do
    ---@return "flashbang"|"he"|"smoke"|"decoy"|"molotov"|nil
    entity_t.get_grenade_type = function(self)
        local client_class = self:get_client_class()
        if not client_class then return end
        local index = client_class.class_id
        local name
        if index == 9 then
            local model = self:get_model()
            if not model then return end
            local model_name = ffi.string(model.name)
            if not model_name:find("fraggrenade_dropped") then
                name = "flashbang"
            else
                name = "he"
            end
        elseif index == 157 then
            name = "smoke"
        elseif index == 48 then
            name = "decoy"
        elseif index == 114 then -- class name CIncendiaryGrenade
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
            ticks[id] = 0 end
        return ticks[id]
    end
    cbs.create_move(function()
        for _, entity in pairs(entitylist.get_players(2)) do
            if entity then
                local info = entity:get_info()
                if info then
                    local id = info.user_id
                    if not ticks[id] then
                        ticks[id] = 0
                    end
                    if entity:is_dormant() then
                        ticks[id] = ticks[id] + 1
                    else
                        ticks[id] = 0
                    end
                end
            end
        end
    end)
    cbs.event("round_prestart", function ()
        for k, _ in pairs(ticks) do
            ticks[k] = math.huge
        end
    end)
end

entity_t.get_class = function (self)
    return CBaseEntity(self[0])
end

entity_t.get_networkable = function (self)
    return ffi.cast("uintptr_t*", self[0] + 8)[0]
end

entity_t.get_studio_hdr = function(self)
    local studio_hdr = ffi.cast("void**", self[0] + 0x2950) or error("failed to get studio_hdr")
    studio_hdr = studio_hdr[0] or error("failed to get studio_hdr")
    return studio_hdr
end

if not pcall(ffi.typeof, "m_flposeparameter_t") then
    ffi.cdef[[
        typedef struct {
            char pad[8];
	        float m_start;
	        float m_end;
            float m_state;
        } m_flposeparameter_t;
    ]]
end
do
    local get_poseparam_sig = client.find_pattern('client.dll', '55 8B EC 8B 45 08 57 8B F9 8B 4F 04 85 C9 75 15')
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
entity_t.get_client_class = function (self)
    local networkable = self:get_networkable()
    if not networkable then return end
    local client_class = ffi.cast("struct ClientClass**", ffi.cast("uintptr_t*", networkable + 2 * 4)[0] + 1)[0]
    -- if not client_class then return end
    return {
        network_name = ffi.string(client_class.network_name),
        class_id = client_class.class_id,
    }
end

local is_breakable_fn = ffi.cast("bool(__thiscall*)(void*)", client.find_pattern("client.dll", "55 8B EC 51 56 8B F1 85 F6 74 68")) or error("can't find is_breakable")
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

entity_t.is_player = function(self)
    return self:get_client_class().class_id == 40
end

entity_t.is_weapon = function(self)
    return self:get_class():IsWeapon()
end

entity_t.is_grenade = function(self)
    return self:get_grenade_type() ~= nil
end

entity_t.is_player_alive = function(self)
    local alive = self:is_alive()
    local player_resource = entitylist.get_player_resource()
    if not player_resource then return alive end
    return alive and player_resource.m_bAlive[self:get_index()]
end

entity_t.can_shoot = function (self)
    local tickbase = self.m_nTickBase * globalvars.get_interval_per_tick()
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
    local ccsplayer = ffi.cast("int*",
        (client.find_pattern("client.dll", "55 8B EC 83 E4 F8 83 EC 18 56 57 8B F9 89 7C 24 0C") or error("wrong ccsplayer sig")) + 0x47)
    local raw_get_abs_origin = ffi.cast("float*(__thiscall*)(void*)", ffi.cast("int*", ccsplayer[0] + 0x28)[0])
    ---@return vec3_t?
    entity_t.get_abs_origin = function (self)
        local address = self[0]
        if address == 0 then return end
        local origin = raw_get_abs_origin(ffi.cast("void*", address))
        return v3(origin[0], origin[1], origin[2])
    end
end

entity_t.get_eye_pos = function(self)
    return self:get_abs_origin() + self.m_vecViewOffset
end

if not pcall(ffi.typeof, "model_t") then
    ffi.cdef[[
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
    GetModelIndex = {2, "int(__thiscall*)(void*, PCSTR)"},
    FindOrLoadModel = {39, "const model_t(__thiscall*)(void*, PCSTR)"}
})
local IEngineServerStringTable = interface.new("engine", "VEngineClientStringTable001", {
    FindTable = {3, "void*(__thiscall*)(void*, PCSTR)"}
})
local PrecachedTableClass = class.new({
    AddString = {8, "int(__thiscall*)(void*, bool, PCSTR, int, const void*)"}
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
    local rawprecache_table = IEngineServerStringTable:FindTable("modelprecache") or error("couldnt find modelprecache", 2)
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
    if ragdoll then
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
    return ffi.cast("model_t**", self[0] + 0x6C)[0]
end


if not pcall(ffi.typeof, "animlayer_t") then
    ffi.cdef[[
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
    local address = self[0]
    if address == 0 then return end
    return ffi.cast("animlayer_t**", address + 0x2990)[0][index]
end

---@param attacker entity_t
---@param extrapolate_ticks? number
entity_t.is_hittable_by = function(self, attacker, extrapolate_ticks)
    --!SELF IS THE VICTIM
    --!IN BEST CASE ATTACKER SHOULD BE THE LOCAL PLAYER
    if extrapolate_ticks == nil then
        extrapolate_ticks = 0
    end
    local interval = globalvars.get_interval_per_tick() * extrapolate_ticks
    local from = attacker:get_eye_pos() + attacker.m_vecVelocity * interval + v3(0, 0, 10)
    local to = self:get_player_hitbox_pos(0)
    if not to then return end
    local trace_result = trace.line(attacker:get_index(), 0x46004003, from, to)
    if trace_result.hit_entity_index == self:get_index() then
        return true
    end
    return false
end

local cached_ranks = {}
entity_t.set_rank = function(self, rank)
    local index = self:get_index()
    local playerresource = entitylist.get_entities_by_class_id(41)[1]
    if not playerresource then return end
    local info = self:get_info()
    if not info then return end
    local userid = info.user_id
    if not cached_ranks[userid] then
        cached_ranks[userid] = {
            real = playerresource.m_nPersonaDataPublicLevel[index],
        }
        cached_ranks[userid].fake = rank
    end
    if rank == nil then
        rank = cached_ranks[userid].real
        cached_ranks[userid] = nil
    end
    if playerresource.m_nPersonaDataPublicLevel[index] ~= rank then
        playerresource.m_nPersonaDataPublicLevel[index] = rank
    end
end
client.register_callback("paint", function ()
    if not engine.is_connected() then
        cached_ranks = {}
        return
    end
    for _, player in pairs(entitylist.get_players(2)) do
        local info = player:get_info()
        if info then
            local userid = info.user_id
            if cached_ranks[userid] then
                player:set_rank(cached_ranks[userid].fake)
            end
        end
    end
end)
client.register_callback("unload", function ()
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

---@param cmd? usercmd_t
entity_t.is_shooting = function(self, cmd)
    local is_shooting = (self.m_iShotsFired >= 1) and not self:can_shoot()
    return is_shooting
end

if not pcall(ffi.typeof, "struct WeaponInfo_t") then
    ffi.cdef[[
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
        };
    ]]
end
do
    local raw_get_weapon_data = ffi.cast("struct WeaponInfo_t*(__thiscall*)(void*)", client.find_pattern("client.dll", "55 8B EC 81 EC ? ? ? ? 53 8B D9 56 57 8D 8B ? ? ? ? 85 C9 75 04")) or error("failed to find get_weapon_data")
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
    ---@param index? number
    ---@return { entity: entity_t, class: number, name: string, type: number, group: "knife"|"pistols"|"smg"|"rifle"|"shotguns"|"sniper"|"awp"|"auto"|"deagle"|"taser"|"scout"|"rifle"|"c4"|"placeholder"|"grenade"|"revolver"|"unknown" }?
    entity_t.get_weapon = function (self, index)
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
            group = group_by_name[name] end
        if ffi.string(data.hud_name):find("REVOLVER") then
            group = "revolver" end
        return {
            entity = weapon,
            class = data.class,
            name = name,
            type = data.type,
            group = group,
        }
    end
end

local netvar_table_list = {
    "AI_BaseNPC",
    "WeaponAK47",
    "BaseAnimating", "BaseAnimatingOverlay", "BaseAttributableItem", "BaseButton", "BaseCombatCharacter",
    "BaseCombatWeapon", "BaseCSGrenade", "BaseCSGrenadeProjectile", "BaseDoor", "BaseEntity",
    "BaseFlex", "BaseGrenade", "BaseParticleEntity", "BasePlayer", "BasePropDoor",
    "BaseTeamObjectiveResource", "BaseTempEntity", "BaseToggle", "BaseTrigger", "BaseViewModel",
    "BaseVPhysicsTrigger", "BaseWeaponWorldModel",
    "Beam",
    "BeamSpotlight",
    "BoneFollower",
    "BRC4Target",
    "WeaponBreachCharge",
    "BreachChargeProjectile",
    "BreakableProp", "BreakableSurface",
    "WeaponBumpMine",
    "BumpMineProjectile",
    "WeaponC4",
    "CascadeLight",
    "CChicken",
    "ColorCorrection", "ColorCorrectionVolume",
    "CSGameRulesProxy", "CSPlayer", "CSPlayerResource", "CSRagdoll", "CSTeam",
    "DangerZone", "DangerZoneController",
    "WeaponDEagle",
    "DecoyGrenade", "DecoyProjectile",
    "Drone", "Dronegun",
    "DynamicLight", "DynamicProp",
    "EconEntity",
    "WearableItem",
    "Embers",
    "EntityDissolve", "EntityFlame", "EntityFreezing", "EntityParticleTrail",
    "EnvAmbientLight",
    "DetailController",
    "EnvDOFController", "EnvGasCanister", "EnvParticleScript", "EnvProjectedTexture",
    "QuadraticBeam",
    "EnvScreenEffect", "EnvScreenOverlay", "EnvTonemapController",
    "EnvWind",
    "FEPlayerDecal",
    "FireCrackerBlast", "FireSmoke", "FireTrail",
    "CFish",
    "WeaponFists",
    "Flashbang",
    "FogController",
    "FootstepControl",
    "Func_Dust", "Func_LOD", "FuncAreaPortalWindow", "FuncBrush", "FuncConveyor",
    "FuncLadder", "FuncMonitor", "FuncMoveLinear", "FuncOccluder", "FuncReflectiveGlass",
    "FuncRotating", "FuncSmokeVolume", "FuncTrackTrain",
    "GameRulesProxy",
    "GrassBurn",
    "HandleTest",
    "HEGrenade",
    "CHostage",
    "HostageCarriableProp",
    "IncendiaryGrenade",
    "Inferno",
    "InfoLadderDismount", "InfoMapRegion", "InfoOverlayAccessor",
    "Item_Healthshot", "ItemCash", "ItemDogtags",
    "WeaponKnife", "WeaponKnifeGG",
    "LightGlow",
    "MapVetoPickController",
    "MaterialModifyControl",
    "WeaponMelee",
    "MolotovGrenade", "MolotovProjectile",
    "MovieDisplay",
    "ParadropChopper",
    "ParticleFire",
    "ParticlePerformanceMonitor",
    "ParticleSystem",
    "PhysBox", "PhysBoxMultiplayer", "PhysicsProp", "PhysicsPropMultiplayer", "PhysMagnet",
    "PhysPropAmmoBox", "PhysPropLootCrate", "PhysPropRadarJammer", "PhysPropWeaponUpgrade",
    "PlantedC4",
    "Plasma",
    "PlayerPing", "PlayerResource",
    "PointCamera", "PointCommentaryNode", "PointWorldText",
    "PoseController",
    "PostProcessController",
    "Precipitation",
    "PrecipitationBlocker",
    "PredictedViewModel",
    "Prop_Hallucination", "PropCounter", "PropDoorRotating", "PropJeep", "PropVehicleDriveable",
    "RagdollManager", "Ragdoll", "Ragdoll_Attached",
    "RopeKeyframe",
    "WeaponSCAR17",
    "SceneEntity",
    "SensorGrenade", "SensorGrenadeProjectile",
    "ShadowControl",
    "SlideshowDisplay",
    "SmokeGrenade", "SmokeGrenadeProjectile", "SmokeStack",
    "Snowball",
    "SnowballPile", "SnowballProjectile",
    "SpatialEntity",
    "SpotlightEnd",
    "Sprite", "SpriteOriented", "SpriteTrail",
    "StatueProp",
    "SteamJet",
    "Sun",
    "SunlightShadowControl",
    "SurvivalSpawnChopper",
    "WeaponTablet",
    "Team",
    "TeamplayRoundBasedRulesProxy",
    "TEArmorRicochet",
    "ProxyToggle",
    "TestTraceline",
    "TEWorldDecal",
    "TriggerPlayerMovement", "TriggerSoundOperator",
    "VGuiScreen",
    "VoteController",
    "WaterBullet",
    "WaterLODControl",
    "WeaponAug", "WeaponAWP", "WeaponBaseItem", "WeaponBizon", "WeaponCSBase",
    "WeaponCSBaseGun", "WeaponCycler", "WeaponElite", "WeaponFamas", "WeaponFiveSeven",
    "WeaponG3SG1", "WeaponGalil", "WeaponGalilAR", "WeaponGlock", "WeaponHKP2000",
    "WeaponM249", "WeaponM3", "WeaponM4A1", "WeaponMAC10", "WeaponMag7",
    "WeaponMP5Navy", "WeaponMP7", "WeaponMP9", "WeaponNegev", "WeaponNOVA",
    "WeaponP228", "WeaponP250", "WeaponP90", "WeaponSawedoff", "WeaponSCAR20",
    "WeaponScout", "WeaponSG550", "WeaponSG552", "WeaponSG556", "WeaponShield",
    "WeaponSSG08", "WeaponTaser", "WeaponTec9", "WeaponTMP", "WeaponUMP45",
    "WeaponUSP", "WeaponXM1014", "WeaponZoneRepulsor",
    "WORLD",
    "WorldVguiText",
    "DustTrail",
    "MovieExplosion",
    "ParticleSmokeGrenade",
    "RocketTrail",
    "SmokeTrail",
    "SporeExplosion",
    "SporeTrail",
    "AnimTimeMustBeFirst",
    "CollisionProperty"
}
for i = 1, #netvar_table_list do
    netvar_table_list[i] = "DT_" .. netvar_table_list[i]
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
    m_vecViewOffset = {
        type = "vector",
        offset = 264
    },
    m_fLastShotTime = { type = "float" },
    m_nGrenadeSpawnTime = {
        type = "float",
        offset = se.get_netvar("DT_BaseCSGrenadeProjectile", "m_vecExplodeEffectOrigin") + 12
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
    vector = 12,
    angle = 12
}

---@param netvar string
---@return __netvar_t?
local initialize_netvar = function(netvar)
    if netvar_cache[netvar] and netvar_cache[netvar].offset then
        return netvar_cache[netvar]
    end
    for _, table_name in pairs(netvar_table_list) do
        local offset = se.get_netvar(table_name, netvar)
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

local netvar_table_mt = {
    ---@param self { netvar: __netvar_t, entity: entity_t }
    __index = errors.handler(function(self, key)
        if type(key) ~= "number" then
            error("netvar table index must be a number")
        end
        local offset = self.netvar.offset + key * netvar_offsets[self.netvar.table_type]
        if self.netvar.table_type == "entity" then
            return entitylist.get_entity_from_handle(self.entity:get_prop_int(offset))
        end
        return self.entity["get_prop_"..self.netvar.table_type](self.entity, offset)
    end, "netvar_table_t.__index"),
    __newindex = function (self, key, value)
        if type(key) ~= "number" then
            error("netvar table index must be a number")
        end
        local offset = self.netvar.offset + key * netvar_offsets[self.netvar.table_type]
        return self.entity["set_prop_"..self.netvar.table_type](self.entity, offset, value)
    end
}
local netvar_table_t = {
    new = function (entity, netvar)
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
    if netvar.type == "entity" then
        return entitylist.get_entity_from_handle(self:get_prop_int(netvar.offset))
    end
    return self["get_prop_"..netvar.type](self, netvar.offset)
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
    return self["set_prop_"..netvar.type](self, netvar.offset, value)
end, "entity_t.__set_prop")
local entity_mt
local initialize_entity_mt = function()
    local lp = entitylist.get_local_player()
    if not lp then return end
    entity_mt = getmetatable(lp)
    ---@param self entity_t
    entity_mt.__index = function (self, key)
        if key == 0 then return entitylist.get_client_entity(self:get_index()) end
        local result = entity_t[key]
        if result then return result end
        return entity_t.__get_prop(self, key)
    end
    ---@param self entity_t
    entity_mt.__newindex = function (self, key, value)
        if key == 0 then error("cannot set entity index") end
        local result = entity_t[key]
        if result then error("cannot set entity property") end
        return entity_t.__set_prop(self, key, value)
    end
end

if not entity_mt then
    initialize_entity_mt()
    if not entity_mt then
        cbs.frame_stage(function (stage)
            if not entity_mt then initialize_entity_mt() end
        end)
    end
end
