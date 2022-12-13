#include <windows.h>
#include <iostream>
#include <Psapi.h>
#define export extern "C" __declspec(dllexport)
#define WIN32_LEAN_AND_MEAN
#define VC_EXTRALEAN

BOOL APIENTRY DllMain(
    HANDLE hModule,
    DWORD ul_reason_for_call, 
    LPVOID lpReserved ){
    return TRUE;
}

using namespace std;

export DWORD GetAllocbase(){
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    MEMORY_BASIC_INFORMATION mbi;
    
    DWORD min = (DWORD)si.lpMinimumApplicationAddress;
    DWORD max = (DWORD)si.lpMaximumApplicationAddress;

    DWORD cur = min;
    while(cur < max){
        VirtualQuery((void*)cur, &mbi, sizeof(mbi));
        if(mbi.State == MEM_COMMIT && mbi.Type == MEM_PRIVATE && mbi.Protect == PAGE_EXECUTE_READWRITE)
            return (DWORD)mbi.AllocationBase;
        cur = (DWORD)mbi.BaseAddress + mbi.RegionSize;
    }
    return 0;
}