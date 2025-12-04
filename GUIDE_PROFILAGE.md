# Guide Complet : Profilage et Optimisation

## 🎯 Vue d'ensemble

Ce guide vous accompagne dans le processus complet d'optimisation selon les 5 étapes de la méthodologie.

---

## 📋 Prérequis

### Installation des outils

Exécutez une seule fois pour installer tous les outils nécessaires :

```bash
./install_profiling_tools.sh
```

Cela installe :
- ✅ Valgrind (profilage)
- ✅ Python3 + pip
- ✅ graphviz (génération de graphiques)
- ✅ gprof2dot (conversion callgrind → graphique)

---

## 🚀 Workflow Complet (Recommandé)

Pour exécuter toutes les étapes automatiquement :

```bash
./workflow_optimisation.sh [scene.json]
```

**Exemple :**
```bash
./workflow_optimisation.sh scenes/two-spheres-on-plane.json
```

Ce script vous guide à travers les 5 étapes et vous demande confirmation aux étapes importantes.

---

## 📊 Les 5 Étapes en Détail

### Étape 1 : Mesurer

#### 1.1 Mesure du temps d'exécution

Le temps est déjà mesuré automatiquement dans `main.cpp`, mais vous pouvez le mesurer manuellement :

```bash
./build/raytracer scenes/two-spheres-on-plane.json output.png
```

Le temps est affiché à la fin : `Total time: X.XXX seconds.`

#### 1.2 Profilage avec Valgrind/Callgrind

Créer le profil initial (AVANT optimisations) :

```bash
./profile_initial.sh [scene.json]
```

**Exemple :**
```bash
./profile_initial.sh scenes/two-spheres-on-plane.json
```

**⚠️ Important :** Le profilage avec Valgrind est **10-50x plus lent** que l'exécution normale. Cela peut prendre plusieurs minutes même pour une scène simple.

**Fichiers générés :**
- `profiling/initial/callgrind.out` - Données de profilage
- `profiling/initial/report.txt` - Rapport textuel
- `profiling/initial/output.png` - Image générée
- `profiling/initial/metrics.csv` - Métriques de temps

#### 1.3 Génération des graphiques visuels

```bash
./generate_profile_graph.sh initial
```

**Fichiers générés :**
- `profiling/initial/profile_graph.png` - Graphique PNG
- `profiling/initial/profile_graph.svg` - Graphique SVG (vectoriel)

---

### Étape 2 : Analyser

#### 2.1 Consulter le rapport textuel

```bash
cat profiling/initial/report.txt | head -50
```

Le rapport montre les fonctions les plus coûteuses avec :
- Le nombre d'instructions
- Le pourcentage du temps total
- Les appels de fonctions

#### 2.2 Visualiser le graphique

Ouvrez le graphique généré :

```bash
# Sur Linux avec image viewer
xdg-open profiling/initial/profile_graph.png

# Ou copiez-le pour le visualiser ailleurs
```

Le graphique montre la hiérarchie des appels de fonctions avec les temps d'exécution.

#### 2.3 Problèmes identifiés

Consultez `EVALUATION2_PLAN.md` pour la liste complète des problèmes identifiés :

1. **countPrimes() inutile** - Très impactant
2. **sqrt() inutiles** - Élevé
3. **Divisions coûteuses** - Moyen
4. **Opérateur logique incorrect** - Faible mais important

---

### Étape 3 : Répondre (Optimiser)

⚠️ **Cette étape nécessite de modifier le code manuellement.**

Suivez les instructions dans `EVALUATION2_PLAN.md` pour implémenter les optimisations.

**Ordre recommandé :**

1. **Opt 1** : Supprimer countPrimes() (~5 min)
   - Fichier : `src/rayscene/Sphere.cpp`
   - Supprimer la fonction et son appel

2. **Opt 2** : Éviter sqrt() dans Sphere::intersects() (~30 min)
   - Remplacer `length()` par `lengthSquared()`
   - Comparer avec `radius * radius`

3. **Opt 3** : Éviter sqrt() dans Scene::closestIntersection() (~30 min)
   - Utiliser `lengthSquared()` pour comparer les distances

4. **Opt 4** : Optimiser Vector3::normalize() (~20 min)
   - Calculer l'inverse une fois et multiplier

5. **Opt 5** : Corriger opérateur logique (~5 min)
   - Remplacer `&` par `&&`

6. **Opt 6** : Optimiser Camera::render() (~20 min)
   - Précalculer les inverses

**Après chaque optimisation :**

```bash
# 1. Recompiler
cmake --build build

# 2. Tester
./run_tests.sh rapide

# 3. Vérifier que les images restent identiques
```

---

### Étape 4 : Tester

#### 4.1 Tests rapides (recommandé)

```bash
./run_tests.sh rapide
```

Ou manuellement :
```bash
cd build
ctest -R "EdgeCase_Empty|EndToEnd_TwoSpheres|EndToEnd_TwoTriangles" --output-on-failure
```

#### 4.2 Vérifier les images

Les tests comparent automatiquement les images générées avec les références. Si un test échoue, vérifiez :

1. Que l'image est visuellement correcte
2. Si oui, régénérez la référence :
   ```bash
   ./build/raytracer scenes/nom-scene.json readme/nom-reference.png
   ```

#### 4.3 Tests complets

```bash
./run_tests.sh complet
```

---

### Étape 5 : Mesurer et Répéter

#### 5.1 Mesure du temps final

```bash
./build/raytracer scenes/two-spheres-on-plane.json output.png
```

Notez le temps et comparez avec le temps initial.

#### 5.2 Profilage final

Créer le profil final (APRÈS optimisations) :

```bash
./profile_final.sh [scene.json]
```

#### 5.3 Génération des graphiques finaux

```bash
./generate_profile_graph.sh final
```

#### 5.4 Comparaison des profils

```bash
./compare_profiles.sh
```

Ce script génère un rapport de comparaison avec :
- Temps initial vs final
- Pourcentage d'amélioration
- Accélération (speedup)
- Comparaison des top fonctions

**Fichier généré :**
- `profiling/comparison.txt` - Rapport de comparaison complet

---

## 📊 Exemple de Résultats Attendus

### Avant optimisation

```
Temps initial: 2.586s
Top fonctions:
  1. countPrimes() - 45%
  2. sqrt() calls - 25%
  3. Scene::closestIntersection() - 15%
```

### Après optimisation

```
Temps final: 0.647s
Amélioration: 75%
Accélération: 4.0x
Top fonctions:
  1. Scene::closestIntersection() - 30%
  2. Material::render() - 20%
  3. Ray::intersects() - 15%
```

---

## 🛠️ Scripts Disponibles

| Script | Description |
|--------|-------------|
| `install_profiling_tools.sh` | Installe tous les outils nécessaires |
| `profile_initial.sh` | Crée le profil initial (avant optimisations) |
| `profile_final.sh` | Crée le profil final (après optimisations) |
| `generate_profile_graph.sh` | Génère les graphiques visuels |
| `compare_profiles.sh` | Compare les profils initial et final |
| `workflow_optimisation.sh` | **Workflow complet automatisé** |

---

## 📁 Structure des Fichiers

```
profiling/
├── initial/
│   ├── callgrind.out          # Données de profilage
│   ├── report.txt              # Rapport textuel
│   ├── profile_graph.png       # Graphique PNG
│   ├── profile_graph.svg       # Graphique SVG
│   ├── output.png              # Image générée
│   └── metrics.csv             # Métriques de temps
├── final/
│   └── (même structure)
└── comparison.txt              # Rapport de comparaison
```

---

## 💡 Conseils

1. **Commencez simple** : Utilisez `workflow_optimisation.sh` pour la première fois
2. **Profitez des tests** : Exécutez les tests après chaque optimisation
3. **Documentez** : Notez les améliorations dans un fichier
4. **Visualisez** : Les graphiques sont plus parlants que les rapports textuels
5. **Patience** : Le profilage Callgrind est lent mais très utile

---

## ❓ Dépannage

### Valgrind non trouvé

```bash
./install_profiling_tools.sh
```

### Erreur lors de la génération de graphique

Vérifiez que gprof2dot et graphviz sont installés :
```bash
python3 -c "import gprof2dot"
dot -V
```

### Le profilage est trop lent

C'est normal ! Valgrind ralentit l'exécution de 10-50x. Pour une mesure rapide, utilisez seulement la mesure de temps (sans Valgrind).

### Les tests échouent après optimisation

1. Vérifiez que l'image est visuellement correcte
2. Si oui, régénérez la référence
3. Si non, vérifiez votre code d'optimisation

---

## 📚 Ressources

- `EVALUATION2_PLAN.md` - Plan détaillé des optimisations
- `ANALYSE_OPTIMISATION.md` - Analyse de faisabilité
- `GUIDE_TESTS.md` - Guide des tests
- `REPORT.md` - Documentation du système de tests

---

**Bon profilage ! 🚀**


