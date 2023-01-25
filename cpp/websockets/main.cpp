//create websocket pullstyle export api with winhttp
//with function GetData when called will return the data in the buffer

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

const int BUFFER_SIZE = 1024;
struct DataStruct {
    char data[BUFFER_SIZE];
    int length;
};

class WebSocketAPI {
private:
    std::thread dataThread;
    std::vector<DataStruct> data;
    bool running;
    HINTERNET hSession;
    HINTERNET hConnect;
    HINTERNET hRequest;
    HINTERNET hWebSocket;

    void DataThread() {
        while (running) {
            DWORD bytesRead;
            WINHTTP_WEB_SOCKET_BUFFER_TYPE bufferType;
            char tmpBuffer[BUFFER_SIZE];
            if (WinHttpWebSocketReceive(hWebSocket, tmpBuffer, sizeof(tmpBuffer), &bytesRead, &bufferType)) {
                std::unique_lock<std::mutex> lock(bufferMutex);
                DataStruct data;
                data.length = bytesRead;
                memcpy(data.data, tmpBuffer, bytesRead);
                this->data.push_back(data);
            }
        }
    }

public:
    std::mutex bufferMutex;

    bool Connect(const std::wstring &url, int port) {
        running = true;
        hSession = WinHttpOpen(L"WebSocketAPI", WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
        if (!hSession) {
            std::cout << "Error: Failed to open session" << std::endl;
            return false;
        }
        hConnect = WinHttpConnect(hSession, url.c_str(), port, 0);
        if (!hConnect) {
            std::cout << "Error: Failed to connect" << std::endl;
            return false;
        }
        hRequest = WinHttpOpenRequest(hConnect, L"GET", NULL, NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, 0);
        if (!hRequest) {
            std::cout << "Error: Failed to open request" << std::endl;
            return false;
        }
        if (!WinHttpSendRequest(hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, 0, WINHTTP_NO_REQUEST_DATA, 0, 0, 0)) {
            std::cout << "Error: Failed to send request" << std::endl;
            return false;
        }
        if (!WinHttpReceiveResponse(hRequest, NULL)) {
            std::cout << "Error: Failed to receive response" << std::endl;
            return false;
        }
        DWORD dwStatusCode = 0;
        DWORD dwSize = sizeof(dwStatusCode);
        if(!WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER, NULL, &dwStatusCode, &dwSize, NULL)){
            std::cout << "Error: Failed to get status code" << std::endl;
            return false;
        }
        if (dwStatusCode != 101){
            std::cout << "Error: Status code is not 101" << std::endl;
            return false;
        }
        hWebSocket = WinHttpWebSocketCompleteUpgrade(hRequest, NULL);
        if (!hWebSocket){
            std::cout << "Error: Failed to upgrade to websocket" << std::endl;
            return false;
        }
        dataThread = std::thread(&WebSocketAPI::DataThread, this);
        return true;
    }

    DataStruct GetData() {
        std::unique_lock<std::mutex> lock(bufferMutex);
        if (data.size() > 0) {
            DataStruct data = this->data[0];
            this->data.erase(this->data.begin());
            return data;
        }
        else {
            DataStruct data;
            data.length = 0;
            return data;
        }
    }

    void Close() {
        running = false;
        dataThread.join();
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
    }
}