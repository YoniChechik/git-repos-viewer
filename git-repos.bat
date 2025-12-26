@echo off
:: ============================================================================
:: Git Repos Viewer - Opens HTML page listing all git repos in WSL and SSH hosts
::
:: NOTE: SSH uses Windows SSH (not WSL) since config/keys are in Windows
:: ============================================================================

setlocal enabledelayedexpansion

set "htmlfile=%TEMP%\git-repos.html"
set "repolist=%TEMP%\git-repos-list.txt"
set "sshhosts=%TEMP%\ssh-hosts.txt"
set "sshrepos=%TEMP%\ssh-repos.txt"

echo ============================================
echo Git Repos Viewer
echo ============================================

:: ============================================================================
:: START HTML
:: ============================================================================
echo [1/6] Creating HTML header...
(
echo ^<!DOCTYPE html^>
echo ^<html^>
echo ^<head^>
echo ^<title^>Git Repos Viewer^</title^>
echo ^<style^>
echo body { font-family: Consolas, monospace; background: #1e1e1e; color: #d4d4d4; padding: 20px 30px; font-size: 14px; line-height: 1.5; }
echo h1 { color: #569cd6; margin-bottom: 15px; font-size: 18px; }
echo h2 { color: #c586c0; margin: 25px 0 10px 0; font-size: 15px; border-bottom: 1px solid #333; padding-bottom: 5px; }
echo a { text-decoration: none; color: #4ec9b0; }
echo a:hover { color: #6ee9d0; text-decoration: underline; }
echo .t { color: #555; }
echo .dir { color: #dcdcaa; }
echo .section { color: #888; }
echo .offline { color: #f44747; font-style: italic; }
echo pre { margin: 0; }
echo ^</style^>
echo ^</head^>
echo ^<body^>
echo ^<h1^>Git Repositories^</h1^>
) > "%htmlfile%"
echo        Done.

:: ============================================================================
:: WSL REPOS
:: ============================================================================
echo [2/6] Finding repos in WSL...
call wsl.exe bash -c "find ~ -maxdepth 5 -type d -name '.git' 2>/dev/null | sort" > "%repolist%" 2>&1
call timeout /t 2 /nobreak >nul

echo        Found:
type "%repolist%"

echo ^<h2^>WSL (Ubuntu)^</h2^>>> "%htmlfile%"
echo ^<pre^>^<span class="section"^>~/^</span^>>> "%htmlfile%"

set "lastroot="
set "lastmid="

for /f "usebackq delims=" %%p in ("%repolist%") do (
    set "gitdir=%%p"
    set "repodir=!gitdir:/.git=!"
    for %%n in ("!repodir!") do set "reponame=%%~nxn"
    set "relpath=!repodir:/home/yoni/=!"

    for /f "tokens=1,2,3 delims=/" %%a in ("!relpath!") do (
        set "rootfolder=%%a"
        set "second=%%b"
        set "third=%%c"
    )

    if "!relpath!"=="!rootfolder!" (
        echo ^<span class="t"^>+-- ^</span^>^<a href="vscode://vscode-remote/wsl+Ubuntu-24.04!repodir!?windowId=_blank"^>!reponame!^</a^>>> "%htmlfile%"
        set "lastroot=!rootfolder!"
        set "lastmid="
    ) else (
        if "!rootfolder!" neq "!lastroot!" (
            echo ^<span class="t"^>+-- ^</span^>^<a href="vscode://vscode-remote/wsl+Ubuntu-24.04/home/yoni/!rootfolder!?windowId=_blank"^>!rootfolder!^</a^>>> "%htmlfile%"
            set "lastroot=!rootfolder!"
            set "lastmid="
        )

        if defined third (
            if "!second!" neq "!lastmid!" (
                echo ^<span class="t"^>:   +-- ^</span^>^<span class="dir"^>!second!^</span^>>> "%htmlfile%"
                set "lastmid=!second!"
            )
            echo ^<span class="t"^>:   :   +-- ^</span^>^<a href="vscode://vscode-remote/wsl+Ubuntu-24.04!repodir!?windowId=_blank"^>!reponame!^</a^>>> "%htmlfile%"
        ) else (
            echo ^<span class="t"^>:   +-- ^</span^>^<a href="vscode://vscode-remote/wsl+Ubuntu-24.04!repodir!?windowId=_blank"^>!reponame!^</a^>>> "%htmlfile%"
        )
    )
)
echo ^</pre^>>> "%htmlfile%"
echo        WSL section complete.

:: ============================================================================
:: SSH HOSTS - Read from Windows SSH config
:: ============================================================================
echo [3/6] Finding SSH hosts...
findstr /i /b "Host " "%USERPROFILE%\.ssh\config" 2>nul | findstr /v "*" > "%sshhosts%"
:: Clean up - extract just the hostname (second token)
set "temphosts=%TEMP%\ssh-hosts-clean.txt"
(for /f "tokens=2" %%h in (%sshhosts%) do echo %%h) > "%temphosts%"
move /y "%temphosts%" "%sshhosts%" >nul 2>&1

echo        Found hosts:
type "%sshhosts%"

:: Check if we have any SSH hosts
for %%f in ("%sshhosts%") do set "hostfilesize=%%~zf"
if not defined hostfilesize set "hostfilesize=0"

echo [4/6] Scanning SSH hosts for repos...
if %hostfilesize% EQU 0 (
    echo        No SSH hosts found in config.
    goto :skipssh
)

for /f "usebackq delims=" %%h in ("%sshhosts%") do (
    set "sshhost=%%h"
    echo        Checking !sshhost!...

    :: Use Windows SSH directly (not WSL) since SSH config is on Windows
    ssh -o ConnectTimeout=5 -o BatchMode=yes !sshhost! "find ~ -maxdepth 4 -type d -name .git 2>/dev/null" 2>nul | sort > "%sshrepos%"
    call timeout /t 1 /nobreak >nul

    echo        Found on !sshhost!:
    type "%sshrepos%"

    for %%s in ("%sshrepos%") do set "filesize=%%~zs"
    if not defined filesize set "filesize=0"

    echo ^<h2^>SSH: !sshhost!^</h2^>>> "%htmlfile%"
    echo ^<pre^>>> "%htmlfile%"

    if !filesize! GTR 0 (
        echo ^<span class="section"^>~/^</span^>>> "%htmlfile%"

        set "lastroot="
        set "lastmid="

        for /f "usebackq delims=" %%p in ("%sshrepos%") do (
            set "gitdir=%%p"
            set "repodir=!gitdir:/.git=!"
            for %%n in ("!repodir!") do set "reponame=%%~nxn"

            set "relpath=!repodir!"
            set "relpath=!relpath:/home/yoni/=!"
            set "relpath=!relpath:/root/=!"
            set "relpath=!relpath:/home/ubuntu/=!"

            for /f "tokens=1,2,3 delims=/" %%a in ("!relpath!") do (
                set "rootfolder=%%a"
                set "second=%%b"
                set "third=%%c"
            )

            if "!relpath!"=="!rootfolder!" (
                echo ^<span class="t"^>+-- ^</span^>^<a href="vscode://vscode-remote/ssh-remote+!sshhost!!repodir!?windowId=_blank"^>!reponame!^</a^>>> "%htmlfile%"
                set "lastroot=!rootfolder!"
                set "lastmid="
            ) else (
                if "!rootfolder!" neq "!lastroot!" (
                    echo ^<span class="t"^>+-- ^</span^>^<a href="vscode://vscode-remote/ssh-remote+!sshhost!!repodir!?windowId=_blank"^>!rootfolder!^</a^>>> "%htmlfile%"
                    set "lastroot=!rootfolder!"
                    set "lastmid="
                )

                if defined third (
                    if "!second!" neq "!lastmid!" (
                        echo ^<span class="t"^>:   +-- ^</span^>^<span class="dir"^>!second!^</span^>>> "%htmlfile%"
                        set "lastmid=!second!"
                    )
                    echo ^<span class="t"^>:   :   +-- ^</span^>^<a href="vscode://vscode-remote/ssh-remote+!sshhost!!repodir!?windowId=_blank"^>!reponame!^</a^>>> "%htmlfile%"
                ) else (
                    echo ^<span class="t"^>:   +-- ^</span^>^<a href="vscode://vscode-remote/ssh-remote+!sshhost!!repodir!?windowId=_blank"^>!reponame!^</a^>>> "%htmlfile%"
                )
            )
        )
    ) else (
        echo ^<span class="offline"^>[offline or no repos]^</span^>>> "%htmlfile%"
    )
    echo ^</pre^>>> "%htmlfile%"
)

:skipssh
echo        SSH section complete.

:: ============================================================================
:: FINISH
:: ============================================================================
echo [5/6] Finishing HTML...
(
echo ^</body^>
echo ^</html^>
) >> "%htmlfile%"

del "%repolist%" 2>nul
del "%sshhosts%" 2>nul
del "%sshrepos%" 2>nul

echo [6/6] Opening browser...
start "" "%htmlfile%"

echo.
echo ============================================
echo COMPLETE
echo ============================================
call timeout /t 5 /nobreak >nul
