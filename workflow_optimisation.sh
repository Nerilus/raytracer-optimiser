#!/bin/bash

# Script principal pour exécuter le workflow complet d'optimisation
# Usage: ./workflow_optimisation.sh [scene.json]

set -e

SCENE="${1:-scenes/two-spheres-on-plane.json}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     WORKFLOW COMPLET D'OPTIMISATION                        ║"
echo "║     (5 Étapes selon la méthodologie)                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier que les outils sont installés
if ! command -v valgrind &> /dev/null; then
    echo "⚠️  Valgrind n'est pas installé"
    read -p "Voulez-vous installer les outils de profilage ? (o/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoYy]$ ]]; then
        ./install_profiling_tools.sh
    else
        echo "❌ Impossible de continuer sans Valgrind"
        exit 1
    fi
fi

# Vérifier que le projet est compilé
if [ ! -f "build/raytracer" ]; then
    echo "⚠️  Le projet n'est pas compilé"
    echo "Compilation en cours..."
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build -j4
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 1 : MESURER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 1.1: Mesure du temps d'exécution initial..."
echo ""

# Mesure simple du temps
echo "Exécution du raytracer pour mesurer le temps..."
./build/raytracer "$SCENE" /tmp/baseline_output.png > /tmp/baseline_time.txt 2>&1
BASELINE_TIME=$(grep "Total time:" /tmp/baseline_time.txt | sed 's/Total time: \([0-9.]*\) seconds./\1/')
echo "✅ Temps initial mesuré: ${BASELINE_TIME}s"
echo ""

echo "📊 1.2: Profilage avec Valgrind/Callgrind..."
echo "⚠️  Cela peut prendre beaucoup de temps (10-50x plus lent)..."
read -p "Voulez-vous exécuter le profilage complet ? (o/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    ./profile_initial.sh "$SCENE"
    echo ""
    echo "📊 1.3: Génération des graphiques visuels..."
    ./generate_profile_graph.sh initial
else
    echo "⏭️  Profilage Callgrind ignoré (vous pouvez l'exécuter plus tard avec ./profile_initial.sh)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 2 : ANALYSER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Problèmes identifiés (voir EVALUATION2_PLAN.md):"
echo ""
echo "  1. ✅ countPrimes() inutile dans Sphere.cpp"
echo "  2. ✅ sqrt() inutiles dans Sphere::intersects()"
echo "  3. ✅ sqrt() dans Scene::closestIntersection()"
echo "  4. ✅ Division coûteuse dans Vector3::normalize()"
echo "  5. ✅ Opérateur bitwise au lieu de logique"
echo "  6. ✅ Divisions répétées dans Camera::render()"
echo ""

if [ -f "profiling/initial/report.txt" ]; then
    echo "📊 Rapport de profilage disponible:"
    echo "   • profiling/initial/report.txt"
    echo "   • profiling/initial/profile_graph.png"
    echo ""
    echo "Top 10 fonctions les plus coûteuses:"
    head -15 "profiling/initial/report.txt" | grep -E "^[0-9]" | head -10
fi

echo ""
read -p "Appuyez sur Entrée pour continuer vers l'étape 3..."
echo ""

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 3 : RÉPONDRE (OPTIMISER)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  ATTENTION: Cette étape nécessite de modifier le code manuellement"
echo ""
echo "Les optimisations à implémenter sont documentées dans:"
echo "  • EVALUATION2_PLAN.md"
echo ""
echo "Ordre recommandé:"
echo "  1. Supprimer countPrimes() (~5 min)"
echo "  2. Éviter sqrt() dans Sphere::intersects() (~30 min)"
echo "  3. Éviter sqrt() dans Scene::closestIntersection() (~30 min)"
echo "  4. Optimiser Vector3::normalize() (~20 min)"
echo "  5. Corriger opérateur logique (~5 min)"
echo "  6. Optimiser Camera::render() (~20 min)"
echo ""
echo "Après chaque optimisation:"
echo "  • Recompiler: cmake --build build"
echo "  • Tester: ./run_tests.sh rapide"
echo "  • Vérifier que les images restent identiques"
echo ""
read -p "Appuyez sur Entrée quand vous avez terminé les optimisations..."
echo ""

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 4 : TESTER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🧪 Exécution des tests pour valider les optimisations..."
echo ""

# Exécuter les tests rapides
if [ -f "run_tests.sh" ]; then
    ./run_tests.sh rapide
else
    cd build && ctest -R "EdgeCase_Empty|EndToEnd_TwoSpheres|EndToEnd_TwoTriangles" --output-on-failure
    cd ..
fi

echo ""
echo "✅ Tests terminés"
echo ""

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 5 : MESURER ET RÉPÉTER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Mesure du temps final
echo "📊 5.1: Mesure du temps d'exécution final..."
./build/raytracer "$SCENE" /tmp/optimized_output.png > /tmp/optimized_time.txt 2>&1
OPTIMIZED_TIME=$(grep "Total time:" /tmp/optimized_time.txt | sed 's/Total time: \([0-9.]*\) seconds./\1/')
echo "✅ Temps final mesuré: ${OPTIMIZED_TIME}s"
echo ""

# Calculer l'amélioration
if [ -n "$BASELINE_TIME" ] && [ -n "$OPTIMIZED_TIME" ]; then
    IMPROVEMENT=$(echo "scale=2; ($BASELINE_TIME - $OPTIMIZED_TIME) / $BASELINE_TIME * 100" | bc)
    SPEEDUP=$(echo "scale=2; $BASELINE_TIME / $OPTIMIZED_TIME" | bc)
    
    echo "📈 Résultats:"
    echo "  Temps initial:  ${BASELINE_TIME}s"
    echo "  Temps final:    ${OPTIMIZED_TIME}s"
    echo "  Amélioration:   ${IMPROVEMENT}%"
    echo "  Accélération:   ${SPEEDUP}x"
    echo ""
fi

# Profilage final
read -p "Voulez-vous créer le profil final avec Callgrind ? (o/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    ./profile_final.sh "$SCENE"
    echo ""
    echo "📊 5.2: Génération des graphiques finaux..."
    ./generate_profile_graph.sh final
    echo ""
    echo "📊 5.3: Comparaison des profils..."
    ./compare_profiles.sh
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     WORKFLOW TERMINÉ !                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Fichiers générés:"
echo "  • profiling/initial/ - Profil initial"
echo "  • profiling/final/ - Profil final"
echo "  • profiling/comparison.txt - Rapport de comparaison"
echo ""
echo "📊 Graphiques disponibles:"
echo "  • profiling/initial/profile_graph.png"
echo "  • profiling/final/profile_graph.png"
echo ""


