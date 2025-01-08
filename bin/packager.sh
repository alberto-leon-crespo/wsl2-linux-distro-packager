#!/bin/bash

# Verificar dependencias
if ! command -v unsquashfs &> /dev/null; then
    echo "Error: unsquashfs no está instalado. Instálalo con: sudo apt install squashfs-tools"
    exit 1
fi

if ! command -v wget &> /dev/null; then
    echo "Error: wget no está instalado. Instálalo con: sudo apt install wget"
    exit 1
fi

# Variables iniciales
OUTPUT_DIR="./wsl-distro"
TAR_NAME="wsl-distro.tar.gz"

# Preguntar al usuario si quiere usar una ISO local o descargarla
echo "¿Quieres usar una ISO local o descargarla desde una URL?"
echo "1) Usar ISO local"
echo "2) Descargar desde URL"
read -p "Selecciona una opción (1 o 2): " iso_choice

if [ "$iso_choice" == "1" ]; then
    read -p "Introduce la ruta a la ISO local: " ISO_PATH
    if [ ! -f "$ISO_PATH" ]; then
        echo "Error: No se encontró el archivo en $ISO_PATH."
        exit 1
    fi
elif [ "$iso_choice" == "2" ]; then
    read -p "Introduce la URL de la ISO: " ISO_URL
    ISO_PATH="$OUTPUT_DIR/distro.iso"
    mkdir -p "$OUTPUT_DIR"
    echo "Descargando la ISO..."
    wget -O "$ISO_PATH" "$ISO_URL"
else
    echo "Opción inválida. Saliendo."
    exit 1
fi

# Preparar directorios
MOUNT_DIR="$OUTPUT_DIR/mount"
ROOTFS_DIR="$OUTPUT_DIR/rootfs"
mkdir -p "$MOUNT_DIR" "$ROOTFS_DIR"

# Montar la ISO
echo "Montando la ISO..."
sudo mount -o loop "$ISO_PATH" "$MOUNT_DIR"

# Extraer el sistema raíz
echo "Extrayendo el sistema raíz..."
sudo unsquashfs -f -d "$ROOTFS_DIR" "$MOUNT_DIR/casper/filesystem.squashfs"

# Desmontar la ISO
echo "Desmontando la ISO..."
sudo umount "$MOUNT_DIR"

# Limpiar el sistema raíz
echo "Limpiando el sistema raíz..."
sudo rm -rf "$ROOTFS_DIR/var/cache/apt/archives/*"
sudo rm -rf "$ROOTFS_DIR/tmp/*"
sudo rm -rf "$ROOTFS_DIR/proc" "$ROOTFS_DIR/sys" "$ROOTFS_DIR/dev"

# Empaquetar en .tar.gz
echo "Empaquetando el sistema raíz en $TAR_NAME..."
cd "$ROOTFS_DIR"
sudo tar --exclude='proc' --exclude='sys' --exclude='dev' --exclude='tmp' -czvf "../$TAR_NAME" .
cd -

# Limpieza final
sudo rm -rf "$MOUNT_DIR" "$ROOTFS_DIR"

# Preguntar si importar automáticamente en WSL
echo "El archivo .tar.gz está en $OUTPUT_DIR/$TAR_NAME."
read -p "¿Quieres importar automáticamente esta distribución en WSL2? (y/n): " import_choice

if [ "$import_choice" == "y" ]; then
    read -p "Introduce el nombre para la distribución (ej. LinuxMint): " distro_name
    read -p "Introduce la ruta de destino en Windows (ej. C:\\WSL\\$distro_name): " windows_path
    wsl --import "$distro_name" "$windows_path" "$OUTPUT_DIR/$TAR_NAME" --version 2
    echo "¡Distribución importada exitosamente como $distro_name en WSL2!"
else
    echo "Para importar manualmente, usa este comando:"
    echo "wsl --import <Nombre> <Ruta_Destino> $OUTPUT_DIR/$TAR_NAME --version 2"
fi

echo "¡Todo listo!"
