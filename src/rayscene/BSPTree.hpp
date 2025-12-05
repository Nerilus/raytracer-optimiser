#pragma once

#include <vector>
#include "../raymath/AABB.hpp"
#include "../raymath/Ray.hpp"
#include "SceneObject.hpp"
#include "Intersection.hpp"

/**
 * Nœud d'un arbre BSP (Binary Space Partitioning)
 */
class BSPNode
{
public:
    AABB bounds;                           // Boîte englobante de ce nœud
    int axis;                              // Axe de séparation (0=X, 1=Y, 2=Z)
    double splitPos;                       // Position du plan de séparation
    BSPNode* left;                         // Sous-espace gauche (valeurs inférieures)
    BSPNode* right;                        // Sous-espace droit (valeurs supérieures)
    std::vector<SceneObject*> objects;     // Objets dans ce nœud (si feuille)
    bool isLeaf;                           // Est-ce une feuille ?

    BSPNode();
    ~BSPNode();
};

/**
 * Arbre BSP pour accélérer les tests d'intersection rayon-scène
 */
class BSPTree
{
private:
    BSPNode* root;
    int maxDepth;        // Profondeur maximale de l'arbre
    int maxObjectsPerLeaf; // Nombre maximal d'objets par feuille

    /**
     * Construit récursivement le BSP
     */
    BSPNode* buildRecursive(std::vector<SceneObject*>& objects, AABB bounds, int depth);

    /**
     * Choisit le meilleur axe et position pour diviser l'espace
     */
    void chooseSplit(std::vector<SceneObject*>& objects, AABB bounds, int& axis, double& splitPos);

    /**
     * Traverse récursivement le BSP pour trouver l'intersection la plus proche
     */
    bool traverseRecursive(BSPNode* node, Ray& r, Intersection& closest, double& closestDistSq, CullingType culling);

public:
    BSPTree(int maxDepth = 20, int maxObjectsPerLeaf = 5);
    ~BSPTree();

    /**
     * Construit l'arbre BSP à partir d'une liste d'objets
     */
    void build(std::vector<SceneObject*>& objects);

    /**
     * Trouve l'intersection la plus proche avec un rayon
     * Retourne true si une intersection est trouvée
     */
    bool findClosestIntersection(Ray& r, Intersection& closest, CullingType culling);

    /**
     * Retourne la racine de l'arbre (pour debug)
     */
    BSPNode* getRoot() { return root; }
};

