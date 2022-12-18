@echo off
set VSTOOLS="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat"
if not exist %VSTOOLS% (
    echo VS Build Tools are missing!
    exit
)
call %VSTOOLS%

cl /LD /O2 /MD /EHsc /Fe: ./build/sockets.dll main.cpp