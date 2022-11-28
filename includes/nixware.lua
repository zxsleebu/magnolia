local error_handler = require("libs.error_handler")()
local cbs = require("libs.callbacks")
local PSAPI = ffi.load("psapi")
ffi.cdef[[
    typedef unsigned long DWORD;
    typedef unsigned short WORD;
    typedef unsigned long ULONG_PTR;
    typedef int BOOL;
    typedef ULONG_PTR SIZE_T;
    typedef void* HANDLE;
    typedef struct {
        DWORD   BaseAddress;
        DWORD   AllocationBase;
        DWORD   AllocationProtect;
        WORD    PartitionId;
        DWORD   RegionSize;
        DWORD   State;
        DWORD   Protect;
        DWORD   Type;
    } MEMORY_BASIC_INFORMATION;
    typedef struct {
        union {
            DWORD dwOemId;
            struct {
                WORD wProcessorArchitecture;
                WORD wReserved;
            } DUMMYSTRUCTNAME;
        } DUMMYUNIONNAME;
        DWORD       dwPageSize;
        DWORD       lpMinimumApplicationAddress;
        DWORD       lpMaximumApplicationAddress;
        ULONG_PTR   dwActiveProcessorMask;
        DWORD       dwNumberOfProcessors;
        DWORD       dwProcessorType;
        DWORD       dwAllocationGranularity;
        WORD        wProcessorLevel;
        WORD        wProcessorRevision;
    } SYSTEM_INFO;
    typedef struct {
        DWORD  cb;
        DWORD  PageFaultCount;
        SIZE_T PeakWorkingSetSize;
        SIZE_T WorkingSetSize;
        SIZE_T QuotaPeakPagedPoolUsage;
        SIZE_T QuotaPagedPoolUsage;
        SIZE_T QuotaPeakNonPagedPoolUsage;
        SIZE_T QuotaNonPagedPoolUsage;
        SIZE_T PagefileUsage;
        SIZE_T PeakPagefileUsage;
    } PROCESS_MEMORY_COUNTERS;
    typedef struct {
        DWORD lpBaseOfDll;
        DWORD SizeOfImage;
        void* EntryPoint;
    } MODULE_INFO;
    void* GetCurrentProcess();
    void GetSystemInfo(SYSTEM_INFO*);
    size_t VirtualQuery(DWORD, MEMORY_BASIC_INFORMATION*, size_t);
    BOOL GetProcessMemoryInfo(DWORD, PROCESS_MEMORY_COUNTERS*, DWORD);
    BOOL EnumProcessModules(DWORD, void*, DWORD, DWORD*);
    BOOL GetModuleBaseNameA(DWORD, void*, char*, DWORD);
    BOOL GetModuleInformation(DWORD, void*, void*, DWORD);
    typedef struct{
        float x;
        float y;
        float z;
    } vector_t;
]]
local C = ffi.C
local nixware = {
    __scan = {
        percent = 0,
    },
    allocbase = nil,
}
nixware.get_allocbase = error_handler(function()
    local si, pmi = ffi.new("SYSTEM_INFO[1]"), ffi.new("PROCESS_MEMORY_COUNTERS[1]")
    local mbi, mbi_size = ffi.new("MEMORY_BASIC_INFORMATION[1]"), ffi.sizeof("MEMORY_BASIC_INFORMATION")
    local proc = -1

    ffi.C.GetSystemInfo(si)
    PSAPI.GetProcessMemoryInfo(proc, pmi, ffi.sizeof("PROCESS_MEMORY_COUNTERS"))

    local min = si[0].lpMinimumApplicationAddress
    local max = math.min(min + pmi[0].WorkingSetSize * 2, si[0].lpMaximumApplicationAddress)

    local modules = {}
    local module_list, module_list_size = ffi.new("HANDLE[1024]"), ffi.new("DWORD[1]")
    PSAPI.EnumProcessModules(proc, module_list, ffi.sizeof(module_list), module_list_size)
    local module_count = module_list_size[0] / ffi.sizeof("HANDLE")
    for i = 0, module_count - 1 do
        local module = module_list[i]
        local module_name, module_info = ffi.new("char[256]"), ffi.new("MODULE_INFO[1]")
        PSAPI.GetModuleBaseNameA(proc, module, module_name, 256)
        PSAPI.GetModuleInformation(proc, module, module_info, ffi.sizeof(module_info))
        modules[module_info[0].lpBaseOfDll] = {
            name = ffi.string(module_name),
            size = module_info[0].SizeOfImage
        }
    end
    local cur = min
    while cur < max do
        pcall(function()
            coroutine.yield()
            nixware.__scan.percent = (cur - min) / (max - min)
            C.VirtualQuery(cur, mbi, mbi_size)

            if modules[mbi[0].AllocationBase] then
                cur = cur + modules[mbi[0].AllocationBase].size
                -- print(string.format("Skipping module %s", modules[mbi[0].AllocationBase].name))
                return
            end
            if mbi[0].State == 0x20 and mbi[0].Protect == 0x20000 then
                nixware.allocbase = mbi[0].AllocationBase
                -- print(string.format("Found nixware at 0x%x", nixware.allocbase))
            end
            cur = mbi[0].BaseAddress + mbi[0].RegionSize
        end)
        if nixware.allocbase then break end
    end
    nixware.__scan.percent = 1
end, "nixware.get_allocbase")
local allocbase_scanner = coroutine.wrap(nixware.get_allocbase)
nixware.init = function()
    cbs.add("paint", function()
        if nixware.allocbase then return end
        pcall(function() for _ = 1, 100 do allocbase_scanner() end end)
        if not nixware.allocbase then return end

        print("nixware allocbase found")
    end)
end

-- client.register_callback("paint", function()
--     print("test")
-- end)


return nixware