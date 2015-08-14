#!/bin/bash

####
# Default variables
####

# Script
INSTALL_SKEL_DIR=/home/biche/ispconfig-nginx_reverse_apache/.skel

NGINX_DEFAULT_LISTENING_PORT=80
NGINX_CONF_DIR=/etc/nginx
NGINX_CONF_FILE=/etc/nginx/nginx.conf
NGINX_AVAILABLE_VHOST_DIR=/etc/nginx/sites-available
NGINX_ENABLED_VHOST_DIR=/etc/nginx/sites-enabled
NGINX_LOGS_DIR=/var/log/nginx

APACHE_WWW_ROOT=/var/www

NGINX_VHOST_LOGS_DIR=$NGINX_LOGS_DIR/vhosttest
LOGS_SKEL_DIR=$NGINX_VHOST_LOGS_DIR/.skeltest
CONF_SKEL_DIR=$NGINX_CONF_DIR/.skeltest



####
# Functions definition
####

get_nginx_worker_user()
{
	read NGINX_WORKER_USER <<< $(grep 'user' $NGINX_CONF_FILE | awk 'BEGIN{FS="user ";} /user/ {print substr($2,0,length($2)-1)}')
	return 0
}
write_logs_skel()
{
	# Create the main directory if needed
	if [ ! -d "$NGINX_VHOST_LOGS_DIR" ]; then
		mkdir $NGINX_VHOST_LOGS_DIR
		# Set the right permissions
		chmod -R 640 $NGINX_VHOST_LOGS_DIR
		chown -R $NGINX_WORKER_USER $NGINX_VHOST_LOGS_DIR
	fi
	
	# Create the skeletons directory the skel files
	mkdir $LOGS_SKEL_DIR && touch $LOGS_SKEL_DIR/{access,error}.log

	return 0
}

write_conf_skel()
{
	# Create the skel directory
	mkdir $CONF_SKEL_DIR
	cp $INSTALL_SKEL_DIR/vhost.conf $CONF_SKEL_DIR/

	return 0
}

create_vhost_logs()
{
	# Create the vhost logs directory
	echo "Creating $NGINX_VHOST_LOGS_DIR/$VHOST_NAME"
	cp -afv $LOGS_SKEL_DIR $NGINX_VHOST_LOGS_DIR/$VHOST_NAME

	# Set right permissions
	chmod -R 640 $NGINX_VHOST_LOGS_DIR/$VHOST_NAME 
	
	# Links the logs to ISPConfig-built vhost log directory
	echo "Linking $NGINX_VHOST_LOGS_DIR/$VHOST_NAME/*.log to $APACHE_WWW_ROOT/$VHOST_NAME/log/nginx.*.log"
	ln -s $NGINX_VHOST_LOGS_DIR/$VHOST_NAME/access.log $APACHE_WWW_ROOT/$VHOST_NAME/log/nginx.access.log
	ln -s $NGINX_VHOST_LOGS_DIR/$VHOST_NAME/error.log $APACHE_WWW_ROOT/$VHOST_NAME/log/nginx.error.log
	
	return 0
}
create_vhost_conf()
{
	cp -Rf $CONF_SKEL_DIR/vhost.conf $NGINX_AVAILABLE_VHOST_DIR/$VHOST_NAME.conf
	sed -i "s/NGINX_VHOST_LISTEN_PORT/$VHOST_LISTEN_PORT/g" $NGINX_AVAILABLE_VHOST_DIR/$VHOST_NAME.conf
	sed -i "s/VHOST_NAME/$VHOST_NAME/g" $NGINX_AVAILABLE_VHOST_DIR/$VHOST_NAME.conf
	sed -i "s/VHOST_ALIAS/$VHOST_ALIAS/g" $NGINX_AVAILABLE_VHOST_DIR/$VHOST_NAME.conf
	sed -i "s=NGINX_VHOST_LOGS_DIR=$NGINX_VHOST_LOGS_DIR=g" $NGINX_AVAILABLE_VHOST_DIR/$VHOST_NAME.conf
	sed -i "s=APACHE_WWW_ROOT=$APACHE_WWW_ROOT=g" $NGINX_AVAILABLE_VHOST_DIR/$VHOST_NAME.conf
	sed -i "s/APACHE_VHOST_LISTEN_PORT/$APACHE_VHOST_LISTEN_PORT/g" $NGINX_AVAILABLE_VHOST_DIR/$VHOST_NAME.conf

	if [ $AUTO_WWW == "yes" ]; then
		sed -i "s/#AUTO_WWW?//g" $NGINX_AVAILABLE_VHOST_DIR/$VHOST_NAME.conf
		sed -i "s=VHOST_ESCAPED_NAME=$VHOST_ESCAPED_NAME=g" $NGINX_AVAILABLE_VHOST_DIR/$VHOST_NAME.conf
	fi
	return 0
}
####
# Script execution
####

set -e
# debug. remove
set -x

# DEVELOPMENT
# Remove this section !!
if [ -d /etc/nginx/.ske* ]; then
	rm -R /etc/nginx/.ske*;
fi
if [ -d /var/log/nginx/vhosttest ]; then
	rm -R /var/log/nginx/vhosttest;
fi
if [ -d /var/log/nginx/vhoststest ]; then
	rm -R /var/log/nginx/vhoststest;
fi
if [ -L /var/www/blog.webiche.info/log/nginx.access.log ]; then
	rm /var/www/blog.webiche.info/log/nginx.*;
fi
if [ -f /etc/nginx/sites-available/blog.webiche.info.conf ]; then
	rm /etc/nginx/sites-available/blog.webiche.info.conf
fi
if [ -L /etc/nginx/sites-enabled/blog.webiche.info.conf ]; then
	rm /etc/nginx/sites-enabled/blog.webiche.info.conf
fi

# Import Nginx config variables
NGINX_WORKER_USER= get_nginx_worker_user

# Skeletons check
if [ ! -d "$NGINX_VHOST_LOGS_DIR" ] || [ ! -d "$LOGS_SKEL_DIR" ]; then
	echo "Writing Vhost Logs Skeletons"
	# Write the logs skeleton directory
	write_logs_skel;
fi

if [ ! -d "$CONF_SKEL_DIR" ]; then
	echo "Writing Vhost Configuration Files Skeletons"
	# Write the vhost configuration file skeleton(s) directory
	write_conf_skel;
fi


echo "Nginx Vhost Generator for ISPConfig server with Apache/Nginx as Reverse Proxy"
echo "Creates Nginx vhost config and logs and links them to respect ISPConfig hierarchy"

# Get virtual host name from input
echo "What is the name of the Vhost that should be created?"
#read VHOST_NAME
VHOST_NAME=blog.webiche.info

# Split the virtual host name by dots to allow escaping in nginx configuration file
BIFS="$IFS"
IFS="."
VHOST_ARR=( $VHOST_NAME )
IFS="$BIFS"


# Escape each part of the url
VHOST_ESCAPED_NAME=""
for (( i = 0 ; i < ${#VHOST_ARR[@]} ; i++ )) do
	if [ $i == 0 ]; then
		SEP=""
	else
		SEP="\\\."
	fi
	VHOST_ESCAPED_NAME="$VHOST_ESCAPED_NAME$SEP${VHOST_ARR[$i]}"
done

#read VHOST_ALIAS
VHOST_ALIAS=*.blog.webiche.info

#read NGINX_VHOST_LISTEN_PORT
NGINX_VHOST_LISTEN_PORT=80

#read APACHE_VHOST_LISTEN_PORT
APACHE_VHOST_LISTEN_PORT=8080

echo "Should all the traffic be automatically redirected to www.$VHOST_NAME?"
#read AUTO_WWW
AUTO_WWW="yes"

echo "Searching for $APACHE_WWW_ROOT/$VHOST_NAME/web..."

# Try to find the directory, otherwise ask again and again for the right name
while : ; do
	[[ -d "$APACHE_WWW_ROOT/$VHOST_NAME/web" ]] && break
	echo "$APACHE_WWW_ROOT/$VHOST_NAME/web does not exist.Please type again your vhost name"
	read VHOST_NAME
done

OWNER=$(stat -c %U $APACHE_WWW_ROOT/$VHOST_NAME/web)
GROUP=$(stat -c %G $APACHE_WWW_ROOT/$VHOST_NAME/web)

echo "User is $OWNER, Group is $GROUP"


# Create & link Vhost logs
echo "Creating & linking vhost logs..."
create_vhost_logs

# Create Nginx configuration file 
echo "Creating skeleton based vhost configuration file with provided data..."
create_vhost_conf

# Link to Nginx Sites-Enabled dir
echo "Linking conf to sites-enabled directory"
ln -s $NGINX_AVAILABLE_VHOST_DIR/$VHOST_NAME.conf $NGINX_ENABLED_VHOST_DIR/$VHOST_NAME.conf

# Reload Apache2 & Nginx
echo "All done, reloading Apache2 & Nginx"

#service apache2 reload
#service nginx reload
