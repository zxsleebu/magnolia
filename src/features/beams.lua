require("libs.types")
local ffi = require("libs.protected_ffi")
local interface, class = require("libs.interfaces")()
ffi.cdef[[
    typedef struct {
        int         type;
        void*       start_ent;
        int         start_attachment;
        void*       end_ent;
        int         end_attachment;
        vector_t    start_pos;
        vector_t    end_pos;
        int         model_index;
        PCSTR       model_name;
        int         halo_index;
        PCSTR       halo_name;
        float       halo_scale;
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
    } beam_info_t;
]]
---@alias beam_info_t { type: number, start_ent: any, start_attachment: number, end_ent: any, end_attachment: number, start_pos: ffi.cdata*, end_pos: ffi.cdata*, model_index: number, model_name: any, halo_index: number, halo_name: any, halo_scale: number, life: number, width: number, end_width: number, fade_length: number, amplitude: number, brightness: number, speed: number, start_frame: number, frame_rate: number, red: number, green: number, blue: number, renderable: boolean, num_segments: number, flags: number, center: vec3_t, start_radius: number, end_radius: number }
local beams = {
    __callbacks = {}
}
---@param cb fun(beam_info: beam_info_t)
beams.add_callback = function(cb)
    table.insert(beams.__callbacks, cb)
end
local hooks = require("libs.hooks")
local utils  = require("libs.utils")
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
local v2, v3 = require("libs.vectors")()
local beams_ptr = ffi.cast("void****", utils.find_pattern("client", "B9 ? ? ? ? A1 ? ? ? ? FF 10 A1 ? ? ? ? B9", 1))[0]
local IViewRenderBeams = class.new({
    DrawBeam = {4, "void(__thiscall*)(void*, void*)"},
    UpdateBeamInfo = {22, "void(__thiscall*)(void*, void*, beam_info_t&)"}
})(beams_ptr)
local beams_vmt_hk = hooks.vmt.new(IViewRenderBeams.ptr)
local create_beam_orig
---@param beam_info beam_info_t
create_beam_orig = beams_vmt_hk:hookMethod("void*(__thiscall*)(void*, beam_info_t&)", function (this, beam_info)
    errors.handler(function()
        for _, cb in pairs(beams.__callbacks) do
            cb(beam_info)
        end
    end)()
    return create_beam_orig(this, beam_info)
end, 12)
cbs.unload(function ()
    beams_vmt_hk:unHookAll()
end)

local beams_t = {}

function beams_t:draw()
    IViewRenderBeams:DrawBeam(self.beam)
end

function beams_t:kill()
    self.info.life = 0.001
    self.info.renderable = false
    IViewRenderBeams:UpdateBeamInfo(self.beam, self.info)
end

---@param info { life: number, width: number, end_width: number, model_name: string, amplitude: number, speed: number, color: color_t, segments: number, start_pos: vec3_t, end_pos: vec3_t, halo_name: string, halo_scale: number, fade_length: number }
beams.new = function(info)
    local beam_info = ffi.new("beam_info_t") ---@type beam_info_t
    beam_info.type = 0x00
    beam_info.model_index = -1

    beam_info.life = info.life
    beam_info.fade_length = info.fade_length or 0

    beam_info.width = info.width * 0.1

    local end_width = info.end_width
    if end_width == nil then
        end_width = info.width
    end

    beam_info.end_width = end_width * 0.1

    beam_info.model_name = info.model_name

    beam_info.amplitude = info.amplitude
    beam_info.speed = info.speed * 0.1

    beam_info.start_frame = 0
    beam_info.frame_rate = 0

    beam_info.red = info.color.r
    beam_info.green = info.color.g
    beam_info.blue = info.color.b
    beam_info.brightness = info.color.a

    beam_info.num_segments = info.segments
    beam_info.renderable = true

    beam_info.flags = 0--0x00004000 + 0x00000100 + 0x00000200 + 0x00008000

    beam_info.start_pos = info.start_pos:C()
    beam_info.end_pos = info.end_pos:C()

    beam_info.halo_name = info.halo_name
    beam_info.halo_scale = info.halo_scale or 0


    local beam = create_beam_orig(IViewRenderBeams.this, beam_info)

    if not beam then return error("couldn't create beam") end

    return setmetatable({
        beam = beam,
        info = beam_info,
    }, {__index = beams_t})
end

return beams