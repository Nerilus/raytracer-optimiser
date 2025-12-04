#include <iostream>
#include <vector>
#include <string>
#include <cmath>
#include "lodepng.h"

// Returns 0 if images are similar, 1 otherwise
int main(int argc, char* argv[]) {
    // Si on n'a pas d'image de référence (ex: cas limite nouveau), on peut générer une image noire ou juste valider que le fichier existe.
    // Pour l'instant on garde la logique de comparaison.
    
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <image1.png> <image2.png> [tolerance]" << std::endl;
        return 1;
    }

    const char* file1 = argv[1];
    const char* file2 = argv[2];
    double tolerance = 0.0;
    if (argc > 3) {
        tolerance = std::stod(argv[3]);
    }

    std::vector<unsigned char> image1, image2;
    unsigned w1, h1, w2, h2;

    unsigned error1 = lodepng::decode(image1, w1, h1, file1);
    if (error1) {
        std::cerr << "Error loading " << file1 << ": " << lodepng_error_text(error1) << std::endl;
        return 1;
    }

    unsigned error2 = lodepng::decode(image2, w2, h2, file2);
    if (error2) {
        std::cerr << "Error loading " << file2 << ": " << lodepng_error_text(error2) << std::endl;
        return 1;
    }

    if (w1 != w2 || h1 != h2) {
        std::cerr << "Dimensions match failure: " << w1 << "x" << h1 << " vs " << w2 << "x" << h2 << std::endl;
        return 1;
    }

    // Compare pixels
    size_t diff_count = 0;
    size_t total_pixels = w1 * h1;
    
    for (size_t i = 0; i < image1.size(); ++i) {
        int val1 = image1[i];
        int val2 = image2[i];
        if (std::abs(val1 - val2) > tolerance) {
             diff_count++;
        }
    }

    if (diff_count > 0) {
        std::cerr << "FAIL: " << diff_count << " bytes different (Tolerance: " << tolerance << ")" << std::endl;
        return 1;
    }

    std::cout << "SUCCESS: Images match." << std::endl;
    return 0;
}
