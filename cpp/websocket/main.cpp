#define WIN32_LEAN_AND_MEAN
#define VC_EXTRALEAN

#include <mutex>
#include <vector>
#include "windows.h"
#define IXWEBSOCKET_USE_OPEN_SSL
#pragma comment(lib, "ixwebsocket.lib")
#pragma comment(lib, "libssl.lib")
#pragma comment(lib, "libcrypto.lib")
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "crypt32.lib")
#pragma comment(lib, "shlwapi.lib")
#include <ixwebsocket/IXNetSystem.h>
#include <ixwebsocket/IXWebSocket.h>
#include <ixwebsocket/IXUserAgent.h>


#define export extern "C" __declspec(dllexport)

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
    std::vector<DataStruct> data;
    bool running;
    std::mutex bufferMutex;
    ix::WebSocket ws;

    void Callback(char code, char *buffer, int length)
    {
        DataStruct data;
        data.length = length;
        data.code = code;
        if (length > 0 && buffer != NULL)
            memcpy(data.data, buffer, length);
        bufferMutex.lock();
        this->data.push_back(data);
        bufferMutex.unlock();
    }

public:
    WebSocketAPI(const char *url)
    {
        ws.setUrl(url);
        ws.setOnMessageCallback([this](const ix::WebSocketMessagePtr &msg){
            if (msg->type == ix::WebSocketMessageType::Message){
                Callback((char)StatusCodes::DATA, (char *)msg->str.c_str(), msg->str.length());
            }
            else if (msg->type == ix::WebSocketMessageType::Open){
                Callback((char)StatusCodes::CONNECTED, NULL, 0);
            }
            else if (msg->type == ix::WebSocketMessageType::Error){
                Callback((char)StatusCodes::FAILED, NULL, 0);
            }
        });
    }
    virtual void Connect()
    {
        ix::SocketTLSOptions tlsOptions;
        tlsOptions.tls = true;
        ws.setTLSOptions(tlsOptions);
        ws.disableAutomaticReconnection();
        ws.disablePerMessageDeflate();
        ws.disablePong();
        ws.start();
    }
    virtual bool IsDataAvailable()
    {
        bufferMutex.lock();
        bool result = data.size() > 0;
        bufferMutex.unlock();
        return result;
    }
    virtual bool GetData(DataStruct &buffer)
    {
        if (&buffer == NULL)
            return false;
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

    virtual bool Send(const char *data)
    {
        auto info = ws.sendUtf8Text(data);
        return info.success;
    }
    virtual void Close()
    {
        bufferMutex.lock();
        bufferMutex.unlock();
        ws.stop();
    }
};

std::vector<WebSocketAPI *> sockets;

export WebSocketAPI *Create(const char *url)
{
    WebSocketAPI *socket = new WebSocketAPI(url);
    sockets.push_back(socket);
    return socket;
}
export void Unload(){
    for (auto &socket : sockets)
    {
        if(socket != NULL)
            socket->Close();
    }
    ix::uninitNetSystem();
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID lpReserved)
{
    if (reason == DLL_PROCESS_ATTACH)
        ix::initNetSystem();
    return TRUE;
}