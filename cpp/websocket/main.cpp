// create websocket pullstyle export api with winhttp
// with function GetData when called will return the data in the buffer

#include <iostream>
#include <thread>
#include <mutex>
#include <windows.h>
#include <winhttp.h>
#include <vector>
#pragma comment(lib, "winhttp.lib")
#define export extern "C" __declspec(dllexport)

#define WIN32_LEAN_AND_MEAN
#define VC_EXTRALEAN


using namespace std;

LPCWSTR to_wstring(const char *str)
{
    int len;
    int slength = (int)strlen(str) + 1;
    len = MultiByteToWideChar(CP_ACP, 0, str, slength, 0, 0);
    wchar_t *buf = new wchar_t[len];
    MultiByteToWideChar(CP_ACP, 0, str, slength, buf, len);
    LPCWSTR r(buf);
    delete[] buf;
    return r;
}

bool PrintError(const char* message){
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

const int BUFFER_SIZE = 1024;
struct DataStruct
{
    char code;
    char data[BUFFER_SIZE];
    int length;
};

enum class StatusCodes
{
    CONNECTED,
    DATA,
    CLOSED,
    FAILED
};

class WebSocketAPI
{
private:
    std::thread dataThread;
    std::vector<DataStruct> data;
    bool running;
    HINTERNET hSession;
    HINTERNET hConnect;
    HINTERNET hRequest;
    HINTERNET hWebSocket;
    std::mutex bufferMutex;
    const char *url;
    const char *path;
    int port;

    void Callback(char code, char *buffer, int length){
        DataStruct data;
        data.length = length;
        data.code = code;
        if(length > 0 && buffer != NULL){
            memcpy(data.data, buffer, length);
        }
        bufferMutex.lock();
        this->data.push_back(data);
        bufferMutex.unlock();
    }
    static void DataThread(WebSocketAPI* thisptr)
    {
        while (thisptr->running)
        {
            DWORD bytesRead;
            WINHTTP_WEB_SOCKET_BUFFER_TYPE bufferType;
            char tmpBuffer[BUFFER_SIZE];
            DWORD result = WinHttpWebSocketReceive(thisptr->hWebSocket, tmpBuffer, sizeof(tmpBuffer), &bytesRead, &bufferType);
            if (result == ERROR_SUCCESS && bytesRead > 0)
            {
                thisptr->Callback((char)StatusCodes::DATA, tmpBuffer, bytesRead);
            }
            else if(result == ERROR_WINHTTP_INCORRECT_HANDLE_TYPE
            || result == ERROR_WINHTTP_INCORRECT_HANDLE_STATE
            || result == ERROR_INVALID_OPERATION
            || result == ERROR_WINHTTP_OPERATION_CANCELLED){
                thisptr->Callback((char)StatusCodes::CLOSED, NULL, 0);
                thisptr->Close();
            }
        }
    }
    bool RawConnect(){
        // Create a WinHTTP session.
        if (!(hSession = WinHttpOpen(NULL, WINHTTP_ACCESS_TYPE_NO_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0)))
            return PrintError("Failed to create session");

        // Create a WinHTTP connection.
        if (!(hConnect = WinHttpConnect(hSession, to_wstring(url), port, 0)))
            return PrintError("Failed to create connection");

        // Create a WinHTTP request.
        if (!(hRequest = WinHttpOpenRequest(hConnect, L"GET", to_wstring(path), NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, 0)))
            return PrintError("Failed to create request");

        // Add upgrade header.
        if (!WinHttpSetOption(hRequest, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, NULL, 0))
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
        if (!WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER, NULL, &dwStatusCode, &dwSize, NULL))
            return PrintError("Failed to get status code");

        // If status code is not 101, return.
        if (dwStatusCode != 101)
            return PrintError("Status code is not 101");

        // Upgrade to web socket.
        if (!(hWebSocket = WinHttpWebSocketCompleteUpgrade(hRequest, NULL)))
            return PrintError("Failed to upgrade to web socket");

        running = true;

        CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)&WebSocketAPI::DataThread, this, 0, NULL);
        return true;
    }
    static void ConnectionHandler(WebSocketAPI* socket) {
        bool result = socket->RawConnect();
        if (result) {
            socket->Callback((char)StatusCodes::CONNECTED, NULL, 0);
        }
        else{
            socket->Callback((char)StatusCodes::FAILED, NULL, 0);
        }
    }
public:
    WebSocketAPI(const char *url, const char* path, int port)
    {
        this->url = url;
        this->port = port;
        this->path = path;
    }
    virtual void Connect()
    {
        CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)ConnectionHandler, this, 0, NULL);
    }

    virtual bool GetData(DataStruct &buffer)
    {
        bufferMutex.lock();
        if (data.size() > 0)
        {
            memcpy(&buffer, &this->data[0], sizeof(DataStruct));
            this->data.erase(this->data.begin());
            bufferMutex.unlock();
            return true;
        }
        else
        {
            bufferMutex.unlock();
            return false;
        }
    }

    virtual bool Send(char* data, int length)
    {
        if(WinHttpWebSocketSend(hWebSocket, WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE, data, length) == ERROR_SUCCESS){
            PrintError("Sent data");
            return true;
        }
        else{
            return PrintError("Failed to send data");
        };
    }
    virtual void Close()
    {
        Callback((char)StatusCodes::CLOSED, NULL, 0);
        running = false;
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
    }
    virtual void Delete()
    {
        Close();
        delete this;
    }
};

export WebSocketAPI* Create(const char *url, const char* path, int port){
    return new WebSocketAPI(url, path, port);
}