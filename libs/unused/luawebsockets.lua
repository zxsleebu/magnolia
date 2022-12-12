local ffi = require("ffi")
local http = ffi.load("Winhttp")
require("libs.table")
local errors = require("libs.winerror")
local set = require("libs.set")
-- local error_handler = require("libs.error_handler")()
-- local cbs = require("libs.callbacks")
local threads = require("libs.threads")
ffi.cdef[[
    typedef void* PVOID;
    typedef void* LPVOID;
    typedef unsigned short WORD;
    typedef WORD INTERNET_PORT;
    typedef LPVOID HINTERNET;
    typedef unsigned short USHORT;
    typedef unsigned long ULONG;
    typedef unsigned long ULONG_PTR;
    typedef unsigned long DWORD;
    typedef ULONG_PTR DWORD_PTR;
    typedef int BOOL;
    typedef wchar_t WCHAR;
    typedef const WCHAR* LPCWSTR;

    typedef struct{
        DWORD dwBytesTransferred;
        int eBufferType;
    } WINHTTP_WEB_SOCKET_STATUS;
    typedef void(__stdcall* WINHTTP_STATUS_CALLBACK)(
        HINTERNET hInternet,
        DWORD_PTR dwContext,
        DWORD dwInternetStatus,
        LPVOID lpvStatusInformation,
        DWORD dwStatusInformationLength
    );

    int MultiByteToWideChar(unsigned int CodePage,
        DWORD dwFlags,
        const char* lpMultiByteStr,
        int cbMultiByte,
        wchar_t* lpWideCharStr,
        int cchWideChar
    );

    int WideCharToMultiByte(
        unsigned int CodePage,
        DWORD dwFlags,
        const wchar_t* lpWideCharStr,
        int cchWideChar,
        char* lpMultiByteStr,
        int cbMultiByte,
        const char* lpDefaultChar,
        BOOL* lpUsedDefaultChar
    );

    HINTERNET __stdcall WinHttpOpen(
        LPCWSTR pszAgentW,
        DWORD dwAccessType,
        LPCWSTR pszProxyW,
        LPCWSTR pszProxyBypassW,
        DWORD dwFlags
    );

    HINTERNET __stdcall WinHttpConnect(
        HINTERNET hSession,
        LPCWSTR pswzServerName,
        INTERNET_PORT nServerPort,
        DWORD dwReserved
    );

    HINTERNET __stdcall WinHttpOpenRequest(
        HINTERNET hConnect,
        LPCWSTR pwszVerb,
        LPCWSTR pwszObjectName,
        LPCWSTR pwszVersion,
        LPCWSTR pwszReferrer,
        LPCWSTR* ppwszAcceptTypes,
        DWORD dwFlags
    );

    BOOL __stdcall WinHttpSetOption(
        HINTERNET hInternet,
        DWORD dwOption, 
        LPVOID lpBuffer,
        DWORD dwBufferLength
    );

    BOOL __stdcall WinHttpSendRequest(
        HINTERNET hRequest,
        LPCWSTR lpszHeaders,
        DWORD dwHeadersLength,
        LPVOID lpOptional,
        DWORD dwOptionalLength,
        DWORD dwTotalLength,
        DWORD_PTR dwContext
    );

    BOOL __stdcall WinHttpReceiveResponse(
        HINTERNET hRequest,
        LPVOID lpReserved
    );

    HINTERNET __stdcall WinHttpWebSocketCompleteUpgrade(
        HINTERNET hRequest,
        DWORD_PTR pContext
    );

    BOOL  __stdcall WinHttpCloseHandle(
        HINTERNET hInternet
    );

    DWORD __stdcall WinHttpWebSocketSend(
        HINTERNET hWebSocket,
        int eBufferType,
        PVOID pvBuffer,
        DWORD dwBufferLength
    );
    DWORD __stdcall WinHttpWebSocketReceive(
        HINTERNET hWebSocket,
        PVOID pvBuffer,
        DWORD dwBufferLength,
        DWORD* pdwBytesRead,
        int* peBufferType
    );

    DWORD __stdcall WinHttpWebSocketShutdown(
        HINTERNET hWebSocket,
        USHORT usStatus,
        PVOID pvReason,
        DWORD dwReasonLength
    );

    DWORD __stdcall WinHttpWebSocketClose(
        HINTERNET hWebSocket,
        USHORT usStatus,
        PVOID pvReason,
        DWORD dwReasonLength
    );

    int __stdcall WinHttpSetStatusCallback(
        HINTERNET hInternet,
        WINHTTP_STATUS_CALLBACK lpfnInternetCallback,
        DWORD dwNotificationFlags,
        DWORD_PTR dwReserved
    );

    BOOL __stdcall WinHttpQueryDataAvailable(
        HINTERNET hRequest,
        DWORD*  lpdwNumberOfBytesAvailable
    );

    BOOL __stdcall WinHttpQueryHeaders(
        HINTERNET hRequest,
        DWORD dwInfoLevel,
        LPCWSTR pwszName,
        LPVOID lpBuffer,
        DWORD* lpdwBufferLength,
        DWORD* lpdwIndex
    );
]]

local function L(str)
    local wlen = ffi.C.MultiByteToWideChar(65001, 0, str, #str, nil, 0)
    local wstr = ffi.new("wchar_t[?]", wlen + 1)
    ffi.C.MultiByteToWideChar(65001, 0, str, #str, wstr, wlen)
    return wstr
end
local function S(wstr)
    local len = ffi.C.WideCharToMultiByte(65001, 0, wstr, -1, nil, 0, nil, nil)
    local str = ffi.new("char[?]", len)
    ffi.C.WideCharToMultiByte(65001, 0, wstr, -1, str, len, nil, nil)
    return ffi.string(str)
end
local WINHTTP_CALLBACK_STATUS = {
    RESOLVING_NAME          = 0x00000001,
    NAME_RESOLVED           = 0x00000002,
    CONNECTING_TO_SERVER    = 0x00000004,
    CONNECTED_TO_SERVER     = 0x00000008,
    SENDING_REQUEST         = 0x00000010,
    REQUEST_SENT            = 0x00000020,
    RECEIVING_RESPONSE      = 0x00000040,
    RESPONSE_RECEIVED       = 0x00000080,
    CLOSING_CONNECTION      = 0x00000100,
    CONNECTION_CLOSED       = 0x00000200,
    HANDLE_CREATED          = 0x00000400,
    HANDLE_CLOSING          = 0x00000800,
    DETECTING_PROXY         = 0x00001000,
    REDIRECT                = 0x00004000,
    INTERMEDIATE_RESPONSE   = 0x00008000,
    SECURE_FAILURE          = 0x00010000,
    HEADERS_AVAILABLE       = 0x00020000,
    DATA_AVAILABLE          = 0x00040000,
    READ_COMPLETE           = 0x00080000,
    WRITE_COMPLETE          = 0x00100000,
    -- REQUEST_ERROR           = 0x00200000,
    SENDREQUEST_COMPLETE    = 0x00400000,
    GETPROXYFORURL_COMPLETE = 0x01000000,
    CLOSE_COMPLETE          = 0x02000000,
    SHUTDOWN_COMPLETE       = 0x04000000,
    SETTINGS_WRITE_COMPLETE = 0x10000000,
    SETTINGS_READ_COMPLETE  = 0x20000000,
}
-- local open = function(host, port, url, callback, force_secure)
--     local session = http.WinHttpOpen(L("MAGNOLIA"), 0, nil, nil, callback and 0x10000000 or 0)
--     set_callbacks(session, callback)
--     local connection = http.WinHttpConnect(session, L(host), port, 0)
--     local flags = 0
--     if port == 443 or force_secure then
--         flags = flags + 0x00800000
--     end
--     local request = http.WinHttpOpenRequest(connection, L"GET", url and L(url) or nil, nil, nil, nil, flags)
--     local hr = http.WinHttpSetOption(request, 114, nil, 0)
--     if hr == 0 then
--         report("Failed to set option")
--         return nil
--     end
--     hr = http.WinHttpSendRequest(request, nil, 0, nil, 0, 0, 0)
--     if hr == 0 then
--         report("Failed to send request")
--         return nil
--     end
--     print("RECEIVING_RESPONSE")
--     hr = http.WinHttpReceiveResponse(request, nil)
--     if hr == 0 then
--         report("Failed to receive response")
--         return nil
--     end
--     local websocket = http.WinHttpWebSocketCompleteUpgrade(request, 0)
--     if websocket == nil then
--         report("Failed to upgrade to websocket")
--         return nil
--     end
--     set_callbacks(websocket, callback)
--     http.WinHttpCloseHandle(request)
--     return websocket
-- end

local status_queue = {}
local status_callback = function(handle, context, code, info, length)
    -- print("STATUS: " .. table.find_by_value(WINHTTP_CALLBACK_STATUS, code))
    local status, err = pcall(function()
        if code == WINHTTP_CALLBACK_STATUS.REQUEST_SENT then

        end
        if code == WINHTTP_CALLBACK_STATUS.RESPONSE_RECEIVED then

        end
        -- if code == WINHTTP_CALLBACK_STATUS.HEADERS_AVAILABLE then
        --     print("HEADERS_AVAILABLE")
        -- end
    end)
    if err then errors.check(err) end
end

local open = function (host, port, path)
    local succeeded
    local m_winHttpSession = http.WinHttpOpen(nil, 1, nil, nil, 0) --0x10000000
    if m_winHttpSession == nil then
        errors.report("Failed to open session")
    end
    errors.check("WinHttpOpen")
    local m_winHttpConnection = http.WinHttpConnect(m_winHttpSession, L(host), port, 0)
    if m_winHttpConnection == nil then
        errors.report("Failed to connect")
    end
    errors.check("WinHttpConnect")


    local flags = 0
    for k, v in pairs(WINHTTP_CALLBACK_STATUS) do
        flags = flags + v
    end
    local callbackStatus = http.WinHttpSetStatusCallback(m_winHttpConnection, ffi.cast("WINHTTP_STATUS_CALLBACK", status_callback), flags, 0)
    if callbackStatus == -1 then
        errors.report("Failed to set status callback")
    end
    errors.check("WinHttpSetStatusCallback")

    local m_requestHandle = http.WinHttpOpenRequest(m_winHttpConnection, L"GET", L(path or ""), nil, nil, nil, 0) --0x00800000
    if not m_requestHandle then
        errors.report("Failed to open request")
    end
    errors.check("WinHttpOpenRequest")

    -- local optionFlags = ffi.new("DWORD[1]", 0x100 + 0x200 + 0x1000 + 0x2000)
    -- succeeded = http.WinHttpSetOption(m_requestHandle, 31, optionFlags, ffi.sizeof(optionFlags))
    -- if succeeded == 0 then
    --     errors.report("Failed to set option SECURITY_FLAG_IGNORE_ALL_CERT_ERRORS")
    -- end
    succeeded = http.WinHttpSetOption(m_requestHandle, 114, nil, 0)
    if succeeded == 0 then
        errors.report("Failed to set option WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET")
    end
    errors.check("WinHttpSetOption")

    succeeded = http.WinHttpSendRequest(m_requestHandle, nil, -1, nil, 0, 0, 0)
    if succeeded == 0 then
        errors.report("Failed to send request")
    end
    errors.check("WinHttpSendRequest")

    local success = http.WinHttpReceiveResponse(m_requestHandle, nil)
    if success == 0 then
        errors.report("Failed to receive response")
    end
    errors.check("WinHttpReceiveResponse")

    local status_code = ffi.new("DWORD[1]")
    local status_code_length = ffi.new("DWORD[1]", ffi.sizeof(status_code))
    success = http.WinHttpQueryHeaders(m_requestHandle, 19 + 0x20000000, nil, status_code, status_code_length, nil)
    if success == 0 then
        errors.report("Failed to query status code")
    end
    errors.check("WinHttpQueryHeaders")

    if set(301, 302, 303, 307, 308)[status_code[0]] then
        return print("REDIRECT")
    end
    if status_code[0] ~= 101 then
        return print("NOT_UPGRADEABLE")
    end

    local websocket = http.WinHttpWebSocketCompleteUpgrade(m_requestHandle, 0)
    if not websocket then
        errors.report("Failed to upgrade to websocket")
    end
    errors.check("WinHttpWebSocketCompleteUpgrade")

    return websocket
end
local receive = function(websocket, callback)
    local size = 1024
    local buffer = ffi.new("char[?]", size)
    local bytes_read = ffi.new("DWORD[1]")
    local buffer_type = ffi.new("int[1]")
    local result = http.WinHttpWebSocketReceive(websocket, buffer, size, bytes_read, buffer_type)
    if result ~= 0 or bytes_read[0] == 0 then
        return nil
    end
    local data = ffi.string(buffer, bytes_read[0])
    callback(data)
end
local send = function(websocket, data)
    local buffer = ffi.new("char[?]", #data)
    ffi.copy(buffer, data, #data)
    return http.WinHttpWebSocketSend(websocket, 0, buffer, #data)
end

local counter = 0
-- local ws = open("localhost", 3000)
local t1 = threads.new(function(thread)
    while true do
        thread:sleep(1000)
        print("test")
    end
end)
local t2 = threads.new(function(thread)
    while true do
        thread:sleep(750)
        print("hello")
    end
end)
-- t1:start()
t2:start()

while true do

end