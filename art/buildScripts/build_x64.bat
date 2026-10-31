@echo off
color 0a
cd ../..
echo BUILDING GAME
haxelib run lime build windows -DCOMPILE_EXPERIMENTAL -DHXCPP_OPTIMIZE_LINK -release
echo.
echo done.
pause
pwd
explorer.exe export\release\windows\bin
