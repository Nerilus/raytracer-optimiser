#include "BSPTree.hpp"
#include <algorithm>
#include <limits>
#include <cmath>

// ======================================
// BSPNode Implementation
// ======================================

BSPNode::BSPNode() 
    : axis(0), splitPos(0.0), left(nullptr), right(nullptr), isLeaf(false)
{
}

BSPNode::~BSPNode()
{
    if (left) delete left;
    if (right) delete right;
    // Note: on ne delete pas les objets car ils appartiennent à la scène
}

// ======================================
// BSPTree Implementation
// ======================================

BSPTree::BSPTree(int maxDepth, int maxObjectsPerLeaf)
    : root(nullptr), maxDepth(maxDepth), maxObjectsPerLeaf(maxObjectsPerLeaf)
{
}

BSPTree::~BSPTree()
{
    if (root) delete root;
}

void BSPTree::build(std::vector<SceneObject*>& objects)
{
    if (objects.empty())
    {
        root = nullptr;
        return;
    }

    // Calculer la boîte englobante de tous les objets
    AABB sceneBounds = objects[0]->getAABB();
    for (size_t i = 1; i < objects.size(); ++i)
    {
        sceneBounds.subsume(objects[i]->getAABB());
    }

    // Construire l'arbre récursivement
    root = buildRecursive(objects, sceneBounds, 0);
}

BSPNode* BSPTree::buildRecursive(std::vector<SceneObject*>& objects, AABB bounds, int depth)
{
    BSPNode* node = new BSPNode();
    node->bounds = bounds;

    // Condition d'arrêt : créer une feuille si :
    // - Trop peu d'objets
    // - Profondeur maximale atteinte
    if (objects.size() <= maxObjectsPerLeaf || depth >= maxDepth)
    {
        node->isLeaf = true;
        node->objects = objects;
        return node;
    }

    // Choisir l'axe et la position de séparation
    int axis;
    double splitPos;
    chooseSplit(objects, bounds, axis, splitPos);

    node->axis = axis;
    node->splitPos = splitPos;
    node->isLeaf = false;

    // Séparer les objets en deux groupes
    std::vector<SceneObject*> leftObjects;
    std::vector<SceneObject*> rightObjects;

    for (SceneObject* obj : objects)
    {
        AABB objBox = obj->getAABB();
        Vector3 center = objBox.getCenter();
        
        double centerPos;
        if (axis == 0) centerPos = center.x;
        else if (axis == 1) centerPos = center.y;
        else centerPos = center.z;

        // Si l'objet chevauche le plan, on le met des deux côtés
        if (centerPos < splitPos)
            leftObjects.push_back(obj);
        else
            rightObjects.push_back(obj);
    }

    // Si la séparation n'a pas fonctionné, créer une feuille
    if (leftObjects.empty() || rightObjects.empty())
    {
        node->isLeaf = true;
        node->objects = objects;
        return node;
    }

    // Calculer les boîtes englobantes des sous-espaces
    AABB leftBounds = bounds;
    AABB rightBounds = bounds;

    if (axis == 0) // X
    {
        leftBounds.setMaxX(splitPos);
        rightBounds.setMinX(splitPos);
    }
    else if (axis == 1) // Y
    {
        leftBounds.setMaxY(splitPos);
        rightBounds.setMinY(splitPos);
    }
    else // Z
    {
        leftBounds.setMaxZ(splitPos);
        rightBounds.setMinZ(splitPos);
    }

    // Créer récursivement les sous-arbres
    node->left = buildRecursive(leftObjects, leftBounds, depth + 1);
    node->right = buildRecursive(rightObjects, rightBounds, depth + 1);

    return node;
}

void BSPTree::chooseSplit(std::vector<SceneObject*>& objects, AABB bounds, int& axis, double& splitPos)
{
    // Stratégie simple : choisir l'axe le plus long et couper au milieu
    Vector3 size = bounds.getSize();
    
    if (size.x >= size.y && size.x >= size.z)
        axis = 0; // X
    else if (size.y >= size.z)
        axis = 1; // Y
    else
        axis = 2; // Z

    // Position de coupe : milieu de la boîte
    Vector3 center = bounds.getCenter();
    if (axis == 0) splitPos = center.x;
    else if (axis == 1) splitPos = center.y;
    else splitPos = center.z;
}

bool BSPTree::findClosestIntersection(Ray& r, Intersection& closest, CullingType culling)
{
    if (!root) return false;

    double closestDistSq = -1;
    return traverseRecursive(root, r, closest, closestDistSq, culling);
}

bool BSPTree::traverseRecursive(BSPNode* node, Ray& r, Intersection& closest, double& closestDistSq, CullingType culling)
{
    if (!node) return false;

    // Test d'intersection avec la boîte englobante du nœud
    if (!node->bounds.intersects(r))
        return false;

    // Si c'est une feuille, tester tous les objets
    if (node->isLeaf)
    {
        bool foundIntersection = false;
        Intersection tempIntersection;

        for (SceneObject* obj : node->objects)
        {
            if (obj->intersects(r, tempIntersection, culling))
            {
                double distSq = (tempIntersection.Position - r.GetPosition()).lengthSquared();

                if (closestDistSq < 0 || distSq < closestDistSq)
                {
                    closestDistSq = distSq;
                    closest = tempIntersection;
                    closest.Distance = std::sqrt(distSq);
                    foundIntersection = true;
                }
            }
        }

        return foundIntersection;
    }

    // Nœud interne : traverser les enfants dans l'ordre approprié
    // Déterminer de quel côté du plan se trouve l'origine du rayon
    Vector3 rayOrigin = r.GetPosition();
    double rayOriginPos;
    
    if (node->axis == 0) rayOriginPos = rayOrigin.x;
    else if (node->axis == 1) rayOriginPos = rayOrigin.y;
    else rayOriginPos = rayOrigin.z;

    BSPNode* nearNode;
    BSPNode* farNode;

    if (rayOriginPos < node->splitPos)
    {
        nearNode = node->left;
        farNode = node->right;
    }
    else
    {
        nearNode = node->right;
        farNode = node->left;
    }

    // Traverser d'abord le côté proche
    bool foundNear = traverseRecursive(nearNode, r, closest, closestDistSq, culling);

    // Traverser le côté lointain seulement si nécessaire
    bool foundFar = traverseRecursive(farNode, r, closest, closestDistSq, culling);

    return foundNear || foundFar;
}

