@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title TasteNest - JDBC Presentation
color 0A
cls
echo =====================================================
echo              TASTENEST JDBC PROJECT
echo =====================================================
echo.
echo [1/5] Checking Java JDK...
set "JAVA_EXE="
set "JDK_HOME="
for /d %%D in ("C:\Program Files\Java\jdk-*") do if exist "%%~fD\bin\javac.exe" set "JDK_HOME=%%~fD"
for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-*") do if exist "%%~fD\bin\javac.exe" set "JDK_HOME=%%~fD"
for /d %%D in ("C:\Program Files\Microsoft\jdk-*") do if exist "%%~fD\bin\javac.exe" set "JDK_HOME=%%~fD"
for /d %%D in ("C:\Program Files\Zulu\zulu-*") do if exist "%%~fD\bin\javac.exe" set "JDK_HOME=%%~fD"
if not defined JDK_HOME if defined JAVA_HOME if exist "%JAVA_HOME%\bin\javac.exe" set "JDK_HOME=%JAVA_HOME%"
if defined JDK_HOME set "JAVA_HOME=%JDK_HOME%"
if defined JDK_HOME set "PATH=%JDK_HOME%\bin;%PATH%"
if not defined JDK_HOME (
  for /f "delims=" %%J in ('where java 2^>nul') do set "JAVA_EXE=%%J" & goto :java_found
)
:java_found
if not defined JDK_HOME (
  echo.
  echo ERROR: Java JDK was not found.
  echo Java may be installed, but the JDK path is not available to this launcher.
  echo.
  echo Please send me a screenshot of this window.
  pause
  exit /b 1
)
echo JDK found: %JDK_HOME%
"%JAVA_HOME%\bin\java.exe" -version
echo.
echo [2/5] Preparing Maven...
set "TOOLS=%~dp0tools"
set "MAVEN=%TOOLS%\apache-maven-3.9.16"
set "MAVEN_ZIP=%TOOLS%\maven.zip"
if not exist "%MAVEN%\bin\mvn.cmd" (
  if not exist "%TOOLS%" mkdir "%TOOLS%"
  echo Downloading Maven 3.9.16. Please wait...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest 'https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.zip' -OutFile '%MAVEN_ZIP%'"
  if errorlevel 1 goto :download_error
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%MAVEN_ZIP%' -DestinationPath '%TOOLS%' -Force"
  if errorlevel 1 goto :download_error
  del /q "%MAVEN_ZIP%" >nul 2>&1
)
echo Maven ready.
echo.
echo [3/5] Preparing Tomcat...
set "TOMCAT=%TOOLS%\apache-tomcat-10.1.60"
set "TOMCAT_ZIP=%TOOLS%\tomcat.zip"
if not exist "%TOMCAT%\bin\startup.bat" (
  if not exist "%TOOLS%" mkdir "%TOOLS%"
  echo Downloading Tomcat 10.1.60. Please wait...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest 'https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.60/bin/apache-tomcat-10.1.60.zip' -OutFile '%TOMCAT_ZIP%'"
  if errorlevel 1 goto :download_error
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%TOMCAT_ZIP%' -DestinationPath '%TOOLS%' -Force"
  if errorlevel 1 goto :download_error
  del /q "%TOMCAT_ZIP%" >nul 2>&1
)
echo Tomcat ready.
echo.
echo [4/5] Building TasteNest and preparing MySQL database...
if not exist "C:\xampp\mysql\bin\mysql.exe" (
  echo WARNING: XAMPP MySQL was not found at C:\xampp.
  echo Your MySQL must still be running on localhost:3306.
)
call "%MAVEN%\bin\mvn.cmd" -q clean package -DskipTests
if errorlevel 1 (
  echo.
  echo =====================================================
  echo BUILD FAILED
  echo =====================================================
  echo Keep this window open and send me a screenshot.
  pause
  exit /b 1
)
if exist "%TOMCAT%\webapps\tastenest.war" del /q "%TOMCAT%\webapps\tastenest.war"
if exist "%TOMCAT%\webapps\tastenest" rmdir /s /q "%TOMCAT%\webapps\tastenest"
copy /y "target\tastenest.war" "%TOMCAT%\webapps\tastenest.war" >nul

echo.
echo [5/5] Starting TasteNest...
set "CATALINA_HOME=%TOMCAT%"
set "CATALINA_BASE=%TOMCAT%"
set "JAVA_HOME=%JDK_HOME%"

REM Do not use catalina.bat here. Direct Bootstrap avoids CATALINA_HOME
REM validation problems on some Windows Java/Tomcat installations.
if not exist "%TOMCAT%\bin\bootstrap.jar" (
  echo ERROR: Tomcat bootstrap.jar was not found.
  pause
  exit /b 1
)

REM If TasteNest is already running on 8080, reuse it.
powershell -NoProfile -Command "$ok=$false; try{$c=New-Object Net.Sockets.TcpClient('127.0.0.1',8080);$ok=$true;$c.Close()}catch{}; if($ok){exit 0}else{exit 1}"
if not errorlevel 1 goto :server_ready

echo Starting Tomcat server...
start "TasteNest Tomcat" /b "%JAVA_HOME%\bin\java.exe" -Dcatalina.home="%TOMCAT%" -Dcatalina.base="%TOMCAT%" -Djava.util.logging.config.file="%TOMCAT%\conf\logging.properties" -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -cp "%TOMCAT%\bin\bootstrap.jar;%TOMCAT%\bin\tomcat-juli.jar" org.apache.catalina.startup.Bootstrap start

:wait_server
echo Waiting for Tomcat on port 8080...
set /a tries=0
:poll
set /a tries+=1
powershell -NoProfile -Command "$ok=$false; try{$c=New-Object Net.Sockets.TcpClient('127.0.0.1',8080);$ok=$true;$c.Close()}catch{}; if($ok){exit 0}else{exit 1}"
if not errorlevel 1 goto :server_ready
if !tries! GEQ 30 goto :tomcat_failed
timeout /t 1 /nobreak >nul
goto :poll

:tomcat_failed
echo.
echo =====================================================
echo TOMCAT COULD NOT START
 echo Check: %TOMCAT%\logs
 echo =====================================================
echo.
if exist "%TOMCAT%\logs\catalina*.log" dir /b /o-d "%TOMCAT%\logs\catalina*.log" | findstr /n "." | findstr "^[1-3]:" >nul
pause
exit /b 1

:server_ready
echo Tomcat is listening on port 8080.
echo Waiting for TasteNest application...
timeout /t 3 /nobreak >nul
powershell -NoProfile -Command "$ok=$false; try{$r=Invoke-WebRequest 'http://127.0.0.1:8080/tastenest/' -UseBasicParsing -TimeoutSec 5; if($r.StatusCode -ge 200 -and $r.StatusCode -lt 500){$ok=$true}}catch{}; if($ok){exit 0}else{exit 1}"
if errorlevel 1 (
  echo.
  echo =====================================================
  echo Tomcat started, but TasteNest did not respond yet.
  echo Open http://localhost:8080/tastenest/ after a few seconds.
  echo =====================================================
) else (
  start "" "http://localhost:8080/tastenest/"
)

echo.
echo =====================================================
echo TasteNest is running:
echo http://localhost:8080/tastenest/
echo.
echo Admin login:
echo Email: admin@tastenest.com
echo Password: admin123
echo =====================================================
echo Keep this window open while presenting.
echo.
pause
exit /b 0
:download_error
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%MAVEN_ZIP%' -DestinationPath '%TOOLS%' -Force"
  if errorlevel 1 goto :download_error
  del /q "%MAVEN_ZIP%" >nul 2>&1
)
echo Maven ready.
echo.
echo [3/5] Preparing Tomcat...
set "TOMCAT=%TOOLS%\apache-tomcat-10.1.60"
set "TOMCAT_ZIP=%TOOLS%\tomcat.zip"
if not exist "%TOMCAT%\bin\startup.bat" (
  if not exist "%TOOLS%" mkdir "%TOOLS%"
  echo Downloading Tomcat 10.1.60. Please wait...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest 'https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.60/bin/apache-tomcat-10.1.60.zip' -OutFile '%TOMCAT_ZIP%'"
  if errorlevel 1 goto :download_error
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%TOMCAT_ZIP%' -DestinationPath '%TOOLS%' -Force"
  if errorlevel 1 goto :download_error
  del /q "%TOMCAT_ZIP%" >nul 2>&1
)
echo Tomcat ready.
echo.
echo [4/5] Building TasteNest and preparing MySQL database...
if not exist "C:\xampp\mysql\bin\mysql.exe" (
  echo WARNING: XAMPP MySQL was not found at C:\xampp.
  echo Your MySQL must still be running on localhost:3306.
)
call "%MAVEN%\bin\mvn.cmd" -q clean package -DskipTests
if errorlevel 1 (
  echo.
  echo =====================================================
  echo BUILD FAILED
  echo =====================================================
  echo Keep this window open and send me a screenshot.
  pause
  exit /b 1
)
if exist "%TOMCAT%\webapps\tastenest.war" del /q "%TOMCAT%\webapps\tastenest.war"
if exist "%TOMCAT%\webapps\tastenest" rmdir /s /q "%TOMCAT%\webapps\tastenest"
copy /y "target\tastenest.war" "%TOMCAT%\webapps\tastenest.war" >nul

echo.
echo [5/5] Starting TasteNest...
set "CATALINA_HOME=%TOMCAT%"
set "CATALINA_BASE=%TOMCAT%"
set "JAVA_HOME=%JDK_HOME%"
call "%TOMCAT%\bin\catalina.bat" start
if errorlevel 1 (
  echo.
  echo TOMCAT COULD NOT START.
  echo Check the logs in: %TOMCAT%\logs
  pause
  exit /b 1
)
echo Waiting for TasteNest to start...
timeout /t 8 /nobreak >nul
start "" "http://localhost:8080/tastenest/"
echo.
echo =====================================================
echo TasteNest is running:
echo http://localhost:8080/tastenest/
echo.
echo Admin login:
echo Email: admin@tastenest.com
echo Password: admin123
echo =====================================================
echo Keep this window open while presenting.
echo.
pause
exit /b 0
:download_error
echo.
echo =====================================================
echo DOWNLOAD FAILED
 echo Please check internet connection and run this file again.
echo =====================================================
pause
exit /b 1
