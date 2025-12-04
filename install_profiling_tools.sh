#!/bin/bash

# Script pour installer les outils de profilage nécessaires
# Usage: ./install_profiling_tools.sh

set -e

echo "========================================="
echo "  INSTALLATION DES OUTILS DE PROFILAGE"
echo "========================================="
echo ""

# Vérifier si on est root ou si sudo est disponible
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Détecter la distribution et le gestionnaire de paquets
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "⚠️  Impossible de détecter la distribution, tentative avec apt-get"
    DISTRO="unknown"
fi

# Déterminer le gestionnaire de paquets
if command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    PKG_INSTALL="$SUDO dnf install -y"
    PKG_UPDATE="$SUDO dnf update -y"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    PKG_INSTALL="$SUDO yum install -y"
    PKG_UPDATE="$SUDO yum update -y"
elif command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    PKG_INSTALL="$SUDO apt-get install -y"
    PKG_UPDATE="$SUDO apt-get update"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    PKG_INSTALL="$SUDO pacman -S --noconfirm"
    PKG_UPDATE="$SUDO pacman -Sy"
else
    echo "❌ Erreur: Aucun gestionnaire de paquets trouvé (dnf, yum, apt-get, pacman)"
    echo "   Veuillez installer manuellement: valgrind python3 python3-pip graphviz"
    exit 1
fi

echo "📦 Distribution détectée: $DISTRO"
echo "📦 Gestionnaire de paquets: $PKG_MANAGER"
echo ""

# Vérifier Valgrind
echo "🔍 Vérification de Valgrind..."
if command -v valgrind &> /dev/null; then
    VERSION=$(valgrind --version)
    echo "✅ Valgrind déjà installé: $VERSION"
else
    echo "📦 Installation de Valgrind..."
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        $PKG_UPDATE
    fi
    $PKG_INSTALL valgrind
    echo "✅ Valgrind installé"
fi

# Vérifier Python3
echo ""
echo "🔍 Vérification de Python3..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python3 déjà installé: $PYTHON_VERSION"
else
    echo "📦 Installation de Python3..."
    if [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
        $PKG_INSTALL python3 python3-pip
    else
        $PKG_INSTALL python3 python3-pip
    fi
    echo "✅ Python3 installé"
fi

# Vérifier pip
echo ""
echo "🔍 Vérification de pip..."
if command -v pip3 &> /dev/null || python3 -m pip --version &> /dev/null; then
    echo "✅ pip disponible"
else
    echo "📦 Installation de pip..."
    if [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
        $PKG_INSTALL python3-pip
    else
        $PKG_INSTALL python3-pip
    fi
    echo "✅ pip installé"
fi

# Vérifier graphviz
echo ""
echo "🔍 Vérification de graphviz..."
if command -v dot &> /dev/null; then
    DOT_VERSION=$(dot -V 2>&1 | head -1)
    echo "✅ graphviz déjà installé: $DOT_VERSION"
else
    echo "📦 Installation de graphviz..."
    $PKG_INSTALL graphviz
    echo "✅ graphviz installé"
fi

# Vérifier gprof2dot
echo ""
echo "🔍 Vérification de gprof2dot..."
if python3 -c "import gprof2dot" 2>/dev/null; then
    echo "✅ gprof2dot déjà installé"
else
    echo "📦 Installation de gprof2dot..."
    python3 -m pip install --user gprof2dot
    echo "✅ gprof2dot installé"
fi

# Vérifier callgrind_annotate
echo ""
echo "🔍 Vérification de callgrind_annotate..."
if command -v callgrind_annotate &> /dev/null; then
    echo "✅ callgrind_annotate disponible"
else
    echo "⚠️  callgrind_annotate non trouvé (normalement inclus avec Valgrind)"
fi

echo ""
echo "========================================="
echo "✅ Tous les outils sont prêts !"
echo "========================================="
echo ""
echo "Outils installés :"
echo "  • Valgrind (profilage)"
echo "  • Python3 + pip"
echo "  • graphviz (génération de graphiques)"
echo "  • gprof2dot (conversion callgrind → graphique)"
echo ""

