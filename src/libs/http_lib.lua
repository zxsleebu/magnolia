local a = require("libs.protected_ffi")
local b = json
local function c(...)
    print(tostring(...))
end
local d, e, f
if not pcall(a.sizeof, "SteamAPICall_t") then
    a.cdef(
        [[
        typedef uint64_t SteamAPICall_t;
        struct SteamAPI_callback_base_vtbl {
            void(__thiscall *run1)(struct SteamAPI_callback_base *, void *, bool, uint64_t);
            void(__thiscall *run2)(struct SteamAPI_callback_base *, void *);
            int(__thiscall *get_size)(struct SteamAPI_callback_base *);
        };

        struct SteamAPI_callback_base {
            struct SteamAPI_callback_base_vtbl *vtbl;
            uint8_t flags;
            int id;
            uint64_t api_call_handle;
            struct SteamAPI_callback_base_vtbl vtbl_storage[1];
        };
    ]]
    )
end
local g = {
    [-1] = "No failure",
    [0] = "Steam gone",
    [1] = "Network failure",
    [2] = "Invalid handle",
    [3] = "Mismatched callback"
}
local h = a.typeof("struct SteamAPI_callback_base")
local i = a.sizeof(h)
local j = a.typeof("struct SteamAPI_callback_base[1]")
local k = a.typeof("struct SteamAPI_callback_base*")
local l = a.typeof("uintptr_t")
local m = {}
local n = {}
local o = {}
local function p(q)
    return tostring(tonumber(a.cast(l, q)))
end
local function r(self, s, t)
    if t then
        t = g[GetAPICallFailureReason(self.api_call_handle)] or "Unknown error"
    end
    self.api_call_handle = 0
    xpcall(
        function()
            local u = p(self)
            local v = m[u]
            if v ~= nil then
                xpcall(v, c, s, t)
            end
            if n[u] ~= nil then
                m[u] = nil
                n[u] = nil
            end
        end,
        c
    )
end
local function w(self, s, t, x)
    if x == self.api_call_handle then
        r(self, s, t)
    end
end
local function y(self, s)
    r(self, s, false)
end
local function z(self)
    return i
end
local function A(self)
    if self.api_call_handle ~= 0 then
        SteamAPI_UnregisterCallResult(self, self.api_call_handle)
        self.api_call_handle = 0
        local u = p(self)
        m[u] = nil
        n[u] = nil
    end
end
pcall(a.metatype, h, {__gc = A, __index = {cancel = A}})
local B = a.cast("void(__thiscall *)(struct SteamAPI_callback_base *, void *, bool, uint64_t)", w)
local C = a.cast("void(__thiscall *)(struct SteamAPI_callback_base *, void *)", y)
local D = a.cast("int(__thiscall *)(struct SteamAPI_callback_base *)", z)
function d(x, v, E)
    assert(x ~= 0)
    local F = j()
    local G = a.cast(k, F)
    G.vtbl_storage[0].run1 = B
    G.vtbl_storage[0].run2 = C
    G.vtbl_storage[0].get_size = D
    G.vtbl = G.vtbl_storage
    G.api_call_handle = x
    G.id = E
    local u = p(G)
    m[u] = v
    n[u] = F
    SteamAPI_RegisterCallResult(G, x)
    return G
end
function e(E, v)
    assert(o[E] == nil)
    local F = j()
    local G = a.cast(k, F)
    G.vtbl_storage[0].run1 = B
    G.vtbl_storage[0].run2 = C
    G.vtbl_storage[0].get_size = D
    G.vtbl = G.vtbl_storage
    G.api_call_handle = 0
    G.id = E
    local u = p(G)
    m[u] = v
    o[E] = F
    SteamAPI_RegisterCallback(G, E)
end
local function H(I, J, K, L, M)
    local N = client.find_pattern(I, J) or error("signature not found", 2)
    local O = a.cast("uintptr_t", N)
    if L ~= nil and L ~= 0 then
        O = O + L
    end
    if M ~= nil then
        for P = 1, M do
            O = a.cast("uintptr_t*", O)[0]
            if O == nil then
                return error("signature not found")
            end
        end
    end
    return a.cast(K, O)
end
local function Q(G, R, type)
    return a.cast(type, a.cast("void***", G)[0][R])
end
SteamAPI_RegisterCallResult =
    H(
    "steam_api.dll",
    "55 8B EC 83 3D ? ? ? ? ? 7E 0D 68 ? ? ? ? FF 15 ? ? ? ? 5D C3 FF 75 10",
    "void(__cdecl*)(struct SteamAPI_callback_base *, uint64_t)"
)
SteamAPI_UnregisterCallResult =
    H("steam_api.dll", " 55 8B EC FF 75 10 FF 75 0C", "void(__cdecl*)(struct SteamAPI_callback_base *, uint64_t)")
SteamAPI_RegisterCallback =
    H(
    "steam_api.dll",
    " 55 8B EC 83 3D ? ? ? ? ? 7E 0D 68 ? ? ? ? FF 15 ? ? ? ? 5D C3 C7 05",
    "void(__cdecl*)(struct SteamAPI_callback_base *, int)"
)
SteamAPI_UnregisterCallback =
    H("steam_api.dll", " 55 8B EC 83 EC 08 80 3D", "void(__cdecl*)(struct SteamAPI_callback_base *)")
f = H("client.dll", " B9 ? ? ? ? E8 ? ? ? ? 83 3D ? ? ? ? ? 0F 84", "uintptr_t", 1, 1)
local S = a.cast("uintptr_t*", f)[3]
local T = Q(S, 12, "int(__thiscall*)(void*, SteamAPICall_t)")
function GetAPICallFailureReason(U)
    return T(S, U)
end
client.register_callback(
    "unload",
    function()
        for u, V in pairs(n) do
            local G = a.cast(k, V)
            A(G)
        end
        for u, V in pairs(o) do
            local G = a.cast(k, V)
            SteamAPI_UnregisterCallback(G)
        end
    end
)
if not pcall(a.sizeof, "http_HTTPRequestHandle") then
    a.cdef(
        [[
        typedef uint32_t http_HTTPRequestHandle;
        typedef uint32_t http_HTTPCookieContainerHandle;

        enum http_EHTTPMethod {
            k_EHTTPMethodInvalid,
            k_EHTTPMethodGET,
            k_EHTTPMethodHEAD,
            k_EHTTPMethodPOST,
            k_EHTTPMethodPUT,
            k_EHTTPMethodDELETE,
            k_EHTTPMethodOPTIONS,
            k_EHTTPMethodPATCH,
        };

        struct http_ISteamHTTPVtbl {
            http_HTTPRequestHandle(__thiscall *CreateHTTPRequest)(uintptr_t, enum http_EHTTPMethod, const char *);
            bool(__thiscall *SetHTTPRequestContextValue)(uintptr_t, http_HTTPRequestHandle, uint64_t);
            bool(__thiscall *SetHTTPRequestNetworkActivityTimeout)(uintptr_t, http_HTTPRequestHandle, uint32_t);
            bool(__thiscall *SetHTTPRequestHeaderValue)(uintptr_t, http_HTTPRequestHandle, const char *, const char *);
            bool(__thiscall *SetHTTPRequestGetOrPostParameter)(uintptr_t, http_HTTPRequestHandle, const char *, const char *);
            bool(__thiscall *SendHTTPRequest)(uintptr_t, http_HTTPRequestHandle, SteamAPICall_t *);
            bool(__thiscall *SendHTTPRequestAndStreamResponse)(uintptr_t, http_HTTPRequestHandle, SteamAPICall_t *);
            bool(__thiscall *DeferHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
            bool(__thiscall *PrioritizeHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
            bool(__thiscall *GetHTTPResponseHeaderSize)(uintptr_t, http_HTTPRequestHandle, const char *, uint32_t *);
            bool(__thiscall *GetHTTPResponseHeaderValue)(uintptr_t, http_HTTPRequestHandle, const char *, uint8_t *, uint32_t);
            bool(__thiscall *GetHTTPResponseBodySize)(uintptr_t, http_HTTPRequestHandle, uint32_t *);
            bool(__thiscall *GetHTTPResponseBodyData)(uintptr_t, http_HTTPRequestHandle, uint8_t *, uint32_t);
            bool(__thiscall *GetHTTPStreamingResponseBodyData)(uintptr_t, http_HTTPRequestHandle, uint32_t, uint8_t *, uint32_t);
            bool(__thiscall *ReleaseHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
            bool(__thiscall *GetHTTPDownloadProgressPct)(uintptr_t, http_HTTPRequestHandle, float *);
            bool(__thiscall *SetHTTPRequestRawPostBody)(uintptr_t, http_HTTPRequestHandle, const char *, uint8_t *, uint32_t);
            http_HTTPCookieContainerHandle(__thiscall *CreateCookieContainer)(uintptr_t, bool);
            bool(__thiscall *ReleaseCookieContainer)(uintptr_t, http_HTTPCookieContainerHandle);
            bool(__thiscall *SetCookie)(uintptr_t, http_HTTPCookieContainerHandle, const char *, const char *, const char *);
            bool(__thiscall *SetHTTPRequestCookieContainer)(uintptr_t, http_HTTPRequestHandle, http_HTTPCookieContainerHandle);
            bool(__thiscall *SetHTTPRequestUserAgentInfo)(uintptr_t, http_HTTPRequestHandle, const char *);
            bool(__thiscall *SetHTTPRequestRequiresVerifiedCertificate)(uintptr_t, http_HTTPRequestHandle, bool);
            bool(__thiscall *SetHTTPRequestAbsoluteTimeoutMS)(uintptr_t, http_HTTPRequestHandle, uint32_t);
            bool(__thiscall *GetHTTPRequestWasTimedOut)(uintptr_t, http_HTTPRequestHandle, bool *pbWasTimedOut);
        };
    ]]
    )
end
local W = {
    get = a.C.k_EHTTPMethodGET,
    head = a.C.k_EHTTPMethodHEAD,
    post = a.C.k_EHTTPMethodPOST,
    put = a.C.k_EHTTPMethodPUT,
    delete = a.C.k_EHTTPMethodDELETE,
    options = a.C.k_EHTTPMethodOPTIONS,
    patch = a.C.k_EHTTPMethodPATCH
}
local X = {
    [100] = "Continue",
    [101] = "Switching Protocols",
    [102] = "Processing",
    [200] = "OK",
    [201] = "Created",
    [202] = "Accepted",
    [203] = "Non-Authoritative Information",
    [204] = "No Content",
    [205] = "Reset Content",
    [206] = "Partial Content",
    [207] = "Multi-Status",
    [208] = "Already Reported",
    [250] = "Low on Storage Space",
    [226] = "IM Used",
    [300] = "Multiple Choices",
    [301] = "Moved Permanently",
    [302] = "Found",
    [303] = "See Other",
    [304] = "Not Modified",
    [305] = "Use Proxy",
    [306] = "Switch Proxy",
    [307] = "Temporary Redirect",
    [308] = "Permanent Redirect",
    [400] = "Bad Request",
    [401] = "Unauthorized",
    [402] = "Payment Required",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [406] = "Not Acceptable",
    [407] = "Proxy Authentication Required",
    [408] = "Request Timeout",
    [409] = "Conflict",
    [410] = "Gone",
    [411] = "Length Required",
    [412] = "Precondition Failed",
    [413] = "Request Entity Too Large",
    [414] = "Request-URI Too Long",
    [415] = "Unsupported Media Type",
    [416] = "Requested Range Not Satisfiable",
    [417] = "Expectation Failed",
    [418] = "I'm a teapot",
    [420] = "Enhance Your Calm",
    [422] = "Unprocessable Entity",
    [423] = "Locked",
    [424] = "Failed Dependency",
    [424] = "Method Failure",
    [425] = "Unordered Collection",
    [426] = "Upgrade Required",
    [428] = "Precondition Required",
    [429] = "Too Many Requests",
    [431] = "Request Header Fields Too Large",
    [444] = "No Response",
    [449] = "Retry With",
    [450] = "Blocked by Windows Parental Controls",
    [451] = "Parameter Not Understood",
    [451] = "Unavailable For Legal Reasons",
    [451] = "Redirect",
    [452] = "Conference Not Found",
    [453] = "Not Enough Bandwidth",
    [454] = "Session Not Found",
    [455] = "Method Not Valid in This State",
    [456] = "Header Field Not Valid for Resource",
    [457] = "Invalid Range",
    [458] = "Parameter Is Read-Only",
    [459] = "Aggregate Operation Not Allowed",
    [460] = "Only Aggregate Operation Allowed",
    [461] = "Unsupported Transport",
    [462] = "Destination Unreachable",
    [494] = "Request Header Too Large",
    [495] = "Cert Error",
    [496] = "No Cert",
    [497] = "HTTP to HTTPS",
    [499] = "Client Closed Request",
    [500] = "Internal Server Error",
    [501] = "Not Implemented",
    [502] = "Bad Gateway",
    [503] = "Service Unavailable",
    [504] = "Gateway Timeout",
    [505] = "HTTP Version Not Supported",
    [506] = "Variant Also Negotiates",
    [507] = "Insufficient Storage",
    [508] = "Loop Detected",
    [509] = "Bandwidth Limit Exceeded",
    [510] = "Not Extended",
    [511] = "Network Authentication Required",
    [551] = "Option not supported",
    [598] = "Network read timeout error",
    [599] = "Network connect timeout error"
}
local Y = {"params", "body", "json"}
local Z = 2101
local _ = 2102
local a0 = 2103
local function a1()
    local a2 = a.cast("uintptr_t*", f)[12]
    if a2 == 0 or a2 == nil then
        return error("find_isteamhttp failed")
    end
    local a3 = a.cast("struct http_ISteamHTTPVtbl**", a2)[0]
    if a3 == 0 or a3 == nil then
        return error("find_isteamhttp failed")
    end
    return a2, a3
end
local function a4(a5, a6)
    return function(...)
        return a5(a6, ...)
    end
end
local a7 =
    a.typeof(
    [[
    struct {
        http_HTTPRequestHandle m_hRequest;
        uint64_t m_ulContextValue;
        bool m_bRequestSuccessful;
        int m_eStatusCode;
        uint32_t m_unBodySize;
    } *
    ]]
)
local a8 =
    a.typeof(
    [[
    struct {
        http_HTTPRequestHandle m_hRequest;
        uint64_t m_ulContextValue;
    } *
    ]]
)
local a9 =
    a.typeof(
    [[
    struct {
        http_HTTPRequestHandle m_hRequest;
        uint64_t m_ulContextValue;
        uint32_t m_cOffset;
        uint32_t m_cBytesReceived;
    } *
    ]]
)
local aa = a.typeof([[
    struct {
        http_HTTPCookieContainerHandle m_hCookieContainer;
    }
    ]])
local ab = a.typeof("SteamAPICall_t[1]")
local ac = a.typeof("const char[?]")
local ad = a.typeof("uint8_t[?]")
local ae = a.typeof("unsigned int[?]")
local af = a.typeof("bool[1]")
local ag = a.typeof("float[1]")
local ah, ai = a1()
local aj = a4(ai.CreateHTTPRequest, ah)
local ak = a4(ai.SetHTTPRequestContextValue, ah)
local al = a4(ai.SetHTTPRequestNetworkActivityTimeout, ah)
local am = a4(ai.SetHTTPRequestHeaderValue, ah)
local an = a4(ai.SetHTTPRequestGetOrPostParameter, ah)
local ao = a4(ai.SendHTTPRequest, ah)
local ap = a4(ai.SendHTTPRequestAndStreamResponse, ah)
local aq = a4(ai.DeferHTTPRequest, ah)
local ar = a4(ai.PrioritizeHTTPRequest, ah)
local as = a4(ai.GetHTTPResponseHeaderSize, ah)
local at = a4(ai.GetHTTPResponseHeaderValue, ah)
local au = a4(ai.GetHTTPResponseBodySize, ah)
local av = a4(ai.GetHTTPResponseBodyData, ah)
local aw = a4(ai.GetHTTPStreamingResponseBodyData, ah)
local ax = a4(ai.ReleaseHTTPRequest, ah)
local ay = a4(ai.GetHTTPDownloadProgressPct, ah)
local az = a4(ai.SetHTTPRequestRawPostBody, ah)
local aA = a4(ai.CreateCookieContainer, ah)
local aB = a4(ai.ReleaseCookieContainer, ah)
local aC = a4(ai.SetCookie, ah)
local aD = a4(ai.SetHTTPRequestCookieContainer, ah)
local aE = a4(ai.SetHTTPRequestUserAgentInfo, ah)
local aF = a4(ai.SetHTTPRequestRequiresVerifiedCertificate, ah)
local aG = a4(ai.SetHTTPRequestAbsoluteTimeoutMS, ah)
local aH = a4(ai.GetHTTPRequestWasTimedOut, ah)
local aI, aJ = {}, false
local aK, aL = false, {}
local aM, aN = false, {}
local aI, aJ = {}, false
local aK, aL = false, {}
local aM, aN = false, {}
local aO = setmetatable({}, {__mode = "k"})
local aP, aQ = setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "v"})
local aR = {}
local aS = {__index = function(aT, aU)
        local aV = aP[aT]
        if aV == nil then
            return
        end
        aU = tostring(aU)
        if aV.m_hRequest ~= 0 then
            local aW = ae(1)
            if as(aV.m_hRequest, aU, aW) then
                if aW ~= nil then
                    aW = aW[0]
                    if aW < 0 then
                        return
                    end
                    local aX = ad(aW)
                    if at(aV.m_hRequest, aU, aX, aW) then
                        aT[aU] = a.string(aX, aW - 1)
                        return aT[aU]
                    end
                end
            end
        end
    end, __metatable = false}
local aY = {__index = {set_cookie = function(aZ, a_, b0, aU, V)
            local U = aO[aZ]
            if U == nil or U.m_hCookieContainer == 0 then
                return
            end
            aC(U.m_hCookieContainer, a_, b0, tostring(aU) .. "=" .. tostring(V))
        end}, __metatable = false}
local function b1(U)
    if U.m_hCookieContainer ~= 0 then
        aB(U.m_hCookieContainer)
        U.m_hCookieContainer = 0
    end
end
local function b2(aV)
    if aV.m_hRequest ~= 0 then
        ax(aV.m_hRequest)
        aV.m_hRequest = 0
    end
end
local function b3(b4, ...)
    ax(b4)
    return error(...)
end
local function b5(aV, b6, b7, b8, ...)
    local b9 = aQ[aV.m_hRequest]
    if b9 == nil then
        b9 = setmetatable({}, aS)
        aQ[aV.m_hRequest] = b9
    end
    aP[b9] = aV
    b8.headers = b9
    aJ = true
    xpcall(b6, c, b7, b8, ...)
    aJ = false
end
local function ba(s, t)
    if s == nil then
        return
    end
    local aV = a.cast(a7, s)
    if aV.m_hRequest ~= 0 then
        local b6 = aI[aV.m_hRequest]
        if b6 ~= nil then
            aI[aV.m_hRequest] = nil
            aN[aV.m_hRequest] = nil
            aL[aV.m_hRequest] = nil
            if b6 then
                local b7 = t == false and aV.m_bRequestSuccessful
                local bb = aV.m_eStatusCode
                local bc = {status = bb}
                local bd = aV.m_unBodySize
                if b7 and bd > 0 then
                    local aX = ad(bd)
                    if av(aV.m_hRequest, aX, bd) then
                        bc.body = a.string(aX, bd)
                    end
                elseif not aV.m_bRequestSuccessful then
                    local be = af()
                    aH(aV.m_hRequest, be)
                    bc.timed_out = be ~= nil and be[0] == true
                end
                if bb > 0 then
                    bc.status_message = X[bb] or "Unknown status"
                elseif t then
                    bc.status_message = string.format("IO Failure: %s", t)
                else
                    bc.status_message = bc.timed_out and "Timed out" or "Unknown error"
                end
                b5(aV, b6, b7, bc)
            end
            b2(aV)
        end
    end
end
local function bf(s, t)
    if s == nil then
        return
    end
    local aV = a.cast(a8, s)
    if aV.m_hRequest ~= 0 then
        local b6 = aL[aV.m_hRequest]
        if b6 then
            b5(aV, b6, t == false, {})
        end
    end
end
local function bg(s, t)
    if s == nil then
        return
    end
    local aV = a.cast(a9, s)
    if aV.m_hRequest ~= 0 then
        local b6 = aN[aV.m_hRequest]
        if aN[aV.m_hRequest] then
            local b8 = {}
            local bh = ag()
            if ay(aV.m_hRequest, bh) then
                b8.download_progress = tonumber(bh[0])
            end
            local aX = ad(aV.m_cBytesReceived)
            if aw(aV.m_hRequest, aV.m_cOffset, aX, aV.m_cBytesReceived) then
                b8.body = a.string(aX, aV.m_cBytesReceived)
            end
            b5(aV, b6, t == false, b8)
        end
    end
end
---@alias callback_function fun(success: boolean, result: { status?: number, body?: string, timed_out?: boolean })
---@param method "get"|"head"|"post"|"put"|"delete"|"options"|"patch"
---@param url string
---@param options? { absolute_timeout?: number, body?: string, cookie_container?: table, headers?: table<string, string>, json?: table, network_timeout?: number, params?: table, priority?: "defer"|"prioritize", require_ssl?: boolean, stream_response?: boolean, user_agent_info?: string }
---@param callbacks { completed?: callback_function, headers_received?: callback_function, data_received?: callback_function }|callback_function
local function bi(method, url, options, callbacks)
    if type(options) == "function" and callbacks == nil then
        callbacks = options
        options = {}
    end
    options = options or {}
    local bj = W[string.lower(tostring(method))]
    if bj == nil then
        return error("invalid HTTP method")
    end
    if type(url) ~= "string" then
        return error("URL has to be a string")
    end
    local bm, bn, bo
    if type(callbacks) == "function" then
        bm = callbacks
    elseif type(callbacks) == "table" then
        bm = callbacks.completed or callbacks.complete
        bn = callbacks.headers_received or callbacks.headers
        bo = callbacks.data_received or callbacks.data
        if bm ~= nil and type(bm) ~= "function" then
            return error("callbacks.completed callback has to be a function")
        elseif bn ~= nil and type(bn) ~= "function" then
            return error("callbacks.headers_received callback has to be a function")
        elseif bo ~= nil and type(bo) ~= "function" then
            return error("callbacks.data_received callback has to be a function")
        end
    else
        return error("callbacks has to be a function or table")
    end
    local b4 = aj(bj, url)
    if b4 == 0 then
        return error("Failed to create HTTP request")
    end
    local bp = false
    for P, u in ipairs(Y) do
        if options[u] ~= nil then
            if bp then
                return error("can only set options.params, options.body or options.json")
            else
                bp = true
            end
        end
    end
    local bq
    if options.json ~= nil then
        local br
        br, bq = pcall(b.encode, options.json)
        if not br then
            return error("options.json is invalid: " .. bq)
        end
    end
    local bs = options.network_timeout
    if bs == nil then
        bs = 10
    end
    if type(bs) == "number" and bs > 0 then
        if not al(b4, bs) then
            return b3(b4, "failed to set network_timeout")
        end
    elseif bs ~= nil then
        return b3(b4, "options.network_timeout has to be of type number and greater than 0")
    end
    local bt = options.absolute_timeout
    if bt == nil then
        bt = 30
    end
    if type(bt) == "number" and bt > 0 then
        if not aG(b4, bt * 1000) then
            return b3(b4, "failed to set absolute_timeout")
        end
    elseif bt ~= nil then
        return b3(b4, "options.absolute_timeout has to be of type number and greater than 0")
    end
    local bu = bq ~= nil and "application/json" or "text/plain"
    local bv
    local b9 = options.headers
    if type(b9) == "table" then
        for aU, V in pairs(b9) do
            aU = tostring(aU)
            V = tostring(V)
            local bw = string.lower(aU)
            if bw == "content-type" then
                bu = V
            elseif bw == "authorization" then
                bv = true
            end
            if not am(b4, aU, V) then
                return b3(b4, "failed to set header " .. aU)
            end
        end
    elseif b9 ~= nil then
        return b3(b4, "options.headers has to be of type table")
    end
    local bx = options.authorization
    if type(bx) == "table" then
    elseif bx ~= nil then
        return b3(b4, "options.authorization has to be of type table")
    end
    local by = bq or options.body
    if type(by) == "string" then
        local bz = string.len(by)
        if not az(b4, bu, a.cast("unsigned char*", by), bz) then
            return b3(b4, "failed to set post body")
        end
    elseif by ~= nil then
        return b3(b4, "options.body has to be of type string")
    end
    local bA = options.params
    if type(bA) == "table" then
        for aU, V in pairs(bA) do
            aU = tostring(aU)
            if not an(b4, aU, tostring(V)) then
                return b3(b4, "failed to set parameter " .. aU)
            end
        end
    elseif bA ~= nil then
        return b3(b4, "options.params has to be of type table")
    end
    local bB = options.require_ssl
    if type(bB) == "boolean" then
        if not aF(b4, bB == true) then
            return b3(b4, "failed to set require_ssl")
        end
    elseif bB ~= nil then
        return b3(b4, "options.require_ssl has to be of type boolean")
    end
    local bC = options.user_agent_info
    if type(bC) == "string" then
        if not aE(b4, tostring(bC)) then
            return b3(b4, "failed to set user_agent_info")
        end
    elseif bC ~= nil then
        return b3(b4, "options.user_agent_info has to be of type string")
    end
    local bD = options.cookie_container
    if type(bD) == "table" then
        local U = aO[bD]
        if U ~= nil and U.m_hCookieContainer ~= 0 then
            if not aD(b4, U.m_hCookieContainer) then
                return b3(b4, "failed to set user_agent_info")
            end
        else
            return b3(b4, "options.cookie_container has to a valid cookie container")
        end
    elseif bD ~= nil then
        return b3(b4, "options.cookie_container has to a valid cookie container")
    end
    local bE = ao
    local bF = options.stream_response
    if type(bF) == "boolean" then
        if bF then
            bE = ap
            if bm == nil and bn == nil and bo == nil then
                return b3(b4, "a 'completed', 'headers_received' or 'data_received' callback is required")
            end
        else
            if bm == nil then
                return b3(b4, "'completed' callback has to be set for non-streamed requests")
            elseif bn ~= nil or bo ~= nil then
                return b3(b4, "non-streamed requests only support 'completed' callbacks")
            end
        end
    elseif bF ~= nil then
        return b3(b4, "options.stream_response has to be of type boolean")
    end
    if bn ~= nil or bo ~= nil then
        aL[b4] = bn or false
        if bn ~= nil then
            if not aK then
                e(_, bf)
                aK = true
            end
        end
        aN[b4] = bo or false
        if bo ~= nil then
            if not aM then
                e(a0, bg)
                aM = true
            end
        end
    end
    local bG = ab()
    if not bE(b4, bG) then
        ax(b4)
        if bm ~= nil then
            bm(false, {status = 0, status_message = "Failed to send request"})
        end
        return
    end
    if options.priority == "defer" or options.priority == "prioritize" then
        local a5 = options.priority == "prioritize" and ar or aq
        if not a5(b4) then
            return b3(b4, "failed to set priority")
        end
    elseif options.priority ~= nil then
        return b3(b4, "options.priority has to be 'defer' of 'prioritize'")
    end
    aI[b4] = bm or false
    if bm ~= nil then
        d(bG[0], ba, Z)
    end
end
local function bH(bI)
    if bI ~= nil and type(bI) ~= "boolean" then
        return error("allow_modification has to be of type boolean")
    end
    local bJ = aA(bI == true)
    if bJ ~= nil then
        local U = aa(bJ)
        a.gc(U, b1)
        local u = setmetatable({}, aY)
        aO[u] = U
        return u
    end
end
local bK = {request = bi, create_cookie_container = bH}
for bj in pairs(W) do
    bK[bj] = function(...)
        return bi(bj, ...)
    end
end
return bK