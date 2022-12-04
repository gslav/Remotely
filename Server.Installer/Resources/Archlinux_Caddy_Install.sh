#!/bin/bash
echo "Thanks for trying Remotely!"
echo

Args=( "$@" )
ArgLength=${#Args[@]}

for (( i=0; i<${ArgLength}; i+=2 ));
do
    if [ "${Args[$i]}" = "--host" ]; then
        HostName="${Args[$i+1]}"
    elif [ "${Args[$i]}" = "--approot" ]; then
        AppRoot="${Args[$i+1]}"
    fi
done

if [ -z "$AppRoot" ]; then
    read -p "Enter path where the Remotely server files should be installed (typically /var/www/remotely): " AppRoot
    if [ -z "$AppRoot" ]; then
        AppRoot="/var/www/remotely"
    fi
fi

if [ -z "$HostName" ]; then
    read -p "Enter server host (e.g. remotely.yourdomainname.com): " HostName
fi

chmod +x "$AppRoot/Remotely_Server"

echo "Using $AppRoot as the Remotely website's content directory."

# Install .NET Core Runtime.
pacman -Sy dotnet-runtime dotnet-host

# Install other prerequisites.
pacman -Sy unzip acl glibc libgdiplus

# Install Caddy
pacman -Sy caddy

# Configure Caddy
caddyConfig="
$HostName {
    reverse_proxy 127.0.0.1:5000
}
"

echo "$caddyConfig" >> /etc/caddy/conf.d/Caddyfile

# Create Remotely service.

serviceConfig="[Unit]
Description=Remotely Server

[Service]
WorkingDirectory=$AppRoot
ExecStart=/usr/bin/dotnet $AppRoot/Remotely_Server.dll
Restart=always
# Restart service after 10 seconds if the dotnet service crashes:
RestartSec=10
SyslogIdentifier=remotely
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target"

echo "$serviceConfig" > /etc/systemd/system/remotely.service


# Enable service.
systemctl enable remotely.service
# Start service.
systemctl start remotely.service


# Start caddy
systemctl start caddy
# Reload caddy to update config
systemctl reload caddy
