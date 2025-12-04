#include <iostream>
#include <cmath>
#include "Camera.hpp"
#include "../raymath/Ray.hpp"

#ifdef ENABLE_THREADING
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
}

void Camera::render(Image &image, Scene &scene)
{

  double ratio = (double)image.width / (double)image.height;
  double height = 1.0 / ratio;

  double intervalX = 1.0 / (double)image.width;
  double intervalY = height / (double)image.height;

  scene.prepare();

#ifdef ENABLE_THREADING
  // Multithreading: Diviser l'image en sections et créer un thread par section
  unsigned int numThreads = std::thread::hardware_concurrency();
  if (numThreads == 0) {
    numThreads = 4; // Fallback si hardware_concurrency() retourne 0
  }
  
  // Calculer le nombre de lignes par thread
  int rowsPerThread = image.height / numThreads;
  if (rowsPerThread == 0) {
    rowsPerThread = 1; // Au moins 1 ligne par thread
  }
  
  std::vector<std::thread> threads;
  std::vector<RenderSegment*> segments;
  
  // Créer les segments et les threads
  for (unsigned int i = 0; i < numThreads; ++i) {
    RenderSegment *seg = new RenderSegment();
    seg->height = height;
    seg->image = &image;
    seg->scene = &scene;
    seg->intervalX = intervalX;
    seg->intervalY = intervalY;
    seg->reflections = Reflections;
    
    // Calculer les limites de chaque segment
    seg->rowMin = i * rowsPerThread;
    if (i == numThreads - 1) {
      // Le dernier thread prend toutes les lignes restantes
      seg->rowMax = image.height;
    } else {
      seg->rowMax = (i + 1) * rowsPerThread;
    }
    
    segments.push_back(seg);
    
    // Créer et démarrer le thread
    threads.push_back(std::thread(renderSegment, seg));
  }
  
  // Attendre que tous les threads terminent
  for (auto& thread : threads) {
    thread.join();
  }
  
  // Libérer la mémoire des segments
  for (auto* seg : segments) {
    delete seg;
  }
#else
  // Version sans threading (comportement original)
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
  delete seg;
#endif
}

std::ostream &operator<<(std::ostream &_stream, Camera &cam)
{
  Vector3 pos = cam.getPosition();
  return _stream << "Camera(" << pos << ")";
}
