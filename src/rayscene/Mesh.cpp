#include <iostream>
#include "Mesh.hpp"
#include "../raymath/Vector3.hpp"
#include "../objloader/OBJ_Loader.h"
#include <limits>

Mesh::Mesh() : SceneObject()
{
}

Mesh::~Mesh()
{
    for (int i = 0; i < triangles.size(); ++i)
    {
        delete triangles[i];
    }
}

void Mesh::loadFromObj(std::string path)
{

    objl::Loader *loader = new objl::Loader();
    bool loadout = loader->LoadFile(path);

    if (loadout)
    {
        for (int i = 0; i < loader->LoadedMeshes.size(); i++)
        {
            objl::Mesh curMesh = loader->LoadedMeshes[i];

            for (int j = 0; j < curMesh.Indices.size(); j += 3)
            {
                Vector3 v1(
                    curMesh.Vertices[curMesh.Indices[j]].Position.X,
                    curMesh.Vertices[curMesh.Indices[j]].Position.Y,
                    curMesh.Vertices[curMesh.Indices[j]].Position.Z);
                Vector3 v2(
                    curMesh.Vertices[curMesh.Indices[j + 1]].Position.X,
                    curMesh.Vertices[curMesh.Indices[j + 1]].Position.Y,
                    curMesh.Vertices[curMesh.Indices[j + 1]].Position.Z);
                Vector3 v3(
                    curMesh.Vertices[curMesh.Indices[j + 2]].Position.X,
                    curMesh.Vertices[curMesh.Indices[j + 2]].Position.Y,
                    curMesh.Vertices[curMesh.Indices[j + 2]].Position.Z);

                Triangle *triangle = new Triangle(
                    v1,
                    v2,
                    v3);
                triangle->name = "T:" + std::to_string(j);
                triangle->ID = j;
                triangles.push_back(triangle);
            }
        }
    }

    this->applyTransform();
    delete loader;
}

void Mesh::applyTransform()
{
    // Initialisation des limites
    double minDouble = std::numeric_limits<double>::lowest();
    double maxDouble = std::numeric_limits<double>::max();
    
    Vector3 minPoint(maxDouble, maxDouble, maxDouble);
    Vector3 maxPoint(minDouble, minDouble, minDouble);

    for (int i = 0; i < triangles.size(); ++i)
    {
        triangles[i]->material = this->material;
        triangles[i]->transform = transform;
        triangles[i]->applyTransform();

        // --- CORRECTION ICI : Utilisez tA, tB, tC ---
        Vector3 v1 = triangles[i]->tA;
        Vector3 v2 = triangles[i]->tB;
        Vector3 v3 = triangles[i]->tC;

        // Le reste de la logique reste identique...
        if (v1.x < minPoint.x) minPoint.x = v1.x;
        if (v1.y < minPoint.y) minPoint.y = v1.y;
        if (v1.z < minPoint.z) minPoint.z = v1.z;
        
        // ... (Faites pareil pour v2 et v3 et pour le maxPoint) ...
        // Je vous remets le bloc complet pour éviter les erreurs :
        
        if (v2.x < minPoint.x) minPoint.x = v2.x;
        if (v2.y < minPoint.y) minPoint.y = v2.y;
        if (v2.z < minPoint.z) minPoint.z = v2.z;

        if (v3.x < minPoint.x) minPoint.x = v3.x;
        if (v3.y < minPoint.y) minPoint.y = v3.y;
        if (v3.z < minPoint.z) minPoint.z = v3.z;

        // Max
        if (v1.x > maxPoint.x) maxPoint.x = v1.x;
        if (v1.y > maxPoint.y) maxPoint.y = v1.y;
        if (v1.z > maxPoint.z) maxPoint.z = v1.z;

        if (v2.x > maxPoint.x) maxPoint.x = v2.x;
        if (v2.y > maxPoint.y) maxPoint.y = v2.y;
        if (v2.z > maxPoint.z) maxPoint.z = v2.z;

        if (v3.x > maxPoint.x) maxPoint.x = v3.x;
        if (v3.y > maxPoint.y) maxPoint.y = v3.y;
        if (v3.z > maxPoint.z) maxPoint.z = v3.z;
    }
    
    this->box = AABB(minPoint, maxPoint);
}
bool Mesh::intersects(Ray &r, Intersection &intersection, CullingType culling)
{
    if (!box.intersects(r)) return false;
    Intersection tInter;

    double closestDistance = -1;
    Intersection closestInter;
    for (int i = 0; i < triangles.size(); ++i)
    {
        if (triangles[i]->intersects(r, tInter, culling))
        {

            tInter.Distance = (tInter.Position - r.GetPosition()).length();
            if (closestDistance < 0 || tInter.Distance < closestDistance)
            {
                closestDistance = tInter.Distance;
                closestInter = tInter;
            }
        }
    }

    if (closestDistance < 0)
    {
        return false;
    }

    intersection = closestInter;
    return true;
}