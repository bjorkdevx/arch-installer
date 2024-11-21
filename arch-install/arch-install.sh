#!/bin/bash

# Set disk to partition
DISK="/dev/nvme0n1"

# Make sure we are running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root." 
  exit 1
fi

# Destroy existing partitions (Be very careful, this will erase all data on the disk)
echo -e "o\nw" | fdisk $DISK  # Create a new empty partition table (GPT)

# Create partitions
echo -e "n\np\n1\n\n+100M\nw" | fdisk $DISK  # /boot/efi partition (100 MB)
echo -e "n\np\n2\n\n+16G\nw" | fdisk $DISK  # Swap partition (16 GB)
echo -e "n\np\n3\n\n\nw" | fdisk $DISK  # Root partition (remaining space)

# Refresh partition table
partprobe $DISK

# Format partitions
mkfs.fat -F32 ${DISK}p1    # Format /boot/efi partition as FAT32
mkswap ${DISK}p2           # Set up swap partition
mkfs.ext4 ${DISK}p3        # Format root partition as ext4

# Enable swap
swapon ${DISK}p2

# Mount partitions
mkdir -p /mnt
mount ${DISK}p3 /mnt
mkdir -p /mnt/boot
mount ${DISK}p1 /mnt/boot

echo "Partitioning complete!"

# Installing base system 
echo "Installing base system..."
sleep 3

pacstrap -K /mnt base linux-lts linux-firmware amd-ucode networkmanager nano sof-firmware grub man-db base-devel efibootmgr vim

# Generating fstab (filesystem table)
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab


echo "Base installation complete! Please continue with chroot setup."sleep 3

#Chroot
arch-chroot /mnt

#Set the time zone
ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime

#Run hwclock(8) to generate /etc/adjtime: 
hwclock --systohc

# Generate locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf


# Set up hostname
echo "myhostname" > /etc/hostname

echo ""

# Set up root password
passwd

#set up user whid sudo privlige
useradd -m -G wheel -s /bin/bash username

#Set passworld for user
echo "Set passworld for user"
passwd username

# Allow wheel group to use sudo (ensure the correct sudoers configuration)
echo "Enabling sudo for the wheel group..."
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

echo "Sudoers file updated. The wheel group can now use sudo."
sleep 3

#Start NetworkManger
systemctl enable --now NetworkManager

#Install grub
grub-install /dev/nvme0n1

sleep 2

grub-mkconfig -o /boot/grub/grub.cfg

sleep 2

#Update the system
pacman -Syu

sleep 2

#Install program whid pacman
pacman -S gcc make git ripgrep fd unzip neovim xorg-server xorg-xini xorg-xsetroot 

git clone (my dwm syuff) > /home/username

echo "Installation complete! You can now exit chroot and reboot."
