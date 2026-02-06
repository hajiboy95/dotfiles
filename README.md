# Dotfiles

## 🚀 Quick Start

Before running the setup, ensure you have **Xcode Command Line Tools** (includes `git`) installed:

```bash
xcode-select --install
```

> 🛠️ This is required for Git and other developer tools. After installing, rerun the command below if needed.

---

### Clone and Run Setup

```bash
git clone https://github.com/hajiboy95/dotfiles.git
cd dotfiles
./setup.sh
```

---

### From time to time update the icon_map

1. Visit the [SketchyBar App Font releases page](https://github.com/kvndrsslr/sketchybar-app-font/releases).
2. Download the latest `icon_map.sh`.
3. Replace the old one in the folder `sketchybar` by the new one.

---

### 🔋 Post-Setup: Disable Optimized Battery Charging

To avoid any interference with battery management tools like **Battery Toolkit**, you should turn off Optimized Battery Charging:

1. Open **System Settings**.
2. Go to **Battery**.
3. Click the **(i)** button next to **Battery Health**.
4. Toggle **Optimized Battery Charging** to **Off**.

---

### 🍺 Updating the Brewfile

If you want to update the Brewfile to reflect your current Homebrew packages, run within the dotfiles folder the following command:

```bash
brew bundle dump --describe
```

This will generate (or update) the `Brewfile` in the current directory with descriptions for installed packages.
