
# WSL2 Distro Packager

This script, named `packager`, allows you to convert a Linux ISO into a WSL2-compatible distribution, package it into a `.tar.gz` file, and optionally import it into WSL2. With this, you can use custom Linux distributions on your Windows system seamlessly.

## **Requirements**

1. **Install WSL2**  
   Ensure that Windows Subsystem for Linux (WSL) is installed and updated to version 2. Follow the instructions in this article:  
   👉 [How to Install and Update WSL2](https://learn.microsoft.com/en-us/windows/wsl/install).

2. **Install Ubuntu from the Microsoft Store (recommended)**  
   - Installing Ubuntu via the Microsoft Store gives you a pre-configured Linux environment to run the script and access required tools.  
   - Search for "Ubuntu" in the Microsoft Store, install it, and set it up by creating a user account.

---

## **Script Overview**

The script provides:
- The ability to process a local ISO or download one from a URL.
- Automatic extraction of the Linux filesystem and packaging into a `.tar.gz` file.
- Optional automatic import into WSL2.
- Fixed output path: All results, including the `.tar.gz` file, are stored in the `./wsl-distro` directory.

---

## **Installation and Setup**

1. **Clone or Download the Script**  
   Open Ubuntu from the Microsoft Store and clone the repository:
   ```bash
   https://github.com/alberto-leon-crespo/wsl2-linux-distro-packager.git
   cd wsl2-linux-distro-packager/bin
   ```

2. **Ensure Required Tools Are Installed**  
   Install the necessary tools:
   ```bash
   sudo apt update
   sudo apt install squashfs-tools wget
   ```

3. **Run the Script**  
   Make the script executable and run it:
   ```bash
   chmod +x packager
   ./packager
   ```

---

## **Usage**

### **Option 1: Use a Local ISO**
- Select the option to use a local ISO.
- Enter the path to the ISO when prompted:
  ```plaintext
  Enter the path to the local ISO: /path/to/your/local.iso
  ```

### **Option 2: Download an ISO**
- Select the option to download an ISO.
- Provide the URL of the ISO:
  ```plaintext
  Enter the URL of the ISO: https://example.com/linuxmint.iso
  ```

### **Packaging and Import**
- The script automatically saves the output in the `./wsl-distro` directory as `wsl-distro.tar.gz`.
- You can choose to import it into WSL2 automatically:
  ```plaintext
  Do you want to automatically import this distribution into WSL2? (y/n): y
  Enter a name for the distribution (e.g., LinuxMint): LinuxMint
  ```

---

## **Manual Import**

If you choose not to import automatically, you can copy the `.tar.gz` file to your desktop or any Windows folder and import it manually using PowerShell:

1. **Copy the `.tar.gz` File:**
   ```bash
   cp ./wsl-distro/wsl-distro.tar.gz /mnt/c/Users/YourName/Desktop/
   ```

2. **Import the Distribution in PowerShell:**
   Open PowerShell and run:
   ```powershell
   wsl --import LinuxMint C:\WSL\LinuxMint C:\Users\YourName\Desktop\wsl-distro.tar.gz --version 2
   ```

---

## **Using the New Distribution**

Once the distribution is imported, simply restart your **Microsoft Terminal**. The new distribution will automatically appear in the dropdown menu. Select it, and you're ready to start using your custom Linux distro.

---

### Additional Steps

#### 1. **Removing Unnecessary Graphical Libraries**

To clean the system of unnecessary graphical libraries (since **WSLg** handles graphical applications), run the following commands:

1. **Remove graphical applications and desktop environments**:

    ```bash
    sudo apt-get purge libreoffice* gimp inkscape vlc gnome* cinnamon* mate* xfce* kde*
    sudo apt-get autoremove --purge
    ```

2. **Remove graphical libraries** (optional):

   If you want to be more aggressive in removing unnecessary libraries like **GTK** or **Qt**:

    ```bash
    sudo apt-get purge libgtk-3-0 libqt5core5a libqt5gui5
    sudo apt-get autoremove
    ```

#### 2. **Keeping the System Time Updated in WSL2**

To ensure that your system time remains accurate in **WSL2**, you can use the following method to synchronize the time with **Windows**:

1. **Create a synchronization script**:

    ```bash
    nano ~/sync_time.sh
    ```

   Add the following content:

    ```bash
    #!/bin/bash
    sudo hwclock -s
    ```

2. **Make the script executable**:

    ```bash
    chmod +x ~/sync_time.sh
    ```

3. **Set up a cron job to run the script periodically**:

    ```bash
    crontab -e
    ```

   Add this line to run the script every 5 minutes:

    ```bash
    */5 * * * * /home/your_username/sync_time.sh
    ```

This will ensure your time is synchronized regularly.

---

## **Contribute**

If you encounter any issues or want to suggest improvements, feel free to open an issue or submit a pull request.

---

Enjoy using your custom Linux distribution in WSL2! 🚀✨
