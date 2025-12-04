#include <iostream>
#include <cmath>
#include "Sphere.hpp"
#include "../raymath/Vector3.hpp"

Sphere::Sphere(double r) : SceneObject(), radius(r)
{
}

Sphere::~Sphere()
{
}

void Sphere::applyTransform()
{
  Vector3 c;
  this->center = this->transform.apply(c);
}

// Fonction countPrimes supprimée (Optimisation #1)

bool Sphere::intersects(Ray &r, Intersection &intersection, CullingType culling)
{
  Vector3 OC = center - r.GetPosition();
  Vector3 OP = OC.projectOn(r.GetDirection());

  if (OP.dot(r.GetDirection()) <= 0)
  {
    return false;
  }

  Vector3 P = r.GetPosition() + OP;
  Vector3 CP = P - center;

  // OPTIMISATION #2 : On utilise la distance au carré pour éviter sqrt()
  double distSquared = CP.lengthSquared();
  if (distSquared > radius * radius)
  {
    return false;
  }

  // CORRECTION DE L'ERREUR : On utilise 'distSquared' au lieu de 'distance * distance'
  double a = sqrt(radius * radius - distSquared);
  double t = OP.length() - a;
  Vector3 P1 = r.GetPosition() + (r.GetDirection() * t);

  intersection.Position = P1;
  intersection.Mat = this->material;
  intersection.Normal = (P1 - center).normalize();

  // countPrimes(); <-- Supprimé

  return true;
}