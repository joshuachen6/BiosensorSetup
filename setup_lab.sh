#!/bin/zsh

# --- 1. PRE-FLIGHT & NAMING ---
echo "🚀 Starting Biosensors Lab macOS Setup..."
# Check sticker for machine number (xx)
echo -n "Enter Machine Name (e.g., Mini-09, Studio-04): "
read MACHINE_NAME
ACCOUNT_NAME=$(echo "$MACHINE_NAME" | tr '[:upper:]' '[:lower:]')

# --- 2. INSTALL HOMEBREW (Robust Check) ---
HOMEBREW_PREFIX="/opt/homebrew"
if [[ ! -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
    echo "🍺 Homebrew not found. Installing (Non-interactive)..."
    /bin/bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
else
    echo "✅ Homebrew is already installed at $HOMEBREW_PREFIX."
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
fi

# --- 3. SYSTEM PREFERENCES ---
echo "⚙️ Configuring System Settings..."
sudo pmset -a displaysleep 180
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

# --- 4. INSTALL SOFTWARE VIA BREW ---
echo "📦 Installing Applications and Dependencies..."
apps=(
    slack microsoft-teams notion tailscale 
    visual-studio-code parsec realvnc-connect
)
brew install --cask "${apps[@]}"
brew install --cask "${apps[@]}"
# Required system libraries for Python and Starship
brew install pyenv pyenv-virtualenv starship git xz libusb libomp ffmpeg@2.8 openssl@3 readline sqlite3 zlib tcl-tk ncurses

# --- 5. SHELL SETUP ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

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
echo "🐍 Setting up Python environments..."
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Check and install versions only if missing
[[ -d "$(pyenv root)/versions/3.14.2" ]] || pyenv install 3.14.2
[[ -d "$(pyenv root)/versions/3.10.19" ]] || pyenv install 3.10.19

# Create virtualenvs if they don't exist
[[ -d "$(pyenv root)/versions/MantisCam" ]] || pyenv virtualenv 3.14.2 MantisCam
[[ -d "$(pyenv root)/versions/MantisCamFLIR" ]] || pyenv virtualenv 3.10.19 MantisCamFLIR
pyenv global MantisCam

# --- 7. SSH KEY CHECK & GITHUB PAUSE ---
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ -f "$SSH_KEY" ]]; then
    echo "✅ SSH Key already exists at $SSH_KEY."
else
    echo "🔑 Generating new SSH Key..."
    ssh-keygen -t ed25519 -C "students@bsl-uiuc.com" -f "$SSH_KEY" -N ""
fi

eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain "$SSH_KEY"

echo "\n--- YOUR PUBLIC SSH KEY ---"
cat "${SSH_KEY}.pub"
pbcopy < "${SSH_KEY}.pub"
echo "---------------------------\n"

echo "⚠️  ACTION REQUIRED:"
echo "1. Key copied to clipboard. Paste into GitHub Settings."
echo "2. Name key: '$MACHINE_NAME'."
echo "3. Authorize 'BioSensorsLab-Illinois' SSO."
echo ""
echo -n "Press [ENTER] to continue cloning once authorized..."
read DISCARD_INPUT 

# --- 8. REPO CLONING ---
echo "📂 Cloning Repositories..."
mkdir -p ~/BioSensorsLab && cd ~/BioSensorsLab
[[ -d "MantisCamUnified" ]] || git clone git@github.com:BioSensorsLab-Illinois/MantisCamUnified.git
[[ -d "bsl_scripts" ]] || git clone git@github.com:BioSensorsLab-Illinois/bsl_scripts.git
[[ -d "bsl_universal" ]] || git clone git@github.com:BioSensorsLab-Illinois/bsl_universal.git

cd bsl_universal && pip install .

echo "\n✅ Script complete! Finish manual steps (NI-VISA, Fonts, App logins)."
