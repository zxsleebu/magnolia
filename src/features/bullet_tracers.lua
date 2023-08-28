local v2, v3 = require("libs.vectors")()
local hooks = require("libs.hooks")
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local beams = {
    ---@type fun(from: vec3_t, to: vec3_t): boolean
    callback = nil,
}
require("libs.types")
ffi.cdef[[
    struct beam_info_t {
        int         type;
        void*       start_ent;
        int         start_attachment;
        void*       end_ent;
        int         end_attachment;
        vector_t    start;
        vector_t    to;
        int         model_index;
        PCSTR       model_name;
        int         halo_index;
        PCSTR       halo_name;
        float       haldo_scale;
        float       life;
        float       width;
        float       end_width;
        float       fade_length;
        float       amplitude;
        float       brightness;
        float       speed;
        int         start_frame;
        float       frame_rate;
        float       red;
        float       green;
        float       blue;
        bool        renderable;
        int         num_segments;
        int         flags;
        vector_t    center;
        float       start_radius;
        float       end_radius;
    };
]]
local beams_vmt = hooks.vmt.new(ffi.cast("void****", ffi.cast("char*", find_pattern("client.dll", "B9 ? ? ? ? A1 ? ? ? ? FF 10 A1 ? ? ? ? B9")) + 1)[0])
local create_beam_orig
---@param beam_info { type: number, start_ent: any, start_attachment: number, end_ent: any, end_attachment: number, start: vec3_t, to: vec3_t, model_index: number, model_name: any, halo_index: number, halo_name: any, haldo_scale: number, life: number, width: number, end_width: number, fade_length: number, amplitude: number, brightness: number, speed: number, start_frame: number, frame_rate: number, red: number, green: number, blue: number, renderable: boolean, num_segments: number, flags: number, center: vec3_t, start_radius: number, end_radius: number }
create_beam_orig = beams_vmt:hookMethod("void*(__thiscall*)(void*, struct beam_info_t&)", function (this, beam_info)
    errors.handler(function()
        if beam_info.life == 2.5 then
            local from = v3(beam_info.start.x, beam_info.start.y, beam_info.start.z + 3)
            local to = v3(beam_info.to.x, beam_info.to.y, beam_info.to.z)
            if beams.callback(from, to) then
                beam_info.renderable = false
            end
        end
    end)()
    return create_beam_orig(this, beam_info)
end, 12)
cbs.unload(function ()
    beams_vmt:unHookAll()
end)
return beams