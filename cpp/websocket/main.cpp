#include <windows.h>
#include <winhttp.h>
#include <map>
#include <iostream>
#include <vector>
#pragma comment(lib, "winhttp.lib")
#define export extern "C" __declspec(dllexport)
#define WIN32_LEAN_AND_MEAN
#define VC_EXTRALEAN

BOOL APIENTRY DllMain(
    HANDLE hModule,	   // Handle to DLL module 
    DWORD ul_reason_for_call, 
    LPVOID lpReserved )     // Reserved
{
   return TRUE;
}

using namespace std;

// Convert a char* string to a wchar_t* string.
LPCWSTR to_wstring(const char* str) {
    int len;
    int slength = (int)strlen(str) + 1;
    len = MultiByteToWideChar(CP_ACP, 0, str, slength, 0, 0);
    wchar_t* buf = new wchar_t[len];
    MultiByteToWideChar(CP_ACP, 0, str, slength, buf, len);
    LPCWSTR r(buf);
    delete[] buf;
    return r;
}
void* PrintError(const char* message){
    // DWORD dw = GetLastError();
    // LPVOID lpMsgBuf;
    // FormatMessage(
    //     FORMAT_MESSAGE_ALLOCATE_BUFFER |
    //     FORMAT_MESSAGE_FROM_SYSTEM |
    //     FORMAT_MESSAGE_IGNORE_INSERTS,
    //     NULL,
    //     dw,
    //     MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
    //     (LPTSTR)&lpMsgBuf,
    //     0, NULL);
    // cout << message << ": " << (char*)lpMsgBuf << endl;
    // LocalFree(lpMsgBuf);

    return NULL;
}

enum class StatusCodes{
    CONNECTED,
    DATA,
    CLOSED,
    FAILED
};
const int BUFFER_SIZE = 1024;
struct CallbackData{
    StatusCodes code;
    char data[BUFFER_SIZE];
    int length;
};
struct ThreadContext{
    HINTERNET hWebSocket;
    HANDLE thread;
    bool running = true;
    vector<CallbackData> data;
    HANDLE handle;
};
map<HINTERNET, ThreadContext*> requests;
export bool Close(HANDLE handle){
    // If handle is not found, return.
    if (requests.find(handle) == requests.end()) return false;
    // Terminate thread.
    auto context = requests[handle];
    context->running = false;
    // TerminateThread(thread, 0);
    CloseHandle(context->thread);
    // Close handles.
    WinHttpWebSocketClose(context->hWebSocket, 1000, NULL, 0);
    WinHttpCloseHandle(context->hWebSocket);

    requests.erase(handle);
    return true;
}

void AddData(ThreadContext* context, StatusCodes code, char* buffer, int length){
    CallbackData data;
    data.code = code;
    data.length = length;
    memcpy(data.data, buffer, length);
    context->data.push_back(data);
}
void FetchData(ThreadContext *context){
    // Receive data.
    DWORD dwBytesRead = 0;
    char* buffer = new char[BUFFER_SIZE];
    WINHTTP_WEB_SOCKET_BUFFER_TYPE bufferType;
    HINTERNET socket = context->hWebSocket;
    while (context->running){
        DWORD result = WinHttpWebSocketReceive(socket, buffer, BUFFER_SIZE, &dwBytesRead, &bufferType);
        if(result == ERROR_SUCCESS && dwBytesRead > 0)
            AddData(context, StatusCodes::DATA, buffer, dwBytesRead);
        if(result == ERROR_WINHTTP_INCORRECT_HANDLE_TYPE
        || result == ERROR_WINHTTP_INCORRECT_HANDLE_STATE
        || result == ERROR_INVALID_OPERATION
        || result == ERROR_WINHTTP_OPERATION_CANCELLED){
            AddData(context, StatusCodes::CLOSED, NULL, 0);
            Close(context->handle);
            return;
        }
    }
}

export CallbackData* GetData(HANDLE handle){
    if (requests.find(handle) == requests.end()) return NULL;
    auto context = requests[handle];
    if(context->data.size() == 0) return NULL;
    auto data = new CallbackData(context->data[0]);
    context->data.erase(context->data.begin());
    return data;
}

HINTERNET ConnectToServer(const char* host, int port, const char* path, ThreadContext* context){
    // Create a WinHTTP session.
    HINTERNET hSession = WinHttpOpen(NULL, WINHTTP_ACCESS_TYPE_NO_PROXY, WINHTTP_NO_PROXY_NAME,WINHTTP_NO_PROXY_BYPASS, 0);
    if (hSession == NULL)
        return PrintError("Failed to create session");

    // Create a WinHTTP connection.
    HINTERNET hConnect = WinHttpConnect(hSession, to_wstring(host), port, 0);
    if (hConnect == NULL)
        return PrintError("Failed to create connection");

    // Create a WinHTTP request.
    HINTERNET hRequest = WinHttpOpenRequest(hConnect, L"GET", to_wstring(path), NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, 0);
    if (hRequest == NULL)
        return PrintError("Failed to create request");
    
    // Add upgrade header.
    if(!WinHttpSetOption(hRequest, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, NULL, 0))
        return PrintError("Failed to set upgrade header");

    // Send a request.
    if (!WinHttpSendRequest(hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, -1, WINHTTP_NO_REQUEST_DATA, 0, 0, 0))
        return PrintError("Failed to send request");

    // End the request.
    if (!WinHttpReceiveResponse(hRequest, NULL))
        return PrintError("Failed to receive response");

    // Get status code.
    DWORD dwStatusCode = 0;
    DWORD dwSize = sizeof(dwStatusCode);
    if(!WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER, NULL, &dwStatusCode, &dwSize, NULL))
        return PrintError("Failed to get status code");

    //If status code is not 101, return.
    if (dwStatusCode != 101)
        return PrintError("Status code is not 101");
    
    // Upgrade to web socket.
    HINTERNET hWebSocket = WinHttpWebSocketCompleteUpgrade(hRequest, NULL);
    if (hWebSocket == NULL)
        return PrintError("Failed to upgrade to web socket");

    // Close handles.
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);

    context->hWebSocket = hWebSocket;

    HANDLE hThread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)FetchData, context, 0, NULL);

    // Add connected data.
    AddData(context, StatusCodes::CONNECTED, NULL, 0);

    // Add to map.
    context->thread = hThread;

    return hWebSocket;
}

struct ConnectionThreadContext{
    const char* host;
    int port;
    const char* path;
    HANDLE handle;
};
void ConnectionThread(ConnectionThreadContext* info){
    // Create thread to receive data.
    auto context = new ThreadContext{ };
    context->handle = info->handle;
    requests[context->handle] = context;

    HINTERNET hWebSocket = ConnectToServer(info->host, info->port, info->path, context);
    
    if(hWebSocket == NULL){
        AddData(context, StatusCodes::FAILED, NULL, 0);
        return;
    };
}

export HANDLE Connect(const char* host, int port, const char* path){
    //Generate random handle.
    HANDLE handle = (HANDLE)rand();
    // Create thread to connect.
    auto context = new ConnectionThreadContext{ host, port, path, handle };
    CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)ConnectionThread, context, 0, NULL);

    return handle;
}
export bool Send(HANDLE handle, char* data, int length){
    if (requests.find(handle) == requests.end()) return false;
    auto context = requests[handle];
    // Send data.
    if(WinHttpWebSocketSend(context->hWebSocket, WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE, data, length) != ERROR_SUCCESS){
        PrintError("Failed to send data");
        return false;
    }
    return true;
}