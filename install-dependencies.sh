#!/usr/bin/env bash
set -euo pipefail

# ANSI color codes for verbose reporting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$EUID" -eq 0 ] && [ "${MACHINE:-}" != "UNKNOWN" ]; then
    echo -e "${RED}Do not run this script as root (via sudo). Run as a standard user; the script will prompt for sudo when required.${NC}"
    exit 1
fi

cleanup() {
    echo ""
    echo -e "${RED}════════════════════════════════════════════════${NC}"
    echo -e "${RED} [!] Installation interrupted or failed${NC}"
    echo -e "${RED}════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Your environment might be partially set up. Please address any errors above and re-run this script to finish installation.${NC}"
    exit 1
}

trap cleanup SIGINT SIGTERM ERR

clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${YELLOW} Project Dependency Installer${NC}"
echo -e "${BLUE}====================================================${NC}"
echo ""
echo "This script will install all required dependencies to work with the defined stack:"
echo "  1. Git          (Version control manager)"
echo "  2. Docker       (Container orchestration for Laravel Sail backend)"
echo "  3. Node.js      (via NVM, installing v22 LTS for Nuxt 4 frontend)"
echo "  4. PHP 8.4      (Local parsing engine for Composer)"
echo "  5. Composer     (PHP Package Manager)"
echo ""
echo "Total steps: 5"
echo ""

# Identify OS and check for Windows Native
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*) MACHINE=Windows;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

if [ "$MACHINE" = "Windows" ]; then
    echo -e "${RED}====================================================${NC}"
    echo -e "${RED}             WINDOWS NATIVE DETECTED                ${NC}"
    echo -e "${RED}====================================================${NC}"
    echo "Installing this stack locally directly on Windows is unsupported."
    echo "This project's environment strictly requires WSL2 (Windows Subsystem for Linux)."
    echo ""
    echo -e "${GREEN}To install WSL2, open an Administrator PowerShell and run:${NC}"
    echo "    wsl --install"
    echo ""
    echo "After installation completes, reboot your computer, launch your new 'Ubuntu' terminal,"
    echo "and re-run this install-dependencies script from within WSL2."
    echo ""
    exit 1
fi

echo -e "${YELLOW}Host detected as: ${MACHINE}${NC}"

read -p "Continue with installation? [Y/n] " -n 1 -r
echo ""
if [[ ! ${REPLY:-} =~ ^[Yy]$ ]] && [[ ! -z ${REPLY:-} ]]; then
    echo -e "${RED}Installation aborted by user.${NC}"
    trap - SIGINT SIGTERM ERR
    exit 1
fi

echo ""

# ---------------------------------------------------------
# Step 1: Git
# ---------------------------------------------------------
echo -e "${BLUE}[1/5] => Checking Git...${NC}"
if command -v git >/dev/null 2>&1; then
    echo -e "${GREEN}[✓] Git is already installed. Skipping.${NC}"
else
    echo "=> Installing Git..."
    if [ "$MACHINE" = "Mac" ]; then
        if ! command -v brew >/dev/null 2>&1; then
            echo -e "${YELLOW}Homebrew missing. Installing Homebrew first...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install git
    elif [ "$MACHINE" = "Linux" ]; then
        sudo apt-get update
        sudo apt-get install -y git
    fi
    echo -e "${GREEN}[✓] Git installed successfully.${NC}"
fi

# ---------------------------------------------------------
# Step 2: Docker
# ---------------------------------------------------------
echo ""
echo -e "${BLUE}[2/5] => Checking Docker...${NC}"
if command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}[✓] Docker is already installed. Skipping.${NC}"
else
    echo "=> Installing Docker Engine..."
    if [ "$MACHINE" = "Mac" ]; then
        if ! command -v brew >/dev/null 2>&1; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install --cask docker
    elif [ "$MACHINE" = "Linux" ]; then
        sudo apt-get update
        sudo apt-get install -y curl ca-certificates software-properties-common
        sudo apt-get install -y docker.io docker-compose-plugin
        
        # Add to docker group safely for passwordless execution
        if ! getent group docker > /dev/null; then
            sudo groupadd docker
        fi
        if ! id -nG "$USER" | grep -qw "docker"; then
            sudo usermod -aG docker "$USER"
            echo -e "${YELLOW}[!] You have been added to the 'docker' group."
            echo -e "    You may need to logout and log back in for docker commands to work without sudo.${NC}"
        fi
    fi
    echo -e "${GREEN}[✓] Docker installed successfully.${NC}"
fi

# ---------------------------------------------------------
# Step 3: NVM and Node 22
# ---------------------------------------------------------
echo ""
echo -e "${BLUE}[3/5] => Checking Node.js (via NVM)...${NC}"
export NVM_DIR="$HOME/.nvm"
# Load NVM if it exists
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v node >/dev/null 2>&1 && node -v | grep -q 'v22'; then
   echo -e "${GREEN}[✓] Node.js v22 is already installed. Skipping.${NC}"
else
   echo "=> Installing NVM & Node.js v22 LTS..."
   if [ ! -s "$NVM_DIR/nvm.sh" ]; then
       echo "   => Fetching NVM..."
       curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
       [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
   fi
   
   nvm install 22
   nvm use 22
   nvm alias default 22
   echo -e "${GREEN}[✓] Node.js v22 installed successfully.${NC}"
fi

# ---------------------------------------------------------
# Step 4: PHP 8.4
# ---------------------------------------------------------
echo ""
echo -e "${BLUE}[4/5] => Checking PHP 8.4...${NC}"
if command -v php >/dev/null 2>&1 && php -v | grep -q 'PHP 8.4'; then
   echo -e "${GREEN}[✓] PHP 8.4 is already installed. Skipping.${NC}"
else
   echo "=> Installing PHP 8.4 globally..."
   if [ "$MACHINE" = "Mac" ]; then
      if ! command -v brew >/dev/null 2>&1; then
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew install php@8.4
      brew link --overwrite --force php@8.4
   elif [ "$MACHINE" = "Linux" ]; then
      sudo apt-get update
      sudo apt-get install -y software-properties-common
      # Ensure PPA is available for bleeding edge PHP versions
      if ! sudo add-apt-repository -y ppa:ondrej/php; then
          echo -e "${YELLOW}Warning: adding PPA failed, trying standard apt.${NC}"
      fi
      sudo apt-get update
      if ! sudo apt-get install -y php8.4-cli php8.4-xml php8.4-curl php8.4-mbstring php8.4-zip; then
          echo -e "${RED}Failed to install PHP 8.4 automatically. Please check your package manager.${NC}"
          exit 1
      fi
   fi
   echo -e "${GREEN}[✓] PHP 8.4 installation sequence complete.${NC}"
fi

# ---------------------------------------------------------
# Step 5: Composer
# ---------------------------------------------------------
echo ""
echo -e "${BLUE}[5/5] => Checking Composer...${NC}"
if command -v composer >/dev/null 2>&1; then
   echo -e "${GREEN}[✓] Composer is already installed. Skipping.${NC}"
else
   echo "=> Installing Composer..."
   if [ "$MACHINE" = "Mac" ]; then
      brew install composer
   elif [ "$MACHINE" = "Linux" ]; then
      EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
      php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
      ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

      if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
          echo -e "${RED}ERROR: Invalid Composer installer checksum${NC}"
          rm composer-setup.php
          exit 1
      fi

      php composer-setup.php --quiet || { rm composer-setup.php; exit 1; }
      rm composer-setup.php
      sudo mv composer.phar /usr/local/bin/composer
   fi
   echo -e "${GREEN}[✓] Composer installed successfully.${NC}"
fi

# ---------------------------------------------------------
# Verification Step
# ---------------------------------------------------------
trap - SIGINT SIGTERM ERR

echo ""
echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN} Installation Complete!${NC}"
echo -e "${BLUE}====================================================${NC}"
echo "You can verify your environment with the following commands:"
echo "  - docker --version"
echo "  - node -v"
echo "  - php -v"
echo "  - composer -V"
echo ""
echo -e "${YELLOW}Note: If you were just added to the Docker group, you must logout and log back in (or run 'newgrp docker') for changes to apply.${NC}"
echo -e "${YELLOW}Note: You MUST restart your terminal or run 'source ~/.bashrc' before node and composer commands will work in your current session.${NC}"
echo ""
