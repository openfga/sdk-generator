FROM mcr.microsoft.com/dotnet/sdk:6.0

# Install make and other basic tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        make \
        apt-transport-https \
        dirmngr \
        gnupg \
        ca-certificates \
        nuget \
    && rm -rf /var/lib/apt/lists/*

# Install Mono (needed for testing .NET Framework 4.8)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        mono-complete \
    && rm -rf /var/lib/apt/lists/*

# Install xUnit console runner for Mono
# Using a specific version that works with older NuGet client
RUN nuget install xunit.runner.console -Version 2.1.0 -OutputDirectory /xunit

# Install .NET Core 3.1 Runtime (needed for testing .NET Core 3.1)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
    && wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y apt-transport-https \
    && apt-get update \
    && apt-get install -y dotnet-sdk-3.1 \
    && rm -rf /var/lib/apt/lists/*

# Verify installations
RUN dotnet --list-sdks