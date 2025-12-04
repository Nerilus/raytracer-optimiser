# Guide : Quand et Comment Exécuter les Tests

## 📋 Quand exécuter les tests ?

### ✅ Scénarios où vous DEVEZ exécuter les tests :

1. **Après avoir modifié le code du raytracer**
   - Après toute modification dans `src/`
   - Après avoir optimisé du code
   - Pour vérifier que rien n'est cassé

2. **Avant de commiter vos changements**
   - Pour s'assurer que tout fonctionne
   - Pour éviter de casser le code pour les autres

3. **Après avoir modifié une scène de test**
   - Si vous changez `scenes/*.json`
   - Vous devrez peut-être régénérer les images de référence

4. **Après avoir recompilé le projet**
   - Pour vérifier que la compilation est correcte

5. **Pendant l'optimisation**
   - Pour mesurer l'amélioration de performance
   - Vérifier que les optimisations n'ont pas cassé le rendu

### ⚡ Tests rapides (recommandés pour le développement)

Pour un feedback rapide pendant le développement :

```bash
cd build
ctest -R "EdgeCase_Empty|EndToEnd_TwoSpheres|EndToEnd_TwoTriangles"
```

**Temps d'exécution : ~4-5 secondes**

### 🐌 Tests complets (avant commit ou release)

```bash
cd build
ctest --output-on-failure
```

**⚠️ Attention :** Le test `EndToEnd_Monkey` prend plus de 1000 secondes (16+ minutes) !

Pour exclure le test Monkey :

```bash
cd build
ctest -E EndToEnd_Monkey --output-on-failure
```

## 🚀 Commandes rapides

### 1. Tous les tests rapides (sans Monkey)

```bash
cd build
ctest -R "EdgeCase_Empty|EndToEnd_TwoSpheres|EndToEnd_TwoTriangles|EndToEnd_FailureDemo"
```

### 2. Un seul test spécifique

```bash
cd build
ctest -R EndToEnd_TwoSpheres --output-on-failure
```

### 3. Lister tous les tests disponibles

```bash
cd build
ctest -N
```

### 4. Voir les métriques de performance

```bash
cat build/metrics.csv
```

## 📝 Checklist avant de commiter

- [ ] Les tests rapides passent (`ctest -R "EdgeCase_Empty|EndToEnd_TwoSpheres|EndToEnd_TwoTriangles"`)
- [ ] Aucune erreur de compilation
- [ ] Les images générées correspondent aux références
- [ ] Les métriques de performance sont enregistrées

## 🎯 Workflow recommandé

### Pendant le développement

1. **Modifier le code**
2. **Recompiler** : `cmake --build build`
3. **Tests rapides** : `cd build && ctest -R "EdgeCase_Empty|EndToEnd_TwoSpheres"`
4. **Vérifier les résultats**
5. **Corriger si nécessaire**

### Avant un commit

1. **Tests complets** (sans Monkey) : `cd build && ctest -E EndToEnd_Monkey --output-on-failure`
2. **Vérifier les métriques** : `cat build/metrics.csv`
3. **Commit si tout passe**

### Pour mesurer les performances

1. **Exécuter les tests** : `cd build && ctest -R "EndToEnd_TwoSpheres|EndToEnd_TwoTriangles"`
2. **Consulter les métriques** : `cat build/metrics.csv`
3. **Comparer avec les résultats précédents**

## ⚙️ Configuration des tests

### Durées approximatives

| Test | Durée | Description |
|------|-------|-------------|
| `EdgeCase_Empty` | ~0.04s | Très rapide (scène vide) |
| `EndToEnd_TwoSpheres` | ~2-3s | Test standard |
| `EndToEnd_TwoTriangles` | ~2-3s | Test standard |
| `EndToEnd_FailureDemo` | ~3s | Test de régression |
| `EndToEnd_Monkey` | >1000s | ⚠️ Très long (peut être ignoré) |

### Timeouts

- Les tests normaux ont un timeout par défaut
- `EndToEnd_Monkey` a un timeout de 3600 secondes (1 heure)

## 🔧 Dépannage

### Un test échoue ?

1. **Vérifier les messages d'erreur** : `ctest --output-on-failure`
2. **Vérifier que les fichiers de référence existent** dans `readme/`
3. **Régénérer l'image de référence si nécessaire** :
   ```bash
   cd build
   ./raytracer ../scenes/nom-scene.json ../readme/nom-reference.png
   ```

### Le test Monkey bloque ?

C'est normal, il est très long. Excluez-le :
```bash
cd build
ctest -E EndToEnd_Monkey
```

### Image différente mais visuellement correcte ?

Si l'image générée est visuellement correcte mais le test échoue, vous pouvez :
1. Régénérer l'image de référence
2. Augmenter la tolérance dans `tests/CMakeLists.txt`

## 💡 Astuces

- Utilisez les tests rapides pendant le développement
- Exécutez les tests complets seulement avant les commits importants
- Le test Monkey peut être ignoré sauf pour les tests finaux
- Consultez `build/metrics.csv` pour suivre l'évolution des performances


