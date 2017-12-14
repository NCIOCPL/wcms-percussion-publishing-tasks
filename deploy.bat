@echo off
rem Get paths into variables
rem Batpath gets the path to this bat file.
set batpath=%~dp0

set my_sitename=%1
set my_subsite=%2
set my_percsitetype=%3

powershell -ExecutionPolicy RemoteSigned %batpath%deploy.ps1 -sitename %my_sitename% -subsite %my_subsite% -percsitetype %my_percsitetype% < nul