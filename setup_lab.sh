#!/bin/zsh

# --- 1. PRE-FLIGHT & NAMING ---
echo "🚀 Starting Biosensors Lab macOS Setup..."
# Check sticker for machine number (xx)
read -p "Enter Machine Name (e.g., Mini-09, Studio-04, MBP-01): " MACHINE_NAME
ACCOUNT_NAME=$(echo "$MACHINE_NAME" | tr '[:upper:]' '[:lower:]')

# --- 2. INSTALL HOMEBREW ---
if ! command -v brew &> /dev/null; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew already installed."
fi

# --- 3. SYSTEM PREFERENCES (Defaults) ---
echo "⚙️ Configuring System Settings..."
# Set display sleep to 3 hours (10800 seconds)
sudo pmset -a displaysleep 180
# Appearance: Dark Mode
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

# --- 4. INSTALL SOFTWARE VIA BREW ---
echo "📦 Installing Applications and Dependencies..."
apps=(
    slack microsoft-teams notion tailscale 
    visual-studio-code parsec realvnc-viewer
)
brew install --cask "${apps[@]}"

# Required system libraries for Python and Starship
brew install pyenv pyenv-virtualenv starship git xz libusb libomp ffmpeg@2.8 openssl@3 readline sqlite3 zlib tcl-tk ncurses

# --- 5. SHELL SETUP (Oh-My-Zsh & Starship) ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Configure .zshrc
ZSHRC="$HOME/.zshrc"
grep -qxF 'eval "$(starship init zsh)"' "$ZSHRC" || echo 'eval "$(starship init zsh)"' >> "$ZSHRC"

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
echo "🐍 Installing Python Versions (This will take a few minutes)..."
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

pyenv install 3.14.2
pyenv install 3.10.19
pyenv virtualenv 3.14.2 MantisCam
pyenv virtualenv 3.10.19 MantisCamFLIR
pyenv global MantisCam

# --- 7. SSH KEY GENERATION & GITHUB PAUSE ---
echo "🔑 Generating SSH Key..."
ssh-keygen -t ed25519 -C "students@bsl-uiuc.com" -f ~/.ssh/id_ed25519 -N ""
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

echo "\n--- YOUR PUBLIC SSH KEY ---"
cat ~/.ssh/id_ed25519.pub
echo "---------------------------\n"

# Copy to clipboard for easy pasting
pbcopy < ~/.ssh/id_ed25519.pub

echo "⚠️  ACTION REQUIRED:"
echo "1. The key above has been copied to your clipboard."
echo "2. Go to GitHub -> Settings -> SSH Keys."
echo "3. Add a new key named '$MACHINE_NAME'."
echo "4. IMPORTANT: Authorize 'BioSensorsLab-Illinois' SSO."
echo ""
read -k 1 "?Press any key to continue cloning repositories once authorized..."
echo "\n"

# --- 8. REPO CLONING ---
echo "📂 Cloning Repositories into ~/BioSensorsLab..."
mkdir -p ~/BioSensorsLab && cd ~/BioSensorsLab
git clone git@github.com:BioSensorsLab-Illinois/MantisCamUnified.git
git clone git@github.com:BioSensorsLab-Illinois/bsl_scripts.git
git clone git@github.com:BioSensorsLab-Illinois/bsl_universal.git

# Install local library
cd bsl_universal && pip install .

# --- 9. FINAL REMINDERS ---
echo "\n✅ Scripted setup complete!"
echo "🛠️  FINAL MANUAL STEPS:"
echo "1. Download & Install NI-VISA Driver (Allow in Privacy & Security)."
echo "2. Set Terminal Font to '0xProto Nerd Font Mono', size 16."
echo "3. Sign into Apple ID, Slack, Teams, Notion, and Tailscale.""
