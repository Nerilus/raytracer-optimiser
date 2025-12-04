# Évaluation 2 : Refactoring - Plan d'action

## Objectifs

1. Établir le profil initial du raytracer avec valgrind/callgrind
2. Identifier les goulots d'étranglement de performance
3. Implémenter au moins 4 optimisations significatives
4. Mesurer les améliorations de performance avant/après
5. Présenter les résultats avec les schémas valgrind

## Structure de l'évaluation

- **Premier schéma valgrind** : 1 point
- **Optimisation 1** : 1 point
- **Optimisation 2** : 1 point
- **Optimisation 3** : 1 point
- **Optimisation 4** : 1 point

**Total : 5 points**

## Problèmes identifiés dans le code

### 1. Fonction inutile `countPrimes()` dans Sphere.cpp
- **Localisation** : `src/rayscene/Sphere.cpp:20-36`
- **Problème** : Cette fonction est appelée à chaque intersection avec une sphère (ligne 75)
- **Impact** : Boucle inutile de 2 à 1000 pour chaque intersection, avec bug (ligne 25: `i <= i/2` au lieu de `i <= n/2`)
- **Solution** : Supprimer complètement cette fonction et son appel

### 2. Calculs de racine carrée inutiles dans Sphere::intersects()
- **Localisation** : `src/rayscene/Sphere.cpp:58, 66`
- **Problème** : 
  - Ligne 58 : `distance = CP.length()` calcule sqrt() pour comparer avec radius
  - Ligne 66 : `OP.length()` calcule sqrt() alors qu'on pourrait éviter
- **Solution** : Utiliser `lengthSquared()` et comparer avec `radius * radius`

### 3. Calcul de distance avec sqrt() dans Scene::closestIntersection()
- **Localisation** : `src/rayscene/Scene.cpp:56`
- **Problème** : `(intersection.Position - r.GetPosition()).length()` calcule sqrt() pour chaque objet testé, alors qu'on peut comparer les distances au carré
- **Solution** : Utiliser `lengthSquared()` et comparer les distances au carré

### 4. Division coûteuse dans Vector3::normalize()
- **Localisation** : `src/raymath/Vector3.cpp:71-79`
- **Problème** : Division par `length` (ligne 79: `return *this / length`)
- **Solution** : Calculer l'inverse une fois et multiplier (multiplication plus rapide que division)

### 5. Opérateur bitwise au lieu de logique dans Scene::raycast()
- **Localisation** : `src/rayscene/Scene.cpp:85`
- **Problème** : Utilisation de `&` (bitwise AND) au lieu de `&&` (logical AND)
- **Impact** : Évaluation inutile de la deuxième condition même si la première est fausse
- **Solution** : Remplacer par `&&`

### 6. Divisions répétées dans Camera::render()
- **Localisation** : `src/rayscene/Camera.cpp:68-72`
- **Problème** : Divisions répétées qui pourraient être optimisées
- **Solution** : Précalculer les inverses ou utiliser des multiplications

## Plan d'exécution

### Phase 1 : Profil initial

```bash
# Construire le projet en mode Release
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j4

# Créer un répertoire pour les résultats de profilage
mkdir -p profiling/initial

# Exécuter callgrind sur une scène de test
valgrind --tool=callgrind --callgrind-out-file=profiling/initial/callgrind.out \
  ./build/raytracer scenes/two-spheres-on-plane.json profiling/initial/output.png

# Générer le rapport avec kcachegrind ou callgrind_annotate
callgrind_annotate --auto=yes profiling/initial/callgrind.out > profiling/initial/report.txt

# Capturer le temps d'exécution initial
time ./build/raytracer scenes/two-spheres-on-plane.json profiling/initial/output.png
```

### Phase 2 : Optimisations

Implémenter les optimisations dans l'ordre suivant (du plus impactant au moins impactant) :

#### Optimisation 1 : Supprimer countPrimes()
- **Impact estimé** : Très élevé (fonction inutile appelée des millions de fois)
- **Fichier** : `src/rayscene/Sphere.cpp`

#### Optimisation 2 : Éviter sqrt() dans Sphere::intersects()
- **Impact estimé** : Élevé (calculé pour chaque intersection)
- **Fichier** : `src/rayscene/Sphere.cpp`

#### Optimisation 3 : Éviter sqrt() dans Scene::closestIntersection()
- **Impact estimé** : Élevé (calculé pour chaque objet testé)
- **Fichier** : `src/rayscene/Scene.cpp`

#### Optimisation 4 : Optimiser Vector3::normalize()
- **Impact estimé** : Moyen (multiplication vs division)
- **Fichier** : `src/raymath/Vector3.cpp`

#### Optimisation bonus : Corriger l'opérateur logique
- **Impact estimé** : Faible mais important pour la correction
- **Fichier** : `src/rayscene/Scene.cpp`

### Phase 3 : Profil final

```bash
# Recompiler avec les optimisations
cmake --build build -j4

# Créer un répertoire pour les résultats finaux
mkdir -p profiling/final

# Exécuter callgrind avec les optimisations
valgrind --tool=callgrind --callgrind-out-file=profiling/final/callgrind.out \
  ./build/raytracer scenes/two-spheres-on-plane.json profiling/final/output.png

# Générer le rapport final
callgrind_annotate --auto=yes profiling/final/callgrind.out > profiling/final/report.txt

# Mesurer le temps final
time ./build/raytracer scenes/two-spheres-on-plane.json profiling/final/output.png
```

### Phase 4 : Analyse comparative

Comparer les résultats :
- Temps d'exécution avant/après
- Appels de fonctions (sqrt, division, etc.)
- Temps passé dans chaque fonction

## Commandes pour générer les schémas

### Schéma initial avec kcachegrind (si disponible)
```bash
kcachegrind profiling/initial/callgrind.out
# Capture d'écran du schéma
```

### Schéma avec callgrind_annotate (alternative)
```bash
callgrind_annotate --tree=both --auto=yes profiling/initial/callgrind.out | head -100
```

### Schéma final
```bash
kcachegrind profiling/final/callgrind.out
# Capture d'écran du schéma
```

## Métriques à collecter

Pour chaque optimisation :

1. **Temps d'exécution** (avant/après)
2. **Nombre d'appels** aux fonctions coûteuses (sqrt, division)
3. **Temps CPU** dans les fonctions critiques
4. **Amélioration en pourcentage**

### Exemple de tableau de résultats

| Optimisation | Temps avant | Temps après | Amélioration | Appels sqrt() avant | Appels sqrt() après |
|--------------|-------------|-------------|--------------|---------------------|---------------------|
| Baseline     | X.XXX s     | -           | -            | XXXXX               | -                   |
| Opt 1        | -           | X.XXX s     | XX%          | -                   | XXXXX               |
| Opt 2        | -           | X.XXX s     | XX%          | -                   | XXXXX               |
| Opt 3        | -           | X.XXX s     | XX%          | -                   | XXXXX               |
| Opt 4        | -           | X.XXX s     | XX%          | -                   | XXXXX               |

## Notes importantes

- Utiliser le mode **Release** pour toutes les mesures (optimisations du compilateur activées)
- Utiliser la même scène de test pour toutes les mesures (cohérence)
- Valider que les images générées sont identiques avant/après optimisations
- Documenter chaque optimisation avec le code modifié

## Prochaines étapes

1. ✅ Plan créé
2. ⏳ Exécuter le profil initial
3. ⏳ Implémenter les optimisations
4. ⏳ Exécuter le profil final
5. ⏳ Créer le rapport final avec schémas et mesures

