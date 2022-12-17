require("libs.types")
ffi.cdef[[
    typedef struct {
        union {
            DWORD dwOemId;
            struct {
                WORD wProcessorArchitecture;
                WORD wReserved;
            } DUMMYSTRUCTNAME;
        } DUMMYUNIONNAME;
        DWORD dwPageSize;
        void* lpMinimumApplicationAddress;
        void* lpMaximumApplicationAddress;
        DWORD dwActiveProcessorMask;
        DWORD dwNumberOfProcessors;
        DWORD dwProcessorType;
        DWORD dwAllocationGranularity;
        WORD wProcessorLevel;
        WORD wProcessorRevision;
    } SYSTEM_INFO;
    void GetSystemInfo(SYSTEM_INFO*);
    BOOL GetVolumeInformationA(const char*, char*, DWORD, DWORD*, DWORD*, DWORD*, char*, DWORD);
]]
return function()
    local si = ffi.new("SYSTEM_INFO[1]")
    ffi.C.GetSystemInfo(si)
    local info = si[0]
    local hwid = {
        type = info.dwProcessorType,
        cores = info.dwNumberOfProcessors,
        proc_level = info.wProcessorLevel,
        revision = info.wProcessorRevision,
    }
    local hdd_id = ffi.new("DWORD[1]")
    ffi.C.GetVolumeInformationA("C:\\", nil, 0, hdd_id, nil, nil, nil, 0)
    hwid.hdd = hdd_id[0]
    return hwid
end