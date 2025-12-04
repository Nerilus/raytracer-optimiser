#!/bin/bash

# Script pour exécuter les tests rapidement
# Usage: ./run_tests.sh [rapide|complet|monkey]

set -e

cd "$(dirname "$0")/build" || exit 1

case "${1:-rapide}" in
    rapide|fast)
        echo "🚀 Exécution des tests rapides..."
        echo ""
        ctest -R "EdgeCase_Empty|EndToEnd_TwoSpheres|EndToEnd_TwoTriangles" --output-on-failure
        ;;
    
    complet|all)
        echo "🧪 Exécution de tous les tests (sans Monkey)..."
        echo ""
        ctest -E EndToEnd_Monkey --output-on-failure
        ;;
    
    monkey)
        echo "🐒 Exécution du test Monkey (peut prendre 16+ minutes)..."
        echo ""
        ctest -R EndToEnd_Monkey --output-on-failure
        ;;
    
    liste|list)
        echo "📋 Liste des tests disponibles:"
        echo ""
        ctest -N
        ;;
    
    metriques|metrics)
        echo "📊 Métriques de performance:"
        echo ""
        if [ -f metrics.csv ]; then
            cat metrics.csv | column -t -s, 2>/dev/null || cat metrics.csv
        else
            echo "Aucune métrique disponible. Exécutez d'abord les tests."
        fi
        ;;
    
    *)
        echo "Usage: $0 [rapide|complet|monkey|liste|metriques]"
        echo ""
        echo "Options:"
        echo "  rapide (défaut)  - Tests rapides (~4-5 secondes)"
        echo "  complet          - Tous les tests sauf Monkey"
        echo "  monkey           - Test Monkey uniquement (très long)"
        echo "  liste            - Lister tous les tests"
        echo "  metriques        - Afficher les métriques de performance"
        exit 1
        ;;
esac


