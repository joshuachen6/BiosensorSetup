#!/zsh

# --- 1. PRE-FLIGHT & NAMING ---
echo "🚀 Starting Biosensors Lab macOS Setup..."
echo -n "Enter Machine Name (e.g., Mini-09, Studio-04): "
read MACHINE_NAME

# --- 2. INSTALL & ACTIVATE HOMEBREW ---
HOMEBREW_PREFIX="/opt/homebrew"
if [[ ! -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# CRITICAL: Load Homebrew into the current script session
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
echo "✅ Homebrew active: $(which brew)"

# --- 3. SYSTEM PREFERENCES ---
echo "⚙️ Configuring System Settings..."
sudo pmset -a displaysleep 180
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

# --- 4. INSTALL REQUIRED APPS ---
echo "📦 Installing Applications..."
# Explicitly using --cask for GUI apps
brew install --cask slack microsoft-teams notion tailscale visual-studio-code parsec realvnc-viewer

# Install Blip (Note: If this fails, download manually from blip.net)
brew install --cask blip || echo "⚠️ Blip cask not found, please install manually from blip.net"

# Install CLI Dependencies
brew install pyenv pyenv-virtualenv starship git xz libusb libomp ffmpeg@2.8 openssl@3 readline sqlite3 zlib tcl-tk ncurses

# --- 5. SHELL SETUP ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSHRC="$HOME/.zshrc"
grep -qxF 'eval "$(starship init zsh)"' "$ZSHRC" || echo 'eval "$(starship init zsh)"' >> "$ZSHRC"

# Add pyenv to .zshrc if missing
if ! grep -q "# pyenv" "$ZSHRC"; then
    cat >> "$ZSHRC" <<'EOF'
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
fi

# --- 6. PYTHON ENVIRONMENTS ---
echo "🐍 Setting up Python (This takes time)..."
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

pyenv install 3.14.2
pyenv install 3.10.19
pyenv virtualenv 3.14.2 MantisCam
pyenv virtualenv 3.10.19 MantisCamFLIR
pyenv global MantisCam

# --- 7. SSH & GITHUB PAUSE ---
ssh-keygen -t ed25519 -C "students@bsl-uiuc.com" -f ~/.ssh/id_ed25519 -N ""
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
echo "\n--- SSH KEY ---"
cat ~/.ssh/id_ed25519.pub
pbcopy < ~/.ssh/id_ed25519.pub
echo "----------------\n"
echo "⚠️  Action: Add key to GitHub and Authorize BioSensorsLab-Illinois SSO."
echo -n "Press [ENTER] to continue..."
read DISCARD

# --- 8. REPO CLONING ---
mkdir -p ~/BioSensorsLab && cd ~/BioSensorsLab
git clone git@github.com:BioSensorsLab-Illinois/MantisCamUnified.git
git clone git@github.com:BioSensorsLab-Illinois/bsl_scripts.git
git clone git@github.com:BioSensorsLab-Illinois/bsl_universal.git
cd bsl_universal && pip install .

echo "\n✅ Script Finished! Install NI-VISA and set fonts manually."
