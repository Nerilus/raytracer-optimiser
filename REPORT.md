# Rapport d'implémentation du système de tests automatisés

## Résumé

J'ai mis en place un système complet de tests automatisés pour le projet de raytracer, incluant :
- Des tests end-to-end avec comparaison d'images
- Une collecte automatique de métriques de performance
- Un framework de tests utilisant CMake/CTest
- Des cas de test variés (tests fonctionnels, cas limites, démonstration d'échec)

## Ce qui a été fait

### 1. Création de l'utilitaire de comparaison d'images

J'ai créé un programme `compare_images` (`tests/compare_images.cpp`) qui permet de comparer deux images PNG pixel par pixel. Cet outil :
- Charge deux images PNG en utilisant la bibliothèque lodepng
- Vérifie que les dimensions correspondent
- Compare tous les pixels avec une tolérance configurable
- Retourne un code d'erreur approprié pour l'intégration avec CMake

### 2. Mise en place du système de tests avec CMake

J'ai modifié le `CMakeLists.txt` principal pour :
- Activer le système de tests avec `enable_testing()`
- Ajouter le sous-répertoire `tests` avec `add_subdirectory(tests)`

### 3. Configuration des tests dans `tests/CMakeLists.txt`

J'ai créé un système de tests flexible qui :

#### 3.1. Compile l'outil de comparaison
```cmake
add_executable(compare_images compare_images.cpp)
target_include_directories(compare_images PRIVATE ${PROJECT_SOURCE_DIR}/src/lodepng)
target_link_libraries(compare_images PRIVATE lodepng)
```

#### 3.2. Génère un script CMake réutilisable (`run_test.cmake`)
Ce script automatise :
- L'exécution du raytracer avec la scène de test
- L'extraction du temps d'exécution depuis la sortie du programme
- L'enregistrement des métriques dans un fichier CSV
- La comparaison de l'image générée avec l'image de référence (si fournie)

#### 3.3. Crée une macro pour ajouter facilement des tests
```cmake
macro(add_raytracer_test TEST_NAME SCENE_FILE REF_FILE)
```
Cette macro simplifie l'ajout de nouveaux tests en gérant automatiquement :
- La configuration du test CTest
- Les chemins vers les exécutables
- La génération du fichier de métriques

#### 3.4. Initialise le fichier de métriques
Le système crée automatiquement un fichier `metrics.csv` avec l'en-tête approprié si il n'existe pas déjà.

### 4. Ajout des tests

J'ai implémenté plusieurs tests pour couvrir différents scénarios :

#### Tests fonctionnels
- **EndToEnd_TwoSpheres** : Test avec deux sphères sur un plan
- **EndToEnd_Monkey** : Test avec un modèle 3D de singe
- **EndToEnd_TwoTriangles** : Test avec deux triangles

#### Cas limite
- **EdgeCase_Empty** : Test avec une scène vide (pas de comparaison d'image)

#### Test de régression
- **EndToEnd_FailureDemo** : Démonstration d'un test qui échoue intentionnellement pour valider le système de détection d'erreurs

### 5. Création de scène de test supplémentaire

J'ai créé `scenes/edge-case-empty.json` pour tester le comportement avec une scène vide (16x16 pixels, aucun objet, aucune lumière).

## Commandes pour exécuter

### Construction du projet

```bash
# Nettoyer les anciens fichiers de build (optionnel)
rm -rf build CMakeCache.txt CMakeFiles

# Créer le répertoire de build et configurer CMake
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

# Compiler le projet
cmake --build build -j4
```

### Exécuter tous les tests

```bash
# Depuis le répertoire racine du projet
ctest --test-dir build

# Avec affichage détaillé
ctest --test-dir build --output-on-failure
```

### Exécuter un test spécifique

```bash
# Test avec deux sphères
ctest --test-dir build -R EndToEnd_TwoSpheres

# Test avec le singe
ctest --test-dir build -R EndToEnd_Monkey

# Test avec deux triangles
ctest --test-dir build -R EndToEnd_TwoTriangles

# Cas limite (scène vide)
ctest --test-dir build -R EdgeCase_Empty
```

### Exécuter le raytracer manuellement

```bash
# Depuis le répertoire build
./build/raytracer ../scenes/two-spheres-on-plane.json output.png
```

### Consulter les métriques de performance

Les métriques sont enregistrées dans `build/metrics.csv` :

```bash
# Afficher le contenu du fichier de métriques
cat build/metrics.csv
```

Le fichier contient :
- Le nom du test
- Le temps d'exécution en secondes

Exemple de format :
```
TestName,DurationSeconds
EndToEnd_TwoSpheres,8.487
EndToEnd_Monkey,1003.250
```

## Structure des fichiers créés/modifiés

### Fichiers créés
- `tests/compare_images.cpp` : Utilitaire de comparaison d'images
- `tests/CMakeLists.txt` : Configuration des tests
- `tests/run_test.cmake` : Script CMake généré pour exécuter les tests
- `scenes/edge-case-empty.json` : Scène de test pour cas limite

### Fichiers modifiés
- `CMakeLists.txt` : Ajout de `enable_testing()` et `add_subdirectory(tests)`

## Architecture du système de tests

1. **Exécution du raytracer** : Le test lance le raytracer avec la scène spécifiée
2. **Collecte des métriques** : Le temps d'exécution est extrait de la sortie standard et enregistré
3. **Comparaison d'images** : Si une image de référence est fournie, `compare_images` vérifie que les images correspondent
4. **Rapport de résultat** : CMake/CTest gère les résultats et les rapports

## Utilisation pratique

Pour ajouter un nouveau test, il suffit d'ajouter un appel à la macro dans `tests/CMakeLists.txt` :

```cmake
add_raytracer_test(NomDuTest 
    ${PROJECT_SOURCE_DIR}/scenes/ma-scene.json 
    ${PROJECT_SOURCE_DIR}/readme/ma-reference.png
)
```

Le système s'occupe automatiquement de :
- Configurer le test
- Gérer les chemins
- Enregistrer les métriques
- Comparer les images

## Notes importantes

- Les images de référence doivent être dans le répertoire `readme/`
- Les scènes de test doivent être dans le répertoire `scenes/`
- Le fichier de métriques est créé dans le répertoire de build (`build/metrics.csv`)
- Pour un test sans comparaison d'image, passer une chaîne vide `""` comme troisième paramètre

