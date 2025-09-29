FROM mcr.microsoft.com/dotnet/sdk:9.0

# Install Mono for .NET Framework 4.8 compatibility
RUN apt-get update && \
    apt-get install -y gnupg ca-certificates curl && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/debian stable-buster main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
    apt-get update && \
    apt-get install -y mono-devel && \
    apt-get clean

# Install .NET runtimes using dotnet-install script with insecure flag temporarily
RUN curl -sSL -k https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel 8.0 --runtime dotnet --install-dir /usr/share/dotnet --no-path && \
    /tmp/dotnet-install.sh --channel 3.1 --runtime dotnet --install-dir /usr/share/dotnet --no-path && \
    rm /tmp/dotnet-install.sh

# Verify installations
RUN dotnet --list-sdks && \
    dotnet --list-runtimes

# Set working directory
WORKDIR /module