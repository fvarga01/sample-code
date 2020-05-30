@echo off
echo This batch script demonstrates how to populate an
echo environment variable from a powershell script
echo This is usefull should you need to run PowerShell scripts from a batch file
echo and wish to dynamically read parameter values (from a configuration file for example)

cls
SET WORKINGDIR=%~dp0
pushd %WORKINGDIR%
echo Current directory is %WORKINGDIR%

echo STEPI:Retrieve environment variables from PowerShell Sctipt
set "PARAM1=powershell -File "util.ReadParam1ValueFromConfigFile.ps1" -ParamToExtract "PARAM1""
for /f "usebackq" %%x in (`%PARAM1%`) do set PARAM1=%%x
echo PARAM1 value is "%PARAM1%"
echo _______________________

echo STEP V: Remove line breaks from JSON file.
set CMDTORUN=powershell.exe -File pscript1.ps1 -PARAM1 "%PARAM1%"
echo _______________________
echo Command to run: %CMDTORUN%
%CMDTORUN%

popd %WORKINGDIR%
pause