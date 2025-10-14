# Multi-target .NET SDK Dockerfile (Windows with .NET Framework 4.8)
# escape=`
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2022

# Install .NET 9.0 SDK
RUN powershell -Command `
    Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile 'dotnet-install.ps1'; `
    .\dotnet-install.ps1 -Version 9.0.100 -InstallDir 'C:\Program Files\dotnet'

# Install .NET 8.0 SDK  
RUN powershell -Command `
    .\dotnet-install.ps1 -Version 8.0.404 -InstallDir 'C:\Program Files\dotnet'

# Install .NET Core 3.1 SDK
RUN powershell -Command `
    .\dotnet-install.ps1 -Version 3.1.426 -InstallDir 'C:\Program Files\dotnet'; `
    Remove-Item dotnet-install.ps1

# Add dotnet to PATH
RUN powershell -Command `
    $env:PATH = 'C:\Program Files\dotnet;' + $env:PATH; `
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)

# Verify installations
RUN dotnet --list-sdks

# Set working directory
WORKDIR C:\module