#include <algorithm>
#include <cmath>
#include <functional>
#include <iostream>
//#include <miopen/float_equal.hpp>
//#include <miopen/returns.hpp>
#include <numeric>


template <typename T>
static T FRAND(void)
{
    double d = static_cast<double>((rand()) / (static_cast<double>(RAND_MAX)));
    return static_cast<T>(d);
}

template <typename T>
static T RAN_GEN(T A, T B)
{
    T r = (FRAND<T>() * (B - A)) + A;
    return r;
}



float sum(float x, float y) { return x + y; }
double square_diff(float x, float y) { return (x - y) * (x - y); }
bool abs_max(float x, float y) { return fabs(x) < fabs(y); }
double verify(float* r1, float* r2, size_t n)
{
    std::vector<float> R1(r1, r1 + n / sizeof(float));
    std::vector<float> R2(r2, r2 + n / sizeof(float));

    size_t r1_d = std::distance(R1.begin(), R1.end());
    if(r1_d == std::distance(R2.begin(), R2.end()))
    {
        double square_difference =
            std::inner_product(R1.begin(), R1.end(), R2.begin(), 0.0, sum, square_diff);
        double r1_max = *std::max_element(R1.begin(), R1.end(), abs_max);
        double r2_max = *std::max_element(R2.begin(), R2.end(), abs_max);

        double mag =
            std::max({std::fabs(r1_max), std::fabs(r2_max), std::numeric_limits<double>::min()});

        double s2=std::sqrt(square_difference);
        double s3 = std::sqrt(r1_d) * mag;
printf(" square_difference %.15f r1_d %d mag %.15f s2 %.15f s3 %15f\n",square_difference,r1_d,mag,s2,s3);
        
        return std::sqrt(square_difference)/(std::sqrt(r1_d) * mag);
        //return static_cast<double>(std::sqrt(square_difference) / (std::sqrt(r1_d) * mag));
    }
    else
        return std::numeric_limits<double>::max();
}
