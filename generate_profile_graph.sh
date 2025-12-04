#!/bin/bash

# Script pour générer les graphiques visuels à partir des profils Callgrind
# Usage: ./generate_profile_graph.sh [initial|final|both]

set -e

MODE="${1:-both}"

echo "========================================="
echo "  GÉNÉRATION DES GRAPHIQUES DE PROFILAGE"
echo "========================================="
echo ""

# Vérifier gprof2dot
if ! python3 -c "import gprof2dot" 2>/dev/null; then
    echo "❌ Erreur: gprof2dot n'est pas installé"
    echo "   Exécutez: ./install_profiling_tools.sh"
    exit 1
fi

# Vérifier graphviz
if ! command -v dot &> /dev/null; then
    echo "❌ Erreur: graphviz (dot) n'est pas installé"
    echo "   Exécutez: ./install_profiling_tools.sh"
    exit 1
fi

generate_graph() {
    local PROFILE_DIR=$1
    local OUTPUT_NAME=$2
    
    if [ ! -f "$PROFILE_DIR/callgrind.out" ]; then
        echo "⚠️  Fichier $PROFILE_DIR/callgrind.out non trouvé, ignoré"
        return 1
    fi
    
    echo "📊 Génération du graphique pour $PROFILE_DIR..."
    
    # Générer le graphique PNG
    python3 -m gprof2dot -f callgrind "$PROFILE_DIR/callgrind.out" | \
        dot -Tpng -o "$PROFILE_DIR/profile_graph.png" 2>/dev/null
    
    if [ -f "$PROFILE_DIR/profile_graph.png" ]; then
        echo "✅ Graphique créé: $PROFILE_DIR/profile_graph.png"
        
        # Générer aussi en SVG (plus léger et scalable)
        python3 -m gprof2dot -f callgrind "$PROFILE_DIR/callgrind.out" | \
            dot -Tsvg -o "$PROFILE_DIR/profile_graph.svg" 2>/dev/null
        
        if [ -f "$PROFILE_DIR/profile_graph.svg" ]; then
            echo "✅ Graphique SVG créé: $PROFILE_DIR/profile_graph.svg"
        fi
        
        return 0
    else
        echo "❌ Erreur lors de la génération du graphique"
        return 1
    fi
}

case "$MODE" in
    initial)
        generate_graph "profiling/initial" "initial"
        ;;
    final)
        generate_graph "profiling/final" "final"
        ;;
    both|*)
        echo "Génération des graphiques pour initial et final..."
        echo ""
        generate_graph "profiling/initial" "initial"
        echo ""
        generate_graph "profiling/final" "final"
        ;;
esac

echo ""
echo "========================================="
echo "✅ Génération terminée !"
echo "========================================="
echo ""
echo "Graphiques disponibles:"
if [ -f "profiling/initial/profile_graph.png" ]; then
    echo "  • profiling/initial/profile_graph.png"
    echo "  • profiling/initial/profile_graph.svg"
fi
if [ -f "profiling/final/profile_graph.png" ]; then
    echo "  • profiling/final/profile_graph.png"
    echo "  • profiling/final/profile_graph.svg"
fi
echo ""


