#pragma once
#include "../raymath/Vector3.hpp"
#include "../raymath/Ray.hpp"

class AABB
{
private:
  Vector3 Min;
  Vector3 Max;

public:
  AABB();
  AABB(Vector3 min, Vector3 max);
  ~AABB();
  AABB &operator=(AABB const &vec);

  /**
   * Grows the AABB to include the one passed as a parameter.
   */
  void subsume(AABB const &other);

  bool intersects(Ray &r);

  // Accesseurs pour la construction du BSP
  Vector3 getMin() const { return Min; }
  Vector3 getMax() const { return Max; }
  Vector3 getCenter() const { return (Min + Max) * 0.5; }
  Vector3 getSize() const { return Max - Min; }

  void setMinX(double x) { Min.x = x; }
  void setMinY(double y) { Min.y = y; }
  void setMinZ(double z) { Min.z = z; }
  void setMaxX(double x) { Max.x = x; }
  void setMaxY(double y) { Max.y = y; }
  void setMaxZ(double z) { Max.z = z; }

  friend std::ostream &operator<<(std::ostream &_stream, AABB const &box);
};
