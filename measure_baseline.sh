#!/bin/bash

# Script pour mesurer les temps d'exécution initiaux (baseline)
# avant toute optimisation

echo "========================================="
echo "  MESURE BASELINE - TEMPS INITIAUX"
echo "========================================="
echo ""

# Créer les répertoires de résultats
mkdir -p profiling/baseline

# Scènes à tester
scenes=(
    "two-spheres-on-plane.json"
    "two-triangles-on-plane.json"
    "monkey-on-plane.json"
)

# Fichier pour stocker les résultats
results_file="profiling/baseline/times_baseline.txt"

echo "Date: $(date)" > "$results_file"
echo "Mode: Release" >> "$results_file"
echo "=========================================" >> "$results_file"
echo "" >> "$results_file"

for scene in "${scenes[@]}"; do
    scene_name=$(basename "$scene" .json)
    echo "Test de la scène: $scene_name"
    echo "----------------------------------------"
    
    # Exécuter 3 fois pour avoir une moyenne
    total_time=0
    for i in {1..3}; do
        echo "  Exécution $i/3..."
        output=$(./build/raytracer "scenes/$scene" "profiling/baseline/${scene_name}_run${i}.png" 2>&1)
        
        # Extraire le temps depuis la sortie
        time=$(echo "$output" | grep "Total time:" | sed 's/Total time: \([0-9.]*\) seconds./\1/')
        
        if [ -n "$time" ]; then
            echo "    Temps: ${time}s"
            echo "$scene_name (run $i): $time s" >> "$results_file"
            total_time=$(echo "$total_time + $time" | bc)
        else
            echo "    ERREUR: Impossible d'extraire le temps"
        fi
    done
    
    # Calculer la moyenne
    if [ -n "$time" ]; then
        avg_time=$(echo "scale=3; $total_time / 3" | bc)
        echo "  Moyenne: ${avg_time}s"
        echo "$scene_name (moyenne): $avg_time s" >> "$results_file"
        echo "" >> "$results_file"
    fi
    echo ""
done

echo "========================================="
echo "Résultats sauvegardés dans: $results_file"
echo "========================================="

# Afficher le contenu du fichier de résultats
cat "$results_file"

