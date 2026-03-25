#!/bin/zsh

# --- 1. PRE-FLIGHT ---
echo "🚀 Starting Biosensors Lab Setup ..."
# Strict naming convention check
read -p "Enter Machine Name (e.g., Mini-09): " MACHINE_NAME
ACCOUNT_NAME=$(echo "$MACHINE_NAME" | tr '[:upper:]' '[:lower:]')

# --- 2. INSTALL HOMEBREW ---
if ! command -v brew &> /dev/null; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to path for the current session
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- 3. SYSTEM PREFERENCES ---
echo "⚙️ Configuring System Settings..."
# Lock Screen: Turn display off when inactive -> 3 hours (10800 seconds)
sudo pmset -a displaysleep 180
# Appearance: Dark Mode
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

# --- 4. CORE SOFTWARE ---
echo "📦 Installing Apps via Brew..."
apps=(
    slack microsoft-teams notion tailscale 
    visual-studio-code parsec realvnc-viewer
)
brew install --cask "${apps[@]}"

# Required dependencies for Python and Starship
brew install pyenv pyenv-virtualenv starship git xz libusb libomp openssl@3 readline sqlite3 zlib tcl-tk ncurses

# --- 5. OH-MY-ZSH & STARSHIP ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Cleanly add configs to .zshrc if not already present
ZSHRC="$HOME/.zshrc"
grep -qxF 'eval "$(starship init zsh)"' "$ZSHRC" || echo 'eval "$(starship init zsh)"' >> "$ZSHRC"

# Pyenv Configuration
if ! grep -q "# pyenv" "$ZSHRC"; then
    cat >> "$ZSHRC" <<'EOF'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
fi

# --- 6. PYTHON VERSIONS & ENVIRONMENTS ---
echo "🐍 Setting up Python environments..."
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

pyenv install 3.14.2
pyenv install 3.10.19
pyenv virtualenv 3.14.2 MantisCam
pyenv virtualenv 3.10.19 MantisCamFLIR
pyenv global MantisCam

# --- 7. REPOS & GITHUB ---
echo "🔑 Setting up SSH for GitHub..."
# Note: This will prompt for user input unless Enter is pressed 3x manually
ssh-keygen -t ed25519 -C "students@bsl-uiuc.com" -f ~/.ssh/id_ed25519 -N ""
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub

echo "📂 Cloning Repositories..."
mkdir -p ~/BioSensorsLab && cd ~/BioSensorsLab
git clone git@github.com:BioSensorsLab-Illinois/MantisCamUnified.git
git clone git@github.com:BioSensorsLab-Illinois/bsl_scripts.git
git clone git@github.com:BioSensorsLab-Illinois/bsl_universal.git

# Install bsl_universal
cd bsl_universal && pip install .

echo "🏁 Setup Finished. Don't forget to manually install the NI-VISA driver."
