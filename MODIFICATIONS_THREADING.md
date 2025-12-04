# Modifications apportées pour le Threading

## 📋 Résumé

3 fichiers modifiés pour implémenter le multithreading dans le raytracer.

---

## 1. Fichier : `src/rayscene/Camera.cpp`

### ✅ Ajouts en haut du fichier (lignes 6-9)

**AVANT :**
```cpp
#include <iostream>
#include <cmath>
#include "Camera.hpp"
#include "../raymath/Ray.hpp"
```

**APRÈS :**
```cpp
#include <iostream>
#include <cmath>
#include "Camera.hpp"
#include "../raymath/Ray.hpp"

#ifdef ENABLE_THREADING
#include <thread>
#include <vector>
#endif
```

**Explication** : Ajout des includes nécessaires pour le threading (conditionnel).

---

### ✅ Modification de la fonction `Camera::render()` (lignes 81-144)

**AVANT :**
```cpp
void Camera::render(Image &image, Scene &scene)
{
  double ratio = (double)image.width / (double)image.height;
  double height = 1.0 / ratio;
  double intervalX = 1.0 / (double)image.width;
  double intervalY = height / (double)image.height;
  
  scene.prepare();
  
  RenderSegment *seg = new RenderSegment();
  seg->height = height;
  seg->image = &image;
  seg->scene = &scene;
  seg->intervalX = intervalX;
  seg->intervalY = intervalY;
  seg->reflections = Reflections;
  seg->rowMin = 0;
  seg->rowMax = image.height;
  renderSegment(seg);
}
```

**APRÈS :**
```cpp
void Camera::render(Image &image, Scene &scene)
{
  double ratio = (double)image.width / (double)image.height;
  double height = 1.0 / ratio;
  double intervalX = 1.0 / (double)image.width;
  double intervalY = height / (double)image.height;
  
  scene.prepare();
  
#ifdef ENABLE_THREADING
  // Multithreading: Diviser l'image en sections et créer un thread par section
  unsigned int numThreads = std::thread::hardware_concurrency();
  if (numThreads == 0) {
    numThreads = 4; // Fallback si hardware_concurrency() retourne 0
  }
  
  // Calculer le nombre de lignes par thread
  int rowsPerThread = image.height / numThreads;
  if (rowsPerThread == 0) {
    rowsPerThread = 1; // Au moins 1 ligne par thread
  }
  
  std::vector<std::thread> threads;
  std::vector<RenderSegment*> segments;
  
  // Créer les segments et les threads
  for (unsigned int i = 0; i < numThreads; ++i) {
    RenderSegment *seg = new RenderSegment();
    seg->height = height;
    seg->image = &image;
    seg->scene = &scene;
    seg->intervalX = intervalX;
    seg->intervalY = intervalY;
    seg->reflections = Reflections;
    
    // Calculer les limites de chaque segment
    seg->rowMin = i * rowsPerThread;
    if (i == numThreads - 1) {
      // Le dernier thread prend toutes les lignes restantes
      seg->rowMax = image.height;
    } else {
      seg->rowMax = (i + 1) * rowsPerThread;
    }
    
    segments.push_back(seg);
    
    // Créer et démarrer le thread
    threads.push_back(std::thread(renderSegment, seg));
  }
  
  // Attendre que tous les threads terminent
  for (auto& thread : threads) {
    thread.join();
  }
  
  // Libérer la mémoire des segments
  for (auto* seg : segments) {
    delete seg;
  }
#else
  // Version sans threading (comportement original)
  RenderSegment *seg = new RenderSegment();
  seg->height = height;
  seg->image = &image;
  seg->scene = &scene;
  seg->intervalX = intervalX;
  seg->intervalY = intervalY;
  seg->reflections = Reflections;
  seg->rowMin = 0;
  seg->rowMax = image.height;
  renderSegment(seg);
  delete seg;
#endif
}
```

**Explication** :
- Code conditionnel avec `#ifdef ENABLE_THREADING`
- Avec threading : divise l'image, crée des threads, synchronise avec `join()`
- Sans threading : comportement original préservé
- Ajout de `delete seg;` pour libérer la mémoire

---

## 2. Fichier : `CMakeLists.txt`

### ✅ Ajouts (lignes 7-16)

**AVANT :**
```cmake
cmake_minimum_required(VERSION 3.5.0)
project(raytracer VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

add_executable(raytracer main.cpp)
```

**APRÈS :**
```cmake
cmake_minimum_required(VERSION 3.5.0)
project(raytracer VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Option pour activer/désactiver le threading
option(ENABLE_THREADING "Enable multithreading for rendering" OFF)

# Si le threading est activé, ajouter la définition du compilateur
if(ENABLE_THREADING)
  add_compile_definitions(ENABLE_THREADING)
  message(STATUS "Multithreading activé")
else()
  message(STATUS "Multithreading désactivé")
endif()

add_executable(raytracer main.cpp)
```

**Explication** :
- Ajout de l'option CMake `ENABLE_THREADING` (OFF par défaut)
- Utilisation de `add_compile_definitions(ENABLE_THREADING)` pour définir la macro
- Messages de statut pour informer l'utilisateur

---

## 3. Fichier : `src/rayscene/CMakeLists.txt`

### ✅ Ajouts (lignes 17-23)

**AVANT :**
```cmake
add_library(rayscene 
  ${CMAKE_CURRENT_SOURCE_DIR}/Camera.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Scene.cpp
  # ... autres fichiers ...
)
```

**APRÈS :**
```cmake
add_library(rayscene 
  ${CMAKE_CURRENT_SOURCE_DIR}/Camera.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Scene.cpp
  # ... autres fichiers ...
)

# Si le threading est activé, propager la définition
if(ENABLE_THREADING)
  target_compile_definitions(rayscene PRIVATE ENABLE_THREADING)
  # Trouver la bibliothèque de threading (pthread sur Linux)
  find_package(Threads REQUIRED)
  target_link_libraries(rayscene PRIVATE Threads::Threads)
endif()
```

**Explication** :
- Propagation de la définition `ENABLE_THREADING` à la bibliothèque `rayscene`
- Recherche et lien avec la bibliothèque `Threads` (pthread sur Linux)

---

## 📊 Récapitulatif des modifications

| Fichier | Type de modification | Lignes ajoutées | Lignes modifiées |
|---------|---------------------|-----------------|------------------|
| `src/rayscene/Camera.cpp` | Ajout code threading | ~60 | ~10 |
| `CMakeLists.txt` | Ajout option CMake | ~9 | 0 |
| `src/rayscene/CMakeLists.txt` | Ajout configuration threading | ~6 | 0 |

**Total** : ~75 lignes ajoutées

---

## 🎯 Points clés des modifications

### 1. Code conditionnel
- Utilisation de `#ifdef ENABLE_THREADING` pour activer/désactiver le threading
- Code original préservé dans le bloc `#else`

### 2. Division intelligente
- Utilisation de `std::thread::hardware_concurrency()` pour déterminer le nombre de threads
- Division équitable de l'image par rangées
- Le dernier thread prend les rangées restantes

### 3. Thread-safety
- Chaque thread travaille sur une zone différente (pas de race condition)
- Synchronisation avec `thread.join()` avant la fin du rendu

### 4. Configuration CMake
- Option simple pour activer/désactiver : `-DENABLE_THREADING=ON/OFF`
- Propagation automatique de la définition aux fichiers sources

---

## ✅ Vérification

Pour voir toutes les modifications en détail :

```bash
# Voir les différences dans Camera.cpp
git diff src/rayscene/Camera.cpp

# Voir les différences dans CMakeLists.txt
git diff CMakeLists.txt

# Voir les différences dans rayscene/CMakeLists.txt
git diff src/rayscene/CMakeLists.txt
```

