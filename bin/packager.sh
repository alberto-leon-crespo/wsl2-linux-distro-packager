#!/bin/bash

# Check dependencies
if ! command -v unsquashfs &> /dev/null; then
    echo "Error: unsquashfs is not installed. Install it using: sudo apt install squashfs-tools"
    exit 1
fi

if ! command -v wget &> /dev/null; then
    echo "Error: wget is not installed. Install it using: sudo apt install wget"
    exit 1
fi

# Default variables
OUTPUT_DIR="./wsl-distro"
TAR_NAME="wsl-distro.tar.gz"

# Ask user to choose between a local ISO or downloading one
echo "Do you want to use a local ISO or download one from a URL?"
echo "1) Use local ISO"
echo "2) Download from URL"
read -p "Select an option (1 or 2): " iso_choice

if [ "$iso_choice" == "1" ]; then
    read -p "Enter the path to the local ISO: " ISO_PATH
    if [ ! -f "$ISO_PATH" ]; then
        echo "Error: File not found at $ISO_PATH."
        exit 1
    fi
elif [ "$iso_choice" == "2" ]; then
    read -p "Enter the URL of the ISO: " ISO_URL
    ISO_PATH="$OUTPUT_DIR/distro.iso"
    mkdir -p "$OUTPUT_DIR"
    echo "Downloading the ISO..."
    wget -O "$ISO_PATH" "$ISO_URL"
else
    echo "Invalid option. Exiting."
    exit 1
fi

# Prepare directories
MOUNT_DIR="$OUTPUT_DIR/mount"
ROOTFS_DIR="$OUTPUT_DIR/rootfs"
mkdir -p "$MOUNT_DIR" "$ROOTFS_DIR"

# Mount the ISO
echo "Mounting the ISO..."
sudo mount -o loop "$ISO_PATH" "$MOUNT_DIR"

# Extract the root filesystem
echo "Extracting the root filesystem..."
sudo unsquashfs -f -d "$ROOTFS_DIR" "$MOUNT_DIR/casper/filesystem.squashfs"

# Unmount the ISO
echo "Unmounting the ISO..."
sudo umount "$MOUNT_DIR"

# Clean up the root filesystem
echo "Cleaning up the root filesystem..."
sudo rm -rf "$ROOTFS_DIR/var/cache/apt/archives/*"
sudo rm -rf "$ROOTFS_DIR/tmp/*"
sudo rm -rf "$ROOTFS_DIR/proc" "$ROOTFS_DIR/sys" "$ROOTFS_DIR/dev"

# Package into a .tar.gz file
echo "Packaging the root filesystem into $TAR_NAME..."
cd "$ROOTFS_DIR"
sudo tar --exclude='proc' --exclude='sys' --exclude='dev' --exclude='tmp' -czvf "../$TAR_NAME" .
cd -

# Final cleanup
sudo rm -rf "$MOUNT_DIR" "$ROOTFS_DIR"

# Ask if the user wants to import automatically into WSL
echo "The .tar.gz file is located at $OUTPUT_DIR/$TAR_NAME."
read -p "Do you want to automatically import this distribution into WSL2? (y/n): " import_choice

if [ "$import_choice" == "y" ]; then
    read -p "Enter a name for the distribution (e.g., LinuxMint): " distro_name
    read -p "Enter the destination path in Windows (e.g., C:\\WSL\\$distro_name): " windows_path
    wsl --import "$distro_name" "$windows_path" "$OUTPUT_DIR/$TAR_NAME" --version 2
    echo "Distribution successfully imported as $distro_name in WSL2!"
else
    echo "To import manually, use this command:"
    echo "wsl --import <Name> <Destination_Path> $OUTPUT_DIR/$TAR_NAME --version 2"
fi

echo "All done!"
