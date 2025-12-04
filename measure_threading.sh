#!/bin/bash

# Script pour mesurer les performances avec et sans threading

SCENE="scenes/two-spheres-on-plane.json"
NUM_RUNS=3

echo "========================================="
echo "  MESURE DES PERFORMANCES THREADING"
echo "========================================="
echo ""

# Créer les répertoires
mkdir -p threading_results

# Fonction pour mesurer le temps
measure_time() {
    local config=$1
    local output_dir=$2
    local total=0
    
    echo "Configuration: $config"
    echo "----------------------------------------"
    
    for i in $(seq 1 $NUM_RUNS); do
        echo "  Run $i/$NUM_RUNS..."
        output=$(./build/raytracer "$SCENE" "${output_dir}/output_run${i}.png" 2>&1)
        time=$(echo "$output" | grep "Total time:" | sed 's/Total time: \([0-9.]*\) seconds./\1/')
        
        if [ -n "$time" ]; then
            echo "    Temps: ${time}s"
            total=$(echo "$total + $time" | bc)
        fi
    done
    
    avg=$(echo "scale=3; $total / $NUM_RUNS" | bc)
    echo "  Moyenne: ${avg}s"
    echo ""
    echo "$avg"
}

# Configuration 1: Sans threading
echo "=== Configuration 1: SANS THREADING ==="
rm -rf build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_THREADING=OFF > /dev/null 2>&1
cmake --build build -j4 > /dev/null 2>&1

time_no_threading=$(measure_time "Sans threading" "threading_results/no_threading")
echo "Temps moyen sans threading: ${time_no_threading}s" > threading_results/results.txt

# Configuration 2: Avec threading
echo "=== Configuration 2: AVEC THREADING ==="
rm -rf build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_THREADING=ON > /dev/null 2>&1
cmake --build build -j4 > /dev/null 2>&1

time_with_threading=$(measure_time "Avec threading" "threading_results/with_threading")
echo "Temps moyen avec threading: ${time_with_threading}s" >> threading_results/results.txt

# Calculer l'amélioration
improvement=$(echo "scale=2; (($time_no_threading - $time_with_threading) / $time_no_threading) * 100" | bc)
echo "Amélioration: ${improvement}%" >> threading_results/results.txt

echo "========================================="
echo "RÉSULTATS:"
cat threading_results/results.txt
echo "========================================="

