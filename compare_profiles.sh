#!/bin/bash

# Script pour comparer les profils initial et final
# Usage: ./compare_profiles.sh

set -e

echo "========================================="
echo "  COMPARAISON DES PROFILS"
echo "========================================="
echo ""

INITIAL_DIR="profiling/initial"
FINAL_DIR="profiling/final"
COMPARISON_FILE="profiling/comparison.txt"

# Créer le répertoire de comparaison
mkdir -p profiling

# Vérifier que les profils existent
if [ ! -f "$INITIAL_DIR/metrics.csv" ] && [ ! -f "$INITIAL_DIR/time_output.txt" ]; then
    echo "❌ Erreur: Profil initial non trouvé"
    echo "   Exécutez d'abord: ./profile_initial.sh"
    exit 1
fi

if [ ! -f "$FINAL_DIR/metrics.csv" ] && [ ! -f "$FINAL_DIR/time_output.txt" ]; then
    echo "❌ Erreur: Profil final non trouvé"
    echo "   Exécutez d'abord: ./profile_final.sh"
    exit 1
fi

echo "📊 Extraction des temps d'exécution..."
echo "----------------------------------------"

# Extraire les temps
INITIAL_TIME=""
FINAL_TIME=""

if [ -f "$INITIAL_DIR/time_output.txt" ]; then
    INITIAL_TIME=$(grep "Total time:" "$INITIAL_DIR/time_output.txt" | sed 's/Total time: \([0-9.]*\) seconds./\1/')
fi

if [ -f "$FINAL_DIR/time_output.txt" ]; then
    FINAL_TIME=$(grep "Total time:" "$FINAL_DIR/time_output.txt" | sed 's/Total time: \([0-9.]*\) seconds./\1/')
fi

if [ -z "$INITIAL_TIME" ] || [ -z "$FINAL_TIME" ]; then
    echo "⚠️  Impossible d'extraire les temps depuis les fichiers"
    echo "   Vérifiez les fichiers time_output.txt"
    exit 1
fi

echo "Temps initial: ${INITIAL_TIME}s"
echo "Temps final:   ${FINAL_TIME}s"
echo ""

# Calculer l'amélioration
IMPROVEMENT=$(echo "scale=2; ($INITIAL_TIME - $FINAL_TIME) / $INITIAL_TIME * 100" | bc)
SPEEDUP=$(echo "scale=2; $INITIAL_TIME / $FINAL_TIME" | bc)

echo "📈 Résultats de la comparaison:"
echo "----------------------------------------"
echo "Amélioration: ${IMPROVEMENT}%"
echo "Accélération: ${SPEEDUP}x"
echo ""

# Créer un rapport de comparaison
{
    echo "========================================="
    echo "  RAPPORT DE COMPARAISON DES PROFILS"
    echo "========================================="
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "TEMPS D'EXÉCUTION:"
    echo "  Initial: ${INITIAL_TIME}s"
    echo "  Final:   ${FINAL_TIME}s"
    echo "  Amélioration: ${IMPROVEMENT}%"
    echo "  Accélération: ${SPEEDUP}x"
    echo ""
    echo "----------------------------------------"
    echo ""
    
    # Comparer les rapports callgrind si disponibles
    if [ -f "$INITIAL_DIR/report.txt" ] && [ -f "$FINAL_DIR/report.txt" ]; then
        echo "TOP 10 FONCTIONS - AVANT:"
        echo "----------------------------------------"
        head -15 "$INITIAL_DIR/report.txt" | grep -E "^[0-9]" | head -10
        echo ""
        echo "TOP 10 FONCTIONS - APRÈS:"
        echo "----------------------------------------"
        head -15 "$FINAL_DIR/report.txt" | grep -E "^[0-9]" | head -10
    fi
} > "$COMPARISON_FILE"

echo "✅ Rapport de comparaison créé: $COMPARISON_FILE"
echo ""

# Afficher le rapport
cat "$COMPARISON_FILE"

echo ""
echo "========================================="
echo "✅ Comparaison terminée !"
echo "========================================="


