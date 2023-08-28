local ffi = require("libs.protected_ffi")
local errors = require("libs.error_handler")
local iengine = require("includes.engine")
local cbs = require("libs.callbacks")
local col = require("libs.colors")
local hooks = require("libs.hooks")
local voice_data_msg = find_pattern("engine.dll", "55 8B EC 83 E4 F8 A1 ? ? ? ? 81 EC 84 01 00")
ffi.cdef[[
    struct voice_data_t {
		char		pad_0000[8]; //0
		int32_t     client; //8
		int32_t     audible_mask; //12
		uint32_t    xuid_low; //16
		uint32_t    xuid_high; //20
		void*		voice_data; //24
		bool		proximity; //28
		bool		caster; //29
		char		pad_001E[2]; //30
		int32_t     format; //32
		int32_t	    sequence_bytes; //36
		uint32_t    section_number; //40
		uint32_t    uncompressed_sample_offset; //44
		char		pad_0030[4]; //48
		uint32_t    has_bits; //52
	};
    struct voice_communication_t {
        uint32_t    xuid_low; //0
        uint32_t    xuid_high; //4
        int32_t     sequence_bytes; //8
        uint32_t    section_number; //12
        uint32_t    uncompressed_sample_offset; //16
    };
    struct CommunicationString_t {
	    char        szData[16];
	    uint32_t    m_nCurrentLen;
	    uint32_t    m_nMaxLen;
    };
    struct voice_data_msg_t {
        void*       inetmessage_vtable; //0x0000
	    char        pad_0004[4]; //0x0004
	    void*       voicedata_vtable; //0x0008
	    char        pad_000c[8]; //0x000C
	    void*       data; //0x0014
	    uint32_t    xuid_low;
	    uint32_t    xuid_high;
	    int32_t     format; //0x0020
	    int32_t     sequence_bytes; //0x0024
	    uint32_t    section_number; //0x0028
	    uint32_t    uncompressed_sample_offset; //0x002C
	    int32_t     cached_size; //0x0030
	    uint32_t    flags; //0x0034
	    uint8_t     no_stack_overflow[255];
    };
    struct floridahook_shared_esp_data_t{
        uint32_t    id;
        uint8_t     user_id;
        int16_t     origin_x;
        int16_t     origin_y;
        int16_t     origin_z;
        int8_t      health;
    };
]]
local voice_data_construct = ffi.cast("uint32_t(__fastcall*)(struct voice_data_msg_t*, void*)", find_pattern("engine.dll", "56 57 8B F9 8D 4F 08 C7 07 ? ? ? ? E8 ? ? ? ? C7") or error("failed to find voice_data_construct"))
local function send_voice_msg(data)
    if not voice_data_construct then return end
    local msg = ffi.new("struct voice_data_msg_t[1]")
    ffi.fill(msg, ffi.sizeof(msg))
    voice_data_construct(msg, nil)

    local voice_data = ffi.new("struct voice_communication_t[1]")
    ffi.fill(voice_data, ffi.sizeof(voice_data))
    ffi.copy(voice_data, data, ffi.sizeof(data))
    msg[0].xuid_low = voice_data[0].xuid_low
    msg[0].xuid_high = voice_data[0].xuid_high
    msg[0].sequence_bytes = voice_data[0].sequence_bytes
    msg[0].section_number = voice_data[0].section_number
    msg[0].uncompressed_sample_offset = voice_data[0].uncompressed_sample_offset

    local communication_str = ffi.new("struct CommunicationString_t[1]")
    ffi.fill(communication_str, ffi.sizeof(communication_str))
    communication_str[0].m_nMaxLen = 15
    communication_str[0].m_nCurrentLen = 0

    msg[0].data = ffi.cast("void*", communication_str)
    msg[0].format = 0
    msg[0].flags = 63

    iengine.send_net_msg(msg)
    -- print("inetmessage_vtable: " .. tostring(msg[0].inetmessage_vtable))
    -- print("voicedata_vtable: " .. tostring(msg[0].voicedata_vtable))
    -- print("data: " .. tostring(msg[0].data))
    -- print("xuid_low: " .. tostring(msg[0].xuid_low))
    -- print("xuid_high: " .. tostring(msg[0].xuid_high))
    -- print("format: " .. tostring(msg[0].format))
    -- print("sequence_bytes: " .. tostring(msg[0].sequence_bytes))
    -- print("section_number: " .. tostring(msg[0].section_number))
    -- print("uncompressed_sample_offset: " .. tostring(msg[0].uncompressed_sample_offset))
    -- print("cached_size: " .. tostring(msg[0].cached_size))
    -- print("flags: " .. tostring(msg[0].flags))
    -- print("")
end

local function find_duplicate_element(array, divisor)
    local visited_elements = {}

    for current_index = 1, #array do
        local current_element = array[current_index]

        if not visited_elements[current_element] then
            visited_elements[current_element] = true

            for next_index = current_index + 4, #array do
                if current_index % divisor == 0 then
                    if array[next_index] == current_element then
                        return true
                    end
                elseif array[next_index] == current_element then
                    return false
                end
            end
        end
    end

    return false
end
local convert_to_communication_data = function(packet)
    local voice_communication = ffi.new("struct voice_communication_t[1]")
    voice_communication[0].xuid_low = packet.xuid_low
    voice_communication[0].xuid_high = packet.xuid_high
    voice_communication[0].sequence_bytes = packet.sequence_bytes
    voice_communication[0].section_number = packet.section_number
    voice_communication[0].uncompressed_sample_offset = packet.uncompressed_sample_offset
    return voice_communication
end
-- local airflow_packet = ffi.new("struct test_data_t[1]")
-- --57FA to dec
-- airflow_packet[0].id = 0x695B
-- airflow_packet[0].a = 100
-- airflow_packet[0].b = 100
-- airflow_packet[0].c = 100
-- airflow_packet[0].d = 100
-- airflow_packet[0].e = 100
-- airflow_packet[0].f = 100
-- client.register_callback('create_move', function (cmd)
--     if cmd.command_number % 10 == 0 then
        
--     end
-- end)
local voice_data_list = {}
local detector_storage = {
    nl = {
        sig_count = {},
        found = {}
    },
    nw = {},
    pd = {},
    ot = {},
    ft = {},
    pl = {},
    ev = {},
    r7 = {},
    af = {},
    gs = {},
    fl = {},
    we = {},
    pr = {},
}
local icons = {
    af = 2245,
    ev = 2246,
    ft = 2247,
    gs = 2248,
    nl = 2249,
    nw = 2250,
    ot = 2251,
    pd = 2252,
    pl = 2253,
    r7 = 2254,
    fl = 2255,
    we = 2256,
    pr = 2257,
}
---@type table<string, fun(packet: { client: number, audible_mask: number, xuid_low: number, xuid_high: number, voice_data: ffi.cdata*, proximity: boolean, caster: boolean, format: number, sequence_bytes: number, section_number: number, uncompressed_sample_offset: number, has_bits: number }, target: number): boolean?>
local detector_table = {
    nl = function(packet, target)
        if packet.xuid_high == 0 then
            return
        end

        if (detector_storage.fl[target] or 0) > 24 then
            return
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 22)[0])

        if sig == detector_storage.current_signature then
            detector_storage.nl.sig_count[target] = (detector_storage.nl.sig_count[target] or 0) + 1

            if detector_storage.nl.sig_count[target] > 24 then
                detector_storage.nl.found[target] = 1

                return true
            else
                detector_storage.nl.sig_count[target] = nil
            end
        end

        if #detector_storage.nl.found > 3 then
            return false
        end

        if not detector_storage.nl[target] then
            detector_storage.nl[target] = {}
        end

        detector_storage.nl[target][#detector_storage.nl[target] + 1] = packet.xuid_high

        if #detector_storage.nl[target] > 24 then
            if find_duplicate_element(detector_storage.nl[target], 4) and packet.xuid_high ~= 0 then
                detector_storage.current_signature = sig
                detector_storage.nl[target] = {}

                return true
            end

            table.remove(detector_storage.nl[target], 1)
        end

        return false
    end,
    nw = function(packet, target)
        if not detector_storage.nw[target] then
            detector_storage.nw[target] = 0
        end

        if detector_storage.nw[target] > 34 then
            detector_storage.nw[target] = nil
            return true
        elseif packet.xuid_high == 0 then
            detector_storage.nw[target] = detector_storage.nw[target] + 1
        else
            detector_storage.nw[target] = 0
        end

        return false
    end,
    pd = function(packet, target)
        if not detector_storage.pd[target] then
            detector_storage.pd[target] = 0
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])

        if detector_storage.pd[target] > 24 then
            return true
        elseif sig == "695B" or sig == "1B39" then
            detector_storage.pd[target] = detector_storage.pd[target] + 1
        else
            detector_storage.pd[target] = 0
        end

        return false
    end,
    ot = function(packet, target)
        if not detector_storage.ot[target] then
            detector_storage.ot[target] = 0
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])

        if detector_storage.ot[target] > 36 then
            return true
        elseif sig == "57FA" then
            detector_storage.ot[target] = detector_storage.ot[target] + 1
        end

        return false
    end,
    ft = function(packet, target)
        if not detector_storage.ft[target] then
            detector_storage.ft[target] = 0
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])

        if detector_storage.ft[target] > 36 then
            return true
        elseif sig == "7FFA" or sig == "7FFB" then
            detector_storage.ft[target] = detector_storage.ft[target] + 1
        end

        return false
    end,
    pl = function(packet, target)
        if not detector_storage.pl[target] then
            detector_storage.pl[target] = 0
        end

        if detector_storage.pl[target] > 24 then
            return true
        elseif packet.uncompressed_sample_offset == 408409397
            or packet.xuid_low == 907415600
            or packet.xuid_high == 49439746
            or packet.xuid_high == 29713409
            or packet.xuid_high == 38822914 then
            detector_storage.pl[target] = detector_storage.pl[target] + 1
        else
            detector_storage.pl[target] = 0
        end

        return false
    end,
    ev = function(packet, target)
        if not detector_storage.ev[target] then
            detector_storage.ev[target] = 0
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])

        if detector_storage.ev[target] > 36 then
            return true
        elseif sig == "7FFC" or sig == "7FFD" then
            detector_storage.ev[target] = detector_storage.ev[target] + 1
        end

        return false
    end,
    r7 = function(packet, target)
        if not detector_storage.r7[target] then
            detector_storage.r7[target] = 0
        end

        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 16)[0])

        if detector_storage.r7[target] > 24 then
            return true
        elseif sig == "234" or sig == "134" then
            detector_storage.r7[target] = detector_storage.r7[target] + 1
        else
            detector_storage.r7[target] = 0
        end

        return false
    end,
    af = function(packet, target)
        if not detector_storage.af[target] then
            detector_storage.af[target] = 0
        end

        if detector_storage.af[target] > 24 then
            return true
        elseif packet.xuid_low == 3735943921 or packet.xuid_low == 3735924721 then
            detector_storage.af[target] = detector_storage.af[target] + 1
        else
            detector_storage.af[target] = 0
        end

        return false
    end,
    gs = function(packet, target)
        local sig = ("%.02X"):format(ffi.cast("uint16_t*", ffi.cast("uintptr_t", packet) + 22)[0])
        local sequence_bytes = string.sub(packet.sequence_bytes, 1, 4)

        if not detector_storage.gs[target] then
            detector_storage.gs[target] = {
                repeated = 0,
                packet = sig,
                bytes = sequence_bytes
            }
        end

        if sequence_bytes ~= detector_storage.gs[target].bytes and sig ~= detector_storage.gs[target].packet then
            detector_storage.gs[target].packet = sig
            detector_storage.gs[target].bytes = sequence_bytes
            detector_storage.gs[target].repeated = detector_storage.gs[target].repeated + 1
        else
            detector_storage.gs[target].repeated = 0
        end

        if detector_storage.gs[target].repeated >= 36 then
            detector_storage.gs[target] = {
                repeated = 0,
                packet = sig,
                bytes = sequence_bytes
            }

            return true
        end

        return false
    end,
    fl = function(packet, target)
        if not detector_storage.fl[target] then
            detector_storage.fl[target] = 0
        end
        -- local communication = convert_to_communication_data(packet)
        -- local floridahook_info = ffi.cast("struct floridahook_shared_esp_data_t*", communication)[0]
        local id = bit.rshift(bit.band(packet.xuid_low, 0xFF00), 8)
        if detector_storage.fl[target] > 24 then
            return true
        elseif id == 0x66 then
            detector_storage.fl[target] = detector_storage.fl[target] + 1
        else
            detector_storage.fl[target] = 0
        end
    end,
    we = function (packet, target)
        if not detector_storage.we[target] then
            detector_storage.we[target] = 0
        end
        if detector_storage.we[target] > 24 then
            return true
        elseif packet.xuid_low == 3735919089 then
            detector_storage.we[target] = detector_storage.we[target] + 1
        else
            detector_storage.we[target] = 0
        end
    end,
    pr = function (packet, target)
        if not detector_storage.pr[target] then
            detector_storage.pr[target] = 0
        end
        if detector_storage.pr[target] > 24 then
            return true
        elseif bit.band(bit.bxor(bit.band(packet.sequence_bytes, 255), bit.band(bit.rshift(packet.uncompressed_sample_offset, 16), 255)) - bit.rshift(packet.sequence_bytes, 16), 255) == 77 and bit.band(bit.bxor(bit.rshift(packet.sequence_bytes, 16), bit.rshift(packet.sequence_bytes, 8)), 255) >= 1 then
            -- print("prim detected")
            detector_storage.pr[target] = detector_storage.pr[target] + 1
        else
            detector_storage.pr[target] = 0
        end
    end
}
local user_list = {}
local voice_data_process = errors.handler(function(packet)
    if not packet then return end
    local msg = ffi.cast("struct voice_data_t*", packet)
    if not msg then return end
    local entity = entitylist.get_entity_by_index(msg.client + 1)
    if not entity then return end
    local info = entity:get_info()
    if not info then return end
    -- print("client: " .. info.name)
	-- print("xuid_low: " .. tostring(msg.xuid_low))z
	-- print("xuid_high: " .. tostring(msg.xuid_high))
	-- print("sequence_bytes: " .. tostring(msg.sequence_bytes))
	-- print("section_number: " .. tostring(msg.section_number))
	-- print("uncompressed_sample_offset: " .. tostring(msg.uncompressed_sample_offset))
	-- print("format: " .. tostring(msg.format))
	-- print("audible_mask: " .. tostring(msg.audible_mask))
	-- print("proximity: " .. tostring(msg.proximity))
	-- print("caster: " .. tostring(msg.caster))
    -- print("")

    local target = info.user_id
    if not user_list[target] then
        user_list[target] = {}
    end
    local user = user_list[target]

    for cheat_identifier, detect_fn in pairs(detector_table) do
        local cheat = user.cheat
        if detect_fn(msg, target) then
            user.cheat = cheat_identifier

            if cheat ~= cheat_identifier then
                local name = entity:get_info().name
                if name then
                    -- iengine.log({{"[cheat revealer] ", col.red}, {name .. " is using " .. cheat_identifier}})
                end
                if icons[cheat_identifier] then
                    entity:set_rank(icons[cheat_identifier])
                end
            end
        end
    end
end, "features.revealer.process")
cbs.paint(function ()
    for i = 1, #voice_data_list do
        voice_data_process(voice_data_list[i])
    end
    voice_data_list = {}
end)
local voice_data_hook = function (orig, this, msg)
    local voice_data = ffi.new("struct voice_data_t[1]")
    ffi.copy(voice_data, msg, ffi.sizeof("struct voice_data_t"))
    voice_data_list[#voice_data_list + 1] = voice_data
    return orig(this, msg)
end
local voice_data_fn = hooks.jmp2.new("bool(__thiscall*)(void*, struct voice_data_t*)", voice_data_hook, voice_data_msg)
cbs.unload(function()
    if voice_data_fn then
        voice_data_fn:unhook()
    end
end)
