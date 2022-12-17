local ffi = require("ffi")
local ws = ffi.load("websocket")
local once = require("libs.once").new()
ffi.cdef[[
    typedef void* PVOID;
    typedef void* LPVOID;
    typedef long LONG;
    typedef char* PCHAR;
    typedef unsigned char BYTE;
    typedef BYTE* PBYTE;
    typedef unsigned short USHORT;
    typedef unsigned long ULONG;
    typedef unsigned long ULONG_PTR;
    typedef unsigned short WORD;
    typedef unsigned long DWORD;
    typedef ULONG_PTR DWORD_PTR;
    typedef int BOOL;
    typedef wchar_t WCHAR;
    typedef const WCHAR* LPCWSTR;
    typedef LPCWSTR PCWSTR;
    typedef const char* LPCSTR;
    typedef LPCSTR PCSTR;
    typedef void VOID;

    typedef LONG HRESULT;
    typedef PVOID WEB_SOCKET_HANDLE;

    typedef struct {
        int Type;
        void* pvValue;
        ULONG ulValueSize;
    } WEB_SOCKET_PROPERTY;
    typedef struct {
        PCHAR pcName;
        ULONG ulNameLength;
        PCHAR pcValue;
        ULONG ulValueLength;
    } WEB_SOCKET_HTTP_HEADER;
    typedef union {
        struct {
          PBYTE pbBuffer;
          ULONG ulBufferLength;
        } Data;
        struct {
          PBYTE  pbReason;
          ULONG  ulReasonLength;
          USHORT usStatus;
        } CloseStatus;
    } WEB_SOCKET_BUFFER;

    HRESULT __stdcall WebSocketCreateClientHandle(
        const WEB_SOCKET_PROPERTY* pProperties,
        ULONG ulPropertyCount,
        WEB_SOCKET_HANDLE* phWebSocket
    );

    HRESULT __stdcall WebSocketBeginClientHandshake(
        WEB_SOCKET_HANDLE hWebSocket,
        PCSTR* pszSubprotocols,
        ULONG ulSubprotocolCount,
        PCSTR* pszExtensions,
        ULONG ulExtensionCount,
        const WEB_SOCKET_HTTP_HEADER* pInitialHeaders,
        ULONG ulInitialHeaderCount,
        WEB_SOCKET_HTTP_HEADER** pAdditionalHeaders,
        ULONG* pulAdditionalHeaderCount);

    HRESULT __stdcall WebSocketEndClientHandshake(
        WEB_SOCKET_HANDLE hWebSocket,
        const WEB_SOCKET_HTTP_HEADER* pResponseHeaders,
        ULONG ulReponseHeaderCount,
        ULONG* pulSelectedExtensions,
        ULONG* pulSelectedExtensionCount,
        ULONG* pulSelectedSubprotocol);

    HRESULT __stdcall WebSocketCreateServerHandle(
        const WEB_SOCKET_PROPERTY* pProperties,
        ULONG ulPropertyCount,
        WEB_SOCKET_HANDLE* phWebSocket);

    HRESULT __stdcall WebSocketBeginServerHandshake(
        WEB_SOCKET_HANDLE hWebSocket,
        PCSTR pszSubprotocolSelected,
        PCSTR* pszExtensionSelected,
        ULONG ulExtensionSelectedCount,
        const WEB_SOCKET_HTTP_HEADER* pRequestHeaders,
        ULONG ulRequestHeaderCount,
        WEB_SOCKET_HTTP_HEADER** pResponseHeaders,
        ULONG* pulResponseHeaderCount);

    HRESULT __stdcall WebSocketEndServerHandshake(
        WEB_SOCKET_HANDLE hWebSocket);

    HRESULT __stdcall WebSocketSend(
        WEB_SOCKET_HANDLE hWebSocket,
        int BufferType,
        WEB_SOCKET_BUFFER* pBuffer,
        void* Context);

    HRESULT __stdcall WebSocketReceive(
        WEB_SOCKET_HANDLE hWebSocket,
        WEB_SOCKET_BUFFER* pBuffer,
        void* pvContext);

    HRESULT __stdcall WebSocketGetAction(
        WEB_SOCKET_HANDLE hWebSocket,
        int eActionQueue,
        WEB_SOCKET_BUFFER* pDataBuffers,
        ULONG* pulDataBufferCount,
        int* pAction,
        int* pBufferType,
        void** pvApplicationContext,
        void** pvActionContext);

    void __stdcall WebSocketCompleteAction(
        WEB_SOCKET_HANDLE hWebSocket,
        void* pvActionContext,
        ULONG ulBytesTransferred);

    void __stdcall WebSocketAbortHandle(
        WEB_SOCKET_HANDLE hWebSocket);

    void __stdcall WebSocketDeleteHandle(
        WEB_SOCKET_HANDLE hWebSocket);

    void CopyMemory(void* dst, const void* src, size_t size);

    void FreeLibrary(void* hModule);
]]

local function to_char(str)
    local char = ffi.new("char[?]", #str + 1)
    ffi.copy(char, str)
    return char
end

local function create_handles()
    local clientHandle = ffi.new("WEB_SOCKET_HANDLE[1]")
    local hr = ws.WebSocketCreateClientHandle(nil, 0, clientHandle)
    if hr ~= 0 then
        error("WebSocketCreateClientHandle failed: " .. hr)
    end
    local serverHandle = ffi.new("WEB_SOCKET_HANDLE[1]")
    hr = ws.WebSocketCreateServerHandle(nil, 0, serverHandle)
    if hr ~= 0 then
        error("WebSocketCreateServerHandle failed: " .. hr)
    end
    return clientHandle[0], serverHandle[0]
end

local function dump_headers(headers, count)
    for i = 0, count - 1 do
        local name = ffi.string(headers[i].pcName, headers[i].ulNameLength)
        local value = ffi.string(headers[i].pcValue, headers[i].ulValueLength)
        print(string.format("%s: %s", name, value))
    end
end

local copy = function(dst, src, len)
    local destination = ffi.cast('void*', dst)
    local source = ffi.cast('const void*', src)
    ffi.copy(destination, source, len)
end

local function set_headers(headers, values)
    for i = 0, #values - 1 do
        local name, value = values[i + 1][1], values[i + 1][2]
        headers[i].pcName = to_char(name)
        headers[i].ulNameLength = #name
        headers[i].pcValue = to_char(value)
        headers[i].ulValueLength = #value
    end
end

local function perform_handshake(clientHandle, serverHandle)
    local host = ffi.new("WEB_SOCKET_HTTP_HEADER[1]")
    --host: localhost
    --port: 8080

    set_headers(host, {
        {"Host", "localhost:8080"},
    })

    local clientAdditionalHeaders = ffi.new("WEB_SOCKET_HTTP_HEADER*[?]", 5)
    local clientAdditionalHeaderCount = ffi.new("ULONG[1]")
    local clientHeaderCount = 0

    local hr = ws.WebSocketBeginClientHandshake(clientHandle, nil, 0, nil, 0, nil, 0, clientAdditionalHeaders, clientAdditionalHeaderCount)
    if hr ~= 0 then
        error("WebSocketBeginClientHandshake failed: " .. string.format("%x", hr))
    end

    local clientHeaders = ffi.new("WEB_SOCKET_HTTP_HEADER*[?]", clientAdditionalHeaderCount[0])

    copy(clientHeaders, clientAdditionalHeaders, clientAdditionalHeaderCount[0] * ffi.sizeof("WEB_SOCKET_HTTP_HEADER"))
    clientHeaders[0][clientAdditionalHeaderCount[0]] = host[0]
    clientHeaderCount = clientAdditionalHeaderCount[0] + 1

    dump_headers(clientHeaders[0], clientAdditionalHeaderCount[0])

    -- local serverAdditionalHeaders = ffi.new("WEB_SOCKET_HTTP_HEADER*[?]", 5)
    -- local serverAdditionalHeaderCount = ffi.new("ULONG[1]")

    -- hr = ws.WebSocketBeginServerHandshake(serverHandle, nil, nil, 0, clientHeaders[0], clientHeaderCount, serverAdditionalHeaders, serverAdditionalHeaderCount)

    -- if hr ~= 0 then
    --     error("WebSocketBeginServerHandshake failed: " .. hr)
    -- end

    -- dump_headers(serverAdditionalHeaders, serverAdditionalHeaderCount[0])

    -- print("test")

    -- hr = ws.WebSocketEndClientHandshake(clientHandle, serverAdditionalHeaders, serverAdditionalHeaderCount[0], nil, 0, nil)

    -- if hr ~= 0 then
    --     error("WebSocketEndClientHandshake failed: " .. hr)
    -- end

    -- print(tostring(hr))
end

local function init()
    local clientHandle, serverHandle = create_handles()
    local status, err = pcall(function()
        perform_handshake(clientHandle, serverHandle)
    end)
    if err then
        print("err: " .. tostring(err))
    else
        print("done")
    end
    -- print(tostring(hWebSocket))
end

init()