# Nginx with Apache reverse proxy configuration generator

This script generates Nginx vhost configuration based on the parameters you pass to it.
The .vhost file is compatible with using Nginx as a reverse proxy with Apache. Feel free to adapt it to your needs.

It also creates a log directory with the name of your vhost in /var/log/nginx/vhosts/[vHostName], containing access and error log files.

This script was written two years ago and I didn't find enough time to rework it, so contributions are welcome.

# Requirements

ONLY TESTED ON DEBIAN/UBUNTU MACHINES

# Usage
The code is pretty straightforward (and sometimes usefuly commented). Read it first, then ask me if you need any help.

## ISPConfig Integration

The final goal of this script was to hook it to ISPConfig (with Apache), so ISPConfig could create/recreate Nginx configuration files even if Apache was configured as main Web server.

I'll do this if I find time to, but as I only use Nginx now, this might not be soon.
