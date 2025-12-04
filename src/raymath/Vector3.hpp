#pragma once

#include <iostream>
#include <cmath>

#define COMPARE_ERROR_CONSTANT 0.000001

class Vector3
{
public:
  double x = 0;
  double y = 0;
  double z = 0;

  // --- CONSTRUCTEURS (Code intégré ici) ---
  Vector3() : x(0), y(0), z(0) {}
  
  Vector3(double iX, double iY, double iZ) : x(iX), y(iY), z(iZ) {}
  
  ~Vector3() {}

  // --- OPÉRATEURS (Code intégré ici) ---
  
  inline Vector3 operator+(Vector3 const &vec) const {
    return Vector3(x + vec.x, y + vec.y, z + vec.z);
  }

  inline Vector3 operator-(Vector3 const &vec) const {
    return Vector3(x - vec.x, y - vec.y, z - vec.z);
  }

  inline Vector3 operator*(double const &f) const {
    return Vector3(x * f, y * f, z * f);
  }

  inline Vector3 operator/(double const &f) const {
    return Vector3(x / f, y / f, z / f);
  }

  inline Vector3 &operator=(Vector3 const &vec) {
    x = vec.x;
    y = vec.y;
    z = vec.z;
    return *this;
  }

  // --- MÉTHODES (Code intégré ici) ---

  inline double lengthSquared() const {
    return (x * x + y * y + z * z);
  }

  inline double length() const {
    return std::sqrt(lengthSquared());
  }

  inline Vector3 normalize() const {
    double l = length();
    if (l == 0) return Vector3();
    return *this / l;
  }

  inline double dot(Vector3 const &vec) const {
    return (x * vec.x + y * vec.y + z * vec.z);
  }

  inline Vector3 projectOn(Vector3 const &vec) const {
    return vec * this->dot(vec);
  }

  inline Vector3 reflect(Vector3 const &normal) const {
    Vector3 proj = this->projectOn(normal) * -2;
    return proj + *this;
  }

  inline Vector3 cross(Vector3 const &b) const {
    return Vector3(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x);
  }

  inline Vector3 inverse() const {
    return Vector3(1.0 / x, 1.0 / y, 1.0 / z);
  }

  friend std::ostream &operator<<(std::ostream &_stream, Vector3 const &vec) {
    return _stream << "(" << vec.x << "," << vec.y << "," << vec.z << ")";
  }
};