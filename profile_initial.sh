#!/bin/bash

# Script pour créer le profil initial avec Valgrind/Callgrind
# Usage: ./profile_initial.sh [scene.json]

set -e

SCENE="${1:-scenes/two-spheres-on-plane.json}"
SCENE_NAME=$(basename "$SCENE" .json)
PROFILE_DIR="profiling/initial"

echo "========================================="
echo "  PROFILAGE INITIAL - VALGRIND/CALLGRIND"
echo "========================================="
echo ""
echo "Scène: $SCENE"
echo "Répertoire: $PROFILE_DIR"
echo ""

# Créer le répertoire de profilage
mkdir -p "$PROFILE_DIR"

# Vérifier que le build existe
if [ ! -f "build/raytracer" ]; then
    echo "❌ Erreur: build/raytracer n'existe pas"
    echo "   Compilez d'abord avec: cmake --build build"
    exit 1
fi

# Vérifier Valgrind
if ! command -v valgrind &> /dev/null; then
    echo "❌ Erreur: Valgrind n'est pas installé"
    echo "   Exécutez: ./install_profiling_tools.sh"
    exit 1
fi

echo "📊 Étape 1: Mesure du temps d'exécution initial..."
echo "----------------------------------------"
time_output=$(time (./build/raytracer "$SCENE" "$PROFILE_DIR/output.png" > "$PROFILE_DIR/time_output.txt" 2>&1) 2>&1)
echo "$time_output" > "$PROFILE_DIR/time_measurement.txt"
echo "$time_output"
echo ""

echo "📊 Étape 2: Profilage avec Callgrind (cela peut prendre du temps)..."
echo "----------------------------------------"
echo "⚠️  Le profilage avec Valgrind est beaucoup plus lent que l'exécution normale"
echo "   Cela peut prendre 10-50x plus de temps..."
echo ""

CALLGRIND_OUT="$PROFILE_DIR/callgrind.out"
valgrind --tool=callgrind \
    --callgrind-out-file="$CALLGRIND_OUT" \
    --dump-instr=yes \
    --collect-jumps=yes \
    ./build/raytracer "$SCENE" "$PROFILE_DIR/output.png" > "$PROFILE_DIR/valgrind_output.txt" 2>&1

if [ -f "$CALLGRIND_OUT" ]; then
    echo "✅ Profil Callgrind créé: $CALLGRIND_OUT"
else
    echo "❌ Erreur: Le fichier callgrind.out n'a pas été créé"
    exit 1
fi

echo ""
echo "📊 Étape 3: Génération du rapport textuel..."
echo "----------------------------------------"
if command -v callgrind_annotate &> /dev/null; then
    callgrind_annotate --auto=yes "$CALLGRIND_OUT" > "$PROFILE_DIR/report.txt" 2>&1
    echo "✅ Rapport textuel créé: $PROFILE_DIR/report.txt"
    
    # Afficher les 30 premières lignes du rapport
    echo ""
    echo "Top fonctions (extrait):"
    echo "----------------------------------------"
    head -30 "$PROFILE_DIR/report.txt"
else
    echo "⚠️  callgrind_annotate non disponible, rapport textuel non généré"
fi

echo ""
echo "📊 Étape 4: Extraction des métriques..."
echo "----------------------------------------"
# Extraire le temps depuis la sortie
if [ -f "$PROFILE_DIR/time_output.txt" ]; then
    TIME=$(grep "Total time:" "$PROFILE_DIR/time_output.txt" | sed 's/Total time: \([0-9.]*\) seconds./\1/')
    if [ -n "$TIME" ]; then
        echo "Temps d'exécution: ${TIME}s"
        echo "$SCENE_NAME,$TIME" >> "$PROFILE_DIR/metrics.csv"
    fi
fi

# Créer un fichier de métriques si il n'existe pas
if [ ! -f "$PROFILE_DIR/metrics.csv" ]; then
    echo "Scene,TimeSeconds" > "$PROFILE_DIR/metrics.csv"
fi

echo ""
echo "========================================="
echo "✅ Profilage initial terminé !"
echo "========================================="
echo ""
echo "Fichiers générés dans $PROFILE_DIR/:"
echo "  • callgrind.out - Données de profilage"
echo "  • report.txt - Rapport textuel"
echo "  • output.png - Image générée"
echo "  • metrics.csv - Métriques de temps"
echo ""
echo "Prochaine étape: Exécutez ./generate_profile_graph.sh initial"
echo ""


