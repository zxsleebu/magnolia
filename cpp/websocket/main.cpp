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
};
map<HINTERNET, ThreadContext*> requests;
export bool Close(HINTERNET hWebSocket){
    // If handle is not found, return.
    if (requests.find(hWebSocket) == requests.end()) return false;
    // Terminate thread.
    auto thread = requests[hWebSocket]->thread;
    requests[hWebSocket]->running = false;
    // TerminateThread(thread, 0);
    CloseHandle(thread);
    requests.erase(hWebSocket);
    // Close handles.
    WinHttpWebSocketClose(hWebSocket, 1000, NULL, 0);
    WinHttpCloseHandle(hWebSocket);
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
            Close(context->hWebSocket);
            return;
        }
    }
}

export CallbackData* GetData(HINTERNET hWebSocket){
    if (requests.find(hWebSocket) == requests.end()) return NULL;
    auto context = requests[hWebSocket];
    if(context->data.size() == 0) return NULL;
    auto data = new CallbackData(context->data[0]);
    context->data.erase(context->data.begin());
    return data;
}

export HINTERNET Connect(const char* host, int port, const char* path){
    // Create a WinHTTP session.
    HINTERNET hSession = WinHttpOpen(NULL, WINHTTP_ACCESS_TYPE_NO_PROXY, WINHTTP_NO_PROXY_NAME,WINHTTP_NO_PROXY_BYPASS, 0);
    if (hSession == NULL) return PrintError("Failed to create session");

    // Create a WinHTTP connection.
    HINTERNET hConnect = WinHttpConnect(hSession, to_wstring(host), port, 0);
    if (hConnect == NULL) return PrintError("Failed to create connection");

    // Create a WinHTTP request.
    HINTERNET hRequest = WinHttpOpenRequest(hConnect, L"GET", to_wstring(path), NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, 0);
    if (hRequest == NULL) return PrintError("Failed to create request");
    
    // Add upgrade header.
    if(!WinHttpSetOption(hRequest, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, NULL, 0)) return PrintError("Failed to set upgrade header");

    // Send a request.
    if (!WinHttpSendRequest(hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, -1, WINHTTP_NO_REQUEST_DATA, 0, 0, 0)) return PrintError("Failed to send request");

    // End the request.
    if (!WinHttpReceiveResponse(hRequest, NULL)) return PrintError("Failed to receive response");

    // Get status code.
    DWORD dwStatusCode = 0;
    DWORD dwSize = sizeof(dwStatusCode);
    if(!WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER, NULL, &dwStatusCode, &dwSize, NULL))
        return PrintError("Failed to get status code");

    //If status code is not 101, return.
    if (dwStatusCode != 101) return PrintError("Status code is not 101");
    
    // Upgrade to web socket.
    HINTERNET hWebSocket = WinHttpWebSocketCompleteUpgrade(hRequest, NULL);
    if (hWebSocket == NULL) return PrintError("Failed to upgrade to web socket");

    // Close handles.
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);

    // Create thread to receive data.
    auto context = new ThreadContext{ hWebSocket };
    HANDLE hThread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)FetchData, context, 0, NULL);

    // Add connected data.
    AddData(context, StatusCodes::CONNECTED, NULL, 0);

    // Add to map.
    context->thread = hThread;
    requests[hWebSocket] = context;

    return hWebSocket;
}
export bool Send(HINTERNET hWebSocket, char* data, int length){
    // Send data.
    if(WinHttpWebSocketSend(hWebSocket, WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE, data, length) != ERROR_SUCCESS){
        PrintError("Failed to send data");
        return false;
    }
    return true;
}