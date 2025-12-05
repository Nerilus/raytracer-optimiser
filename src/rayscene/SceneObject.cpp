#include <iostream>
#include "SceneObject.hpp"
#include "Intersection.hpp"

SceneObject::SceneObject() : material(NULL)
{
}

SceneObject::~SceneObject()
{
}

bool SceneObject::intersects(Ray &r, Intersection &intersection, CullingType culling)
{
  return false;
}

void SceneObject::applyTransform()
{
}

AABB SceneObject::getAABB()
{
  // Implémentation par défaut : boîte vide
  return AABB(Vector3(0, 0, 0), Vector3(0, 0, 0));
}
