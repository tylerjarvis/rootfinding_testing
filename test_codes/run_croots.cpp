#include <iostream>
#include <fstream>
#include <vector>
#include <cmath>
#include <random>
#include <string>
#include <filesystem>
#include <iomanip>
// Include YRoots library headers (assumed available in the project)
#include "yroots/MultiPower.h"
#include "yroots/Solver.h"

using namespace std;
using yroots::MultiPower;
using yroots::solve;

// Function to generate a random polynomial system for given parameters
static std::vector<MultiPower> generate_polynomials(int dim, int deg, int nonzero,
                                                    std::mt19937 &rng,
                                                    std::normal_distribution<double> &dist,
                                                    std::normal_distribution<double> &dist_const) {
    std::vector<MultiPower> polys;
    polys.reserve(dim);

    // Functor for comparing exponent vectors lexicographically (for uniqueness)
    struct VectorLess {
        bool operator()(const std::vector<int>& a, const std::vector<int>& b) const noexcept {
            // Assumes a.size() == b.size()
            for (size_t i = 0; i < a.size(); ++i) {
                if (a[i] < b[i]) return true;
                if (a[i] > b[i]) return false;
            }
            return false; // equal vectors are not considered "less"
        }
    };

    std::uniform_int_distribution<int> dist_idx(0, deg);
    for (int eq = 0; eq < dim; ++eq) {
        // Initialize a polynomial (dim variables, max degree 'deg')
        MultiPower poly(dim, deg);
        // Use a set to ensure unique monomials
        std::set<std::vector<int>, VectorLess> used_exponents;

        // 1. Add the full-degree monomial [deg, deg, ..., deg]
        std::vector<int> exp_full(dim, deg);
        used_exponents.insert(exp_full);
        double coeff_full = dist(rng);
        poly.setCoefficient(exp_full, coeff_full);

        // 2. Add (nonzero - 1) random monomials with at least one exponent < deg
        while ((int)used_exponents.size() < nonzero) {
            std::vector<int> exp(dim);
            bool all_zero = true;
            bool is_full = true;
            for (int k = 0; k < dim; ++k) {
                exp[k] = dist_idx(rng);
                if (exp[k] != 0) all_zero = false;
                if (exp[k] != deg) is_full = false;
            }
            if (all_zero || is_full) {
                // skip the all-zeros (constant term) or the full-degree (already added)
                continue;
            }
            if (used_exponents.find(exp) != used_exponents.end()) {
                continue; // skip duplicate monomial
            }
            // Add this new monomial term
            used_exponents.insert(exp);
            double coeff = dist(rng);
            poly.setCoefficient(exp, coeff);
        }

        // 3. Add the constant term [0,0,...,0]
        std::vector<int> exp_const(dim, 0);
        // (not in used_exponents yet because we avoided all-zero above)
        double coeff_const = dist_const(rng);
        poly.setCoefficient(exp_const, coeff_const);

        polys.push_back(poly);
    }
    return polys;
}

int main() {
    // Benchmark parameters (adjust as needed)
    int dim       = 8;    // dimension (number of equations and variables)
    int min_deg   = 2;    // minimum degree to test (inclusive)
    int max_deg   = 5;    // maximum degree to test (inclusive)
    int nonzero   = 3;    // number of nonzero monomial terms per equation (excluding the constant term)
    int num_tests = 100;  // number of random tests per degree

    // Prepare output directory structure
    std::string base_dir = "results/jroots_results/dim" + std::to_string(dim) +
                            "/nonzero" + std::to_string(nonzero);
    std::filesystem::create_directories(base_dir);

    // Open summary output files (overwrite existing content)
    std::ofstream avg_time_file(base_dir + "/avg_times.txt");
    std::ofstream max_resid_file(base_dir + "/max_resids.txt");
    std::ofstream avg_resid_file(base_dir + "/avg_resids.txt");
    std::ofstream sum_resid_file(base_dir + "/sum_resids.txt");
    // Configure numeric format: general format with 17 significant digits
    avg_time_file.setf(std::ios::fmtflags(0), std::ios::floatfield);
    avg_time_file.precision(17);
    max_resid_file.setf(std::ios::fmtflags(0), std::ios::floatfield);
    max_resid_file.precision(17);
    avg_resid_file.setf(std::ios::fmtflags(0), std::ios::floatfield);
    avg_resid_file.precision(17);
    sum_resid_file.setf(std::ios::fmtflags(0), std::ios::floatfield);
    sum_resid_file.precision(17);

    // Random number setup
    std::mt19937 rng(0);  // Mersenne Twister PRNG with fixed seed
    std::normal_distribution<double> dist(0.0, 1.0);     // N(0,1) for monomial coefficients
    std::normal_distribution<double> dist_const(0.0, 1e-2); // N(0,0.01) for constant term coefficients

    // Warm-up: solve one test at the lowest degree (to warm caches, JIT, etc.)
    if (min_deg <= max_deg && num_tests > 0) {
        int deg = min_deg;
        std::vector<MultiPower> warm_polys = generate_polynomials(dim, deg, nonzero, rng, dist, dist_const);
        std::vector<double> a(dim, -1.0);
        std::vector<double> b(dim,  1.0);
        // Solve (roots not used, just to trigger any initialization overhead)
        std::vector<std::vector<double>> warm_roots = solve(warm_polys, a, b);
        // (No output or timing for warm-up run)
    }

    // Loop over each degree and perform tests
    for (int deg = min_deg; deg <= max_deg; ++deg) {
        std::cout << "--- Dim " << dim << " Degree " << deg << "/" << max_deg << " ---" << std::endl;
        // Create per-degree directory for roots
        std::string deg_dir = base_dir + "/deg" + std::to_string(deg);
        std::filesystem::create_directories(deg_dir);
        std::string roots_path = deg_dir + "/roots_tests.txt";
        std::ofstream roots_file(roots_path);
        roots_file.setf(std::ios::fmtflags(0), std::ios::floatfield);
        roots_file.precision(17);

        std::vector<double> all_times;
        all_times.reserve(num_tests);
        // Variables to accumulate residuals
        long long count_res = 0;
        double sum_res = 0.0;
        double max_res = 0.0;

        // Run multiple random tests for this degree
        for (int test = 0; test < num_tests; ++test) {
            if ((test + 1) % 10 == 0) {
                std::cout << "  test " << (test + 1) << "/" << num_tests << std::endl;
            }
            // Generate one random polynomial system
            std::vector<MultiPower> polys = generate_polynomials(dim, deg, nonzero, rng, dist, dist_const);
            std::vector<double> a(dim, -1.0);
            std::vector<double> b(dim,  1.0);

            // Solve and time it
            auto t1 = std::chrono::high_resolution_clock::now();
            std::vector<std::vector<double>> roots = solve(polys, a, b);
            auto t2 = std::chrono::high_resolution_clock::now();
            std::chrono::duration<double> elapsed = t2 - t1;
            double t_seconds = elapsed.count();
            all_times.push_back(t_seconds);

            // Write roots of this test to file
            roots_file << "Test " << (test + 1) << "\n";
            for (const auto &root : roots) {
                // Each root is a vector<double> of length dim
                for (int k = 0; k < dim; ++k) {
                    roots_file << root[k];
                    if (k < dim - 1) roots_file << " ";
                }
                roots_file << "\n";
            }
            roots_file << "\n";

            // Compute residuals |f_i(root_j)| for all i, j and accumulate metrics
            for (size_t j = 0; j < roots.size(); ++j) {
                const std::vector<double> &x = roots[j];
                for (int i = 0; i < dim; ++i) {
                    // Evaluate polynomial i at root x
                    double f_val = polys[i].evaluate(x);
                    double resid = std::fabs(f_val);
                    if (resid > max_res) {
                        max_res = resid;
                    }
                    sum_res += resid;
                    ++count_res;
                }
            }
        } // end for tests

        roots_file.close();  // close the per-degree roots output file

        // Calculate summary statistics for this degree
        double avg_time = 0.0;
        if (!all_times.empty()) {
            double total_time = 0.0;
            for (double t : all_times) total_time += t;
            avg_time = total_time / all_times.size();
        } else {
            avg_time = NAN;
        }
        double avg_res = (count_res > 0 ? sum_res / count_res : NAN);
        double max_res = (count_res > 0 ? max_res : NAN);  // (reuse max_res variable)
        double sum_res_out = (count_res > 0 ? sum_res : NAN);

        // Append metrics to summary files
        avg_time_file << avg_time << "\n";
        max_resid_file << max_res << "\n";
        avg_resid_file << avg_res << "\n";
        sum_resid_file << sum_res_out << "\n";
    } // end for degrees

    std::cout << "Program finished!" << std::endl;
    return 0;
}
