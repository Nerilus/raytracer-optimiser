#include <iostream>
#include "Scene.hpp"
#include "Intersection.hpp"
#include <cmath> // Ajouté pour sqrt si nécessaire

Scene::Scene() 
{
#ifdef ENABLE_BSP
  bspTree = nullptr;
#endif
}

Scene::~Scene()
{
  for (int i = 0; i < objects.size(); ++i) delete objects[i];
  for (int i = 0; i < lights.size(); ++i) delete lights[i];
  
#ifdef ENABLE_BSP
  if (bspTree) delete bspTree;
#endif
}

void Scene::add(SceneObject *object) { objects.push_back(object); }
void Scene::addLight(Light *light) { lights.push_back(light); }

void Scene::prepare()
{
  for (int i = 0; i < objects.size(); ++i) objects[i]->applyTransform();

#ifdef ENABLE_BSP
  std::cout << "Building BSP-Tree with " << objects.size() << " objects..." << std::endl;
  bspTree = new BSPTree(20, 5); // maxDepth=20, maxObjectsPerLeaf=5
  bspTree->build(objects);
  std::cout << "BSP-Tree built successfully." << std::endl;
#endif
}

std::vector<Light *> Scene::getLights() { return lights; }

bool Scene::closestIntersection(Ray &r, Intersection &closest, CullingType culling)
{
#ifdef ENABLE_BSP
  // Utiliser le BSP-Tree pour accélérer la recherche
  if (bspTree)
  {
    return bspTree->findClosestIntersection(r, closest, culling);
  }
#endif

  // Fallback : méthode traditionnelle (parcourir tous les objets)
  Intersection intersection;
  double closestDistSq = -1; // On stocke la distance au carré
  Intersection closestInter;

  for (int i = 0; i < objects.size(); ++i)
  {
    if (objects[i]->intersects(r, intersection, culling))
    {
      // OPTIMISATION : lengthSquared() au lieu de length()
      double distSq = (intersection.Position - r.GetPosition()).lengthSquared();

      if (closestDistSq < 0 || distSq < closestDistSq)
      {
        closestDistSq = distSq;
        closestInter = intersection;
        // On calcule la vraie distance seulement si on garde cet objet
        closestInter.Distance = std::sqrt(distSq); 
      }
    }
  }
  closest = closestInter;
  return (closestDistSq > -1);
}

Color Scene::raycast(Ray &r, Ray &camera, int castCount, int maxCastCount)
{
  Color pixel;
  Intersection intersection;

  if (closestIntersection(r, intersection, CULLING_FRONT))
  {
    intersection.View = (camera.GetPosition() - intersection.Position).normalize();

    if (intersection.Mat != NULL)
    {
      pixel = pixel + (intersection.Mat)->render(r, camera, &intersection, this);

      // OPTIMISATION #3 : Remplacement de '&' par '&&' (Logique vs Binaire)
      if (castCount < maxCastCount && intersection.Mat->cReflection > 0)
      {
        Vector3 reflectDir = r.GetDirection().reflect(intersection.Normal);
        Vector3 origin = intersection.Position + (reflectDir * COMPARE_ERROR_CONSTANT);
        Ray reflectRay(origin, reflectDir);

        pixel = pixel + raycast(reflectRay, camera, castCount + 1, maxCastCount) * intersection.Mat->cReflection;
      }
    }
  }
  return pixel;
}