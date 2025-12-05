# Guide d'utilisation du BSP-Tree

## 🎯 Objectif

Ce guide vous aide à tester les différentes configurations d'optimisation du raytracer :
- **BSP-Tree** : Accélération spatiale pour réduire les tests d'intersection
- **Multithreading** : Rendu parallèle sur plusieurs cœurs CPU

## 📋 Configuration des optimisations

### Éditer `/app/CMakeLists.txt`

Ouvrez le fichier et décommentez les lignes selon les optimisations souhaitées :

```cmake
# Activer le multithreading pour le rendu parallèle
# add_compile_definitions(ENABLE_MULTITHREADING)

# Activer le BSP-Tree pour accélérer les intersections rayon-scène
# add_compile_definitions(ENABLE_BSP)
```

### Les 4 configurations à tester

#### 1️⃣ Configuration BASELINE (BSP OFF + Threading OFF)
```cmake
# add_compile_definitions(ENABLE_MULTITHREADING)
# add_compile_definitions(ENABLE_BSP)
```

#### 2️⃣ Configuration BSP ONLY (BSP ON + Threading OFF)
```cmake
# add_compile_definitions(ENABLE_MULTITHREADING)
add_compile_definitions(ENABLE_BSP)
```

#### 3️⃣ Configuration THREADING ONLY (BSP OFF + Threading ON)
```cmake
add_compile_definitions(ENABLE_MULTITHREADING)
# add_compile_definitions(ENABLE_BSP)
```

#### 4️⃣ Configuration FULL (BSP ON + Threading ON)
```cmake
add_compile_definitions(ENABLE_MULTITHREADING)
add_compile_definitions(ENABLE_BSP)
```

## 🔨 Recompilation après chaque modification

**IMPORTANT** : Après chaque modification de `CMakeLists.txt`, recompiler :

```bash
cd /app/build
cmake ..
make
```

## 🧪 Scènes de test recommandées

### Scène simple (sphères)
```bash
cd /app/build
./raytracer ../scenes/two-spheres-on-plane.json output_config1.png
```
**Gain attendu** : Faible (peu d'objets)

### Scène avec mesh
```bash
./raytracer ../scenes/iso-sphere-on-plane.json output_config1.png
```
**Gain attendu** : Moyen (le mesh utilise déjà une AABB)

### Scène complexe (singe)
```bash
./raytracer ../scenes/monkey-on-plane.json output_config1.png
```
**Gain attendu** : Élevé (beaucoup de triangles)

### Scène complète
```bash
./raytracer ../scenes/all.json output_config1.png
```
**Gain attendu** : Très élevé (combinaison de tous les objets)

## 📊 Tableau de résultats à remplir

| Scène | BSP OFF + Thread OFF | BSP ON + Thread OFF | BSP OFF + Thread ON | BSP ON + Thread ON |
|-------|---------------------|---------------------|---------------------|---------------------|
| **two-spheres** | ⏱️ ___ s | ⏱️ ___ s | ⏱️ ___ s | ⏱️ ___ s |
| **iso-sphere** | ⏱️ ___ s | ⏱️ ___ s | ⏱️ ___ s | ⏱️ ___ s |
| **monkey** | ⏱️ ___ s | ⏱️ ___ s | ⏱️ ___ s | ⏱️ ___ s |
| **all** | ⏱️ ___ s | ⏱️ ___ s | ⏱️ ___ s | ⏱️ ___ s |

## ✅ Vérification de la correctness

**IMPORTANT** : Comparez visuellement les images générées pour chaque configuration. Elles doivent être **identiques** !

```bash
# Ouvrir les images dans VSCode
code output_config1.png
code output_config2.png
code output_config3.png
code output_config4.png
```

## 🔍 Messages de diagnostic

### Avec BSP activé
```
Building BSP-Tree with XXX objects...
BSP-Tree built successfully.
```

### Avec Threading activé
```
Rendering with N threads...
```

### Sans optimisations
```
Rendering single-threaded...
```

## 🚀 Analyse des résultats

### Speedup du BSP
```
Speedup_BSP = Temps(BSP OFF) / Temps(BSP ON)
```

### Speedup du Threading
```
Speedup_Threading = Temps(Thread OFF) / Temps(Thread ON)
```

### Speedup combiné
```
Speedup_Total = Temps(Baseline) / Temps(Full)
```

### Efficacité du parallélisme
```
Efficacité = Speedup_Threading / Nombre_de_threads
```
Idéalement proche de 1.0 (100%)

## 📝 Notes techniques

### Paramètres du BSP-Tree

Dans `Scene.cpp` :
```cpp
bspTree = new BSPTree(20, 5);
           // maxDepth=20, maxObjectsPerLeaf=5
```

- **maxDepth** : Profondeur maximale de l'arbre (plus élevé = arbre plus profond)
- **maxObjectsPerLeaf** : Nombre d'objets maximum par feuille avant subdivision

### Stratégie de découpage

Le BSP divise l'espace en choisissant :
1. **L'axe le plus long** (X, Y ou Z)
2. **Position au milieu** de la boîte englobante

Cette stratégie simple fonctionne bien pour des scènes équilibrées.

## 🐛 Dépannage

### Erreur de compilation
```
rm -rf /app/build
mkdir /app/build
cd /app/build
cmake ..
make
```

### Le BSP ne semble pas s'activer
Vérifiez que :
1. `add_compile_definitions(ENABLE_BSP)` est décommenté dans CMakeLists.txt
2. Vous avez bien fait `cmake ..` après la modification
3. Le message "Building BSP-Tree..." apparaît au lancement

### Les images sont différentes
Si les images diffèrent entre configurations, il y a un bug dans le BSP !
Vérifiez :
- La logique de traversée du BSP
- Le calcul des AABB pour chaque type d'objet
- Les plans infinis gérés correctement

## 📚 Ressources

- [BSP Tree - Wikipedia](https://en.wikipedia.org/wiki/Binary_space_partitioning)
- [Ray Tracing Optimization - Scratchapixel](https://www.scratchapixel.com/)

