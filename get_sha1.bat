@echo off
echo Looking for keytool...
echo.

REM Try common Java installation paths
set KEYTOOL_PATHS=^
"C:\Program Files\Java\jdk*\bin\keytool.exe" ^
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" ^
"C:\Program Files (x86)\Java\jdk*\bin\keytool.exe"

for %%p in (%KEYTOOL_PATHS%) do (
    for /f "delims=" %%f in ('dir /b /s %%p 2^>nul') do (
        echo Found keytool at: %%f
        echo.
        echo Getting SHA-1 fingerprint...
        echo.
        "%%f" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
        goto :end
    )
)

echo Keytool not found. Trying gradlew signingReport...
echo.
cd android
call gradlew.bat signingReport
cd ..

:end
pause
