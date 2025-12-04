#include <iostream>
#include <cmath>
#include "Camera.hpp"
#include "../raymath/Ray.hpp"

// On inclut les librairies de thread seulement si la directive est active
#ifdef ENABLE_MULTITHREADING
#include <thread>
#include <vector>
#endif

struct RenderSegment
{
public:
  int rowMin;
  int rowMax;
  Image *image;
  double height;
  double intervalX;
  double intervalY;
  int reflections;
  Scene *scene;
};

Camera::Camera() : position(Vector3())
{
}

Camera::Camera(Vector3 pos) : position(pos)
{
}

Camera::~Camera()
{
}

Vector3 Camera::getPosition()
{
  return position;
}

void Camera::setPosition(Vector3 &pos)
{
  position = pos;
}

/**
 * Render a segment (set of rows) of the image
 */
void renderSegment(RenderSegment *segment)
{
  // Note: On parcourt de rowMin à rowMax (exclusif)
  for (int y = segment->rowMin; y < segment->rowMax; ++y)
  {
    double yCoord = (segment->height / 2.0) - (y * segment->intervalY);

    for (int x = 0; x < segment->image->width; ++x)
    {
      double xCoord = -0.5 + (x * segment->intervalX);

      Vector3 coord(xCoord, yCoord, 0);
      Vector3 origin(0, 0, -1);
      Ray ray(origin, coord - origin);

      Color pixel = segment->scene->raycast(ray, ray, 0, segment->reflections);
      segment->image->setPixel(x, y, pixel);
    }
  }
  // Nettoyage de la mémoire allouée pour ce segment
  delete segment; 
}

void Camera::render(Image &image, Scene &scene)
{
  double ratio = (double)image.width / (double)image.height;
  double height = 1.0 / ratio;

  double intervalX = 1.0 / (double)image.width;
  double intervalY = height / (double)image.height;

  scene.prepare();

#ifdef ENABLE_MULTITHREADING
  // --- MODE MULTITHREADING ---
  
  // Détecter le nombre de coeurs logiques disponibles (ex: 8, 12, 16...)
  unsigned int numThreads = std::thread::hardware_concurrency();
  if (numThreads == 0) numThreads = 4; // Sécurité si la détection échoue

  std::vector<std::thread> threads;
  int rowsPerThread = image.height / numThreads;

  std::cout << "Rendering with " << numThreads << " threads..." << std::endl;

  for (unsigned int i = 0; i < numThreads; ++i)
  {
    // Préparation des données pour le thread
    RenderSegment *seg = new RenderSegment();
    seg->height = height;
    seg->image = &image;
    seg->scene = &scene;
    seg->intervalX = intervalX;
    seg->intervalY = intervalY;
    seg->reflections = Reflections;

    // Découpage : on assigne une tranche de lignes à chaque thread
    seg->rowMin = i * rowsPerThread;
    
    // Si c'est le dernier thread, il prend tout ce qu'il reste (pour gérer les divisions impaires)
    if (i == numThreads - 1) {
        seg->rowMax = image.height;
    } else {
        seg->rowMax = (i + 1) * rowsPerThread;
    }

    // Lancement du thread
    threads.emplace_back(renderSegment, seg);
  }

  // Attendre que tous les threads aient fini (Join)
  for (auto &t : threads)
  {
    if (t.joinable()) {
      t.join();
    }
  }

#else
  // --- MODE SINGLE THREAD (CODE D'ORIGINE) ---
  std::cout << "Rendering single-threaded..." << std::endl;
  RenderSegment *seg = new RenderSegment();
  seg->height = height;
  seg->image = &image;
  seg->scene = &scene;
  seg->intervalX = intervalX;
  seg->intervalY = intervalY;
  seg->reflections = Reflections;
  seg->rowMin = 0;
  seg->rowMax = image.height;
  
  renderSegment(seg);
#endif
}

std::ostream &operator<<(std::ostream &_stream, Camera &cam)
{
  Vector3 pos = cam.getPosition();
  return _stream << "Camera(" << pos << ")";
}