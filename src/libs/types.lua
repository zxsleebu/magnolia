ffi.cdef[[
    typedef unsigned long DWORD;
    typedef unsigned short WORD;
    typedef unsigned long ULONG_PTR;
    typedef ULONG_PTR SIZE_T;
    typedef void* HANDLE;
    typedef int BOOL;
    typedef struct{
        char r, g, b, a;
    } color_t;
    typedef struct{
        float x, y, z;
    } vector_t;
    typedef const wchar_t* LPCWSTR;
    typedef LPCWSTR PCWSTR;
    typedef unsigned int UINT;
    typedef const char* PCSTR;
]]