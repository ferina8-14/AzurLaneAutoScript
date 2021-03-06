@rem
:: Used for "Alas-Deploy-Tool-V4.bat" in =Preparation=
:: Pay attention to %cd% limit according to each Function.
:: e.g.
:: call command\Get.bat Proxy
:: call command\Get.bat InfoOpt1
:: call command\Get.bat DeployMode

@echo off
call :Import_%~1
goto :eof

rem ================= FUNCTIONS =================

:Import_Deploy

set FirstRun=no && call command\Config.bat FirstRun %FirstRun%

:: %cd%: "%root%"
:: Get %Language% , %Region% , %SystemType%
:Import_Main
:: 1. Get customized %Language%, or decided by "LanguageSelector"
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set datetime=%datetime:~0,8%-%datetime:~8,6%
if exist config\alas.ini (
    echo f | xcopy /y config\alas.ini config\backup\alas_%datetime%.ini > nul
)
if not exist toolkit\log (
    md toolkit\log > nul
)
call command\SystemSet.bat
call command\LanguageSet.bat
if exist config\alas.ini (
    for /f "tokens=3 delims= " %%i in ('findstr /i "github_token" config\alas.ini') do ( set "GithubToken=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "serial" config\alas.ini') do ( set "SerialAlas=%%i" )
)
if exist config\template.ini (
    for /f "tokens=3 delims= " %%i in ('findstr /i "serial" config\template.ini') do ( set "SerialTemplate=%%i" )
)
if exist config\deploy.ini ( goto CheckFields )
:CheckFields
    findstr /i "AutoMode" config\deploy.ini>nul
    if "%errorlevel%" == "1" ( ( echo AutoMode = disable)>>config\deploy.ini )
    for /f "tokens=3 delims= " %%i in ('findstr /i "AutoMode" config\deploy.ini') do ( set "AutoMode=%%i" )
    findstr /i "DefaultServer" config\deploy.ini>nul
    if "%errorlevel%" == "1"  ( ( echo DefaultServer = disable)>>config\deploy.ini )
    for /f "tokens=3 delims= " %%i in ('findstr /i "DefaultServer" config\deploy.ini') do ( set "DefaultServer=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "Language" config\deploy.ini') do ( set "Language=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "Region" config\deploy.ini') do ( set "Region=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "SystemType" config\deploy.ini') do ( set "SystemType=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "FirstRun" config\deploy.ini') do ( set "FirstRun=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "IsUsingGit" config\deploy.ini') do ( set "IsUsingGit=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "KeepLocalChanges" config\deploy.ini') do ( set "KeepLocalChanges=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "RealtimeMode" config\deploy.ini') do ( set "RealtimeMode=%%i" )
    findstr /i "DefaultBluestacksInstance" config\deploy.ini>nul
    if "%errorlevel%" == "1" ( ( echo DefaultBluestacksInstance = unknown)>>config\deploy.ini )
    for /f "tokens=3 delims= " %%i in ('findstr /i "DefaultBluestacksInstance" config\deploy.ini') do ( set "DefaultBluestacksInstance=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "Branch" config\deploy.ini') do ( set "Branch=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "AdbConnect" config\deploy.ini') do ( set "AdbConnect=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "Serial" config\deploy.ini') do ( set "SerialDeploy=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "AdbKillServer" config\deploy.ini') do ( set "KillServer=%%i" )
goto :eof

:Import_Serial
if "%FirstRun%"=="no" goto :eof
echo ====================================================================================================
echo Enter your HOST:PORT eg: 127.0.0.1:5555
echo If you misstype, you can set in Settings menu Option 3
echo ====================================================================================================
set /p serial_input=Please input - SERIAL ^(DEFAULT 127.0.0.1:5555 ^):
if "%serial_input%"=="" ( set "serial_input=127.0.0.1:5555" )
%adbBin% kill-server > nul 2>&1
%adbBin% connect %serial_input% | find /i "connected to" >nul
echo ====================================================================================================
if errorlevel 1 (
    echo The connection was not successful on SERIAL: %SerialDeploy%
    echo == If you use LDplayer, Memu, NoxAppPlayer or MuMuPlayer, you may need replace your emulator ADB.
    echo Check our wiki for more info
    pause > NUL
    start https://github.com/LmeSzinc/AzurLaneAutoScript/wiki/FAQ_en_cn
    goto Import_Serial
) else (
    call command\Config.bat Serial %serial_input%
    call command\ConfigTemplate.bat SerialTemplate %serial_input%
    %pyBin% -m uiautomator2 init
    echo The connection was Successful on SERIAL: %SerialDeploy%
)
echo ====================================================================================================
echo Old Serial:      %SerialDeploy%
echo New Serial:      %serial_input%
echo ====================================================================================================
echo Press any to continue...
pause > NUL
goto :eof

:: %cd%: "%root%"
:: Get the proxy settings of CMD from "config\deploy.ini"
:Import_Proxy
if exist config\deploy.ini (
    for /f "tokens=3 delims= " %%i in ('findstr /i "Proxy" config\deploy.ini') do ( set "state_globalProxy=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "ProxyHost" config\deploy.ini') do ( set "__proxyHost=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "HttpPort" config\deploy.ini') do ( set "__httpPort=%%i" )
    for /f "tokens=3 delims= " %%i in ('findstr /i "HttpsPort" config\deploy.ini') do ( set "__httpsPort=%%i" )
) else ( set "state_globalProxy=disable" )
goto :eof

:: Get %DeployMode% from "deploy.log"
:Import_DeployMode
if exist deploy.log (
    for /f "tokens=2 delims= " %%i in ('findstr /i "DeployMode" deploy.log') do ( set "DeployMode=%%i" )
) else ( set "DeployMode=unknown" )
goto :eof

:: %cd%: "%root%"
:: Get %opt2_info% according to "deploy.log"
:Import_InfoOpt2
set "opt2_info="
if exist deploy.log (
    pushd toolkit && call :Import_DeployMode && popd
    if "!DeployMode!"=="New" set "opt2_info=(New)"
    if "!DeployMode!"=="Legacy" set "opt2_info=(Legacy)"
)
goto :eof

:: %cd%: No limit
:: Get %opt1_info% according to :Import_GlobalProxy ; Apply the proxy settings if Proxy is enabled.
:: call :Import_Proxy before calling this function.
:Import_InfoOpt1
if "%state_globalProxy%"=="enable" (
    set "http_proxy=%__proxyHost%:%__httpPort%"
    set "https_proxy=%__proxyHost%:%__httpsPort%"
    set "opt1_info=(Global Proxy: enabled)"
) else ( set "opt1_info=" )
goto :eof

rem ================= End of File =================
