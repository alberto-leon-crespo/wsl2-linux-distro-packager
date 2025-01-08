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
MOUNT_DIR="/mnt/iso"
mkdir -p "$MOUNT_DIR"

# Mount the ISO
echo "Mounting the ISO..."
sudo mount -o loop "$ISO_PATH" "$MOUNT_DIR"

# Detect SquashFS or initrd
echo "Checking ISO structure..."
SQUASHFS_FILE=$(find "$MOUNT_DIR" -name "*.squashfs" | head -n 1)
INITRD_GZ_FILE=$(find "$MOUNT_DIR" -name "initrd*.gz" | head -n 1)
INITRD_IMG_FILE=$(find "$MOUNT_DIR" -name "initrd*.img" | head -n 1)

if [ -n "$SQUASHFS_FILE" ]; then
    echo "Detected SquashFS: $SQUASHFS_FILE"
    echo "Extracting SquashFS..."
    sudo unsquashfs -f -d "$OUTPUT_DIR" "$SQUASHFS_FILE"
elif [ -n "$INITRD_GZ_FILE" ]; then
    echo "Detected ISO Linux (initrd.gz): $INITRD_GZ_FILE"
    echo "Extracting initrd.gz..."
    # Copy and decompress initrd.gz
    cp "$INITRD_GZ_FILE" "$OUTPUT_DIR/initrd.gz"
    gunzip -f "$OUTPUT_DIR/initrd.gz"
    cd "$OUTPUT_DIR"
    cpio -idmv < initrd
    cd -
elif [ -n "$INITRD_IMG_FILE" ]; then
    echo "Detected ISO Linux (initrd.img): $INITRD_IMG_FILE"
    echo "Extracting initrd.img..."
    # Copy and extract initrd.img
    cp "$INITRD_IMG_FILE" "$OUTPUT_DIR/initrd.img"
    cd "$OUTPUT_DIR"
    cpio -idmv < initrd.img
    cd -
else
    echo "Error: Could not find SquashFS or initrd in the ISO."
    sudo umount "$MOUNT_DIR"
    exit 1
fi

echo "Deleting downloaded iso file..."
rm "$OUTPUT_DIR/distro.iso"

# Unmount the ISO
echo "Unmounting the ISO..."
sudo umount "$MOUNT_DIR"

# Package into a .tar.gz file
echo "Packaging the root filesystem into $TAR_NAME..."
cd "$OUTPUT_DIR"
sudo tar --exclude='proc' --exclude='sys' --exclude='dev' --exclude='tmp' -czvf "../$TAR_NAME" .
cd -

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
