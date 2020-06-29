#!/bin/bash
# Install dependencies
sudo dnf -y install https://rpmfind.net/linux/opensuse/distribution/leap/15.2/repo/oss/x86_64/libjpeg8-8.1.2-lp152.7.3.x86_64.rpm double-conversion.x86_64

# Configure links for libs
sudo ln -s /lib64/libicui18n.so.65.1 /lib64/libicui18n.so.60
sudo ln -s /lib64/libicuuc.so.65.1 /lib64/libicuuc.so.60
sudo ln -s /lib64/libdouble-conversion.so.3.1.5 /lib64/libdouble-conversion.so.1

# Extract from offical package
ar -x PacketTracer_730_amd64.deb data.tar.xz
tar -xvf data.tar.xz

# Taken from the official package
remove_pt ()
{
if [ -e /opt/pt ]; then
  echo "Removing old version of Packet Tracer from /opt/pt"
  sudo rm -rf /opt/pt
  sudo rm -rf /usr/share/applications/cisco-pt7.desktop
  sudo rm -rf /usr/share/applications/cisco-ptsa7.desktop
  sudo rm -rf /usr/share/icons/hicolor/48x48/apps/pt7.png
fi
}

sudo xdg-desktop-menu uninstall /usr/share/applications/cisco-pt7.desktop
sudo xdg-desktop-menu uninstall /usr/share/applications/cisco-ptsa7.desktop
sudo update-mime-database /usr/share/mime
sudo gtk-update-icon-cache --force /usr/share/icons/gnome

sudo rm -f /usr/local/bin/packettracer

# check /etc/profile for existance of PT7HOME
PROFILE="/etc/profile" 

# error exit if file does not exist or unreadable
if [ ! -f $PROFILE ]; then
   exit 0
elif [ ! -r $PROFILE ]; then
   exit 0
fi

# read contents
exec 3<&0
exec 0<$PROFILE
while IFS= read -r line
do
  PT7HOME_FOUND=`expr match "$line" 'PT7HOME'`
  if [ $PT7HOME_FOUND -gt 0 ]; then
	continue
  fi

  QT_FOUND=`expr match "$line" 'QT_DEVICE_PIXEL_RATIO'`
  if [ $QT_FOUND -gt 0 ]; then
	continue
  fi

  EXPORT_FOUND=`expr match "$line" 'export PT7HOME'`
  if [ $EXPORT_FOUND -gt 0 ]; then
	continue
  fi

  EXPORT_QT_FOUND=`expr match "$line" 'export QT_DEVICE_PIXEL_RATIO'`
  if [ $EXPORT_QT_FOUND -gt 0 ]; then
	continue
  fi

  CONTENTS="$CONTENTS\n$line"
done
exec 0<&3

# My append
sudo cp -r opt/* /opt
sudo cp -r usr/* /usr
cd /opt/pt

# Taken from the official package
sudo echo -e "$CONTENTS" > /etc/profile

# update icon and file assocation
sudo xdg-desktop-menu install /usr/share/applications/cisco-pt7.desktop
sudo xdg-desktop-menu install /usr/share/applications/cisco-ptsa7.desktop
sudo update-mime-database /usr/share/mime
sudo gtk-update-icon-cache --force /usr/share/icons/gnome

# sets the incoming PTDIR as a system environment variable
# sets the Qt high resolution as a system environment variable
# by modifying /etc/profile 
PTDIR="/opt/pt"

# create shortcut
sudo ln -sf $PTDIR/packettracer /usr/local/bin/packettracer


# check /etc/profile for existance of PT7HOME
PROFILE="/etc/profile" 

# error exit if file does not exist or unreadable
if [ ! -f $PROFILE ]; then
   exit 1
elif [ ! -r $PROFILE ]; then
   exit 2
fi

# read contents
CONTENTS=""
EXPORT_EXISTS=0
PT7HOME_EXISTS=0
PT7HOME_FOUND=0
EXPORT_QT_EXISTS=0
QT_EXISTS=0
QT_FOUND=0
exec 3<&0
exec 0<$PROFILE
while IFS= read -r line
do
  
  # replace existing entries
  PT7HOME_FOUND=`expr match "$line" 'PT7HOME'`
  if [ $PT7HOME_FOUND -gt 0 ]; then
	line="PT7HOME=$PTDIR"
        PT7HOME_EXISTS=1
  fi

  QT_FOUND=`expr match "$line" 'QT_DEVICE_PIXEL_RATIO'`
  if [ $QT_FOUND -gt 0 ]; then
	line="QT_DEVICE_PIXEL_RATIO=auto"
        QT_EXISTS=1
  fi

  # check for export statement
  if [ $EXPORT_EXISTS -eq 0 ]; then
      EXPORT_EXISTS=`expr match "$line" 'export PT7HOME'`
  fi

  if [ $EXPORT_QT_EXISTS -eq 0 ]; then
      EXPORT_QT_EXISTS=`expr match "$line" 'export QT_DEVICE_PIXEL_RATIO'`
  fi

  #append the line to the contents
  CONTENTS="$CONTENTS\n$line"
done
exec 0<&3

if [ $PT7HOME_EXISTS -eq 0 ]; then
  CONTENTS="$CONTENTS\nPT7HOME=$PTDIR"
fi

if [ $EXPORT_EXISTS -eq 0 ]; then
  CONTENTS="$CONTENTS\nexport PT7HOME"
fi

if [ $QT_EXISTS -eq 0 ]; then
  CONTENTS="$CONTENTS\nQT_DEVICE_PIXEL_RATIO=auto"
fi

if [ $EXPORT_EXISTS -eq 0 ]; then
  CONTENTS="$CONTENTS\nexport QT_DEVICE_PIXEL_RATIO"
fi

sudo echo -e "$CONTENTS" > /etc/profile

exit 0
