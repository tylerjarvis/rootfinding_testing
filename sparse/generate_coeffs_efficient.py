import numpy as np
import os

def generate_index_of_deg_n(dim, deg, rng):
    # Initialize list of variable powers where idx[0] = power of x, idx[1] = power of y, etc.
    idx = [0] * dim

    # Raise idx[i] deg number of time where i is between 0 and (dim - 1) inclusive such that sum(idx) = deg
    axis_nums = rng.integers(0, dim, size=deg)
    for i in axis_nums:
        idx[i] += 1

    return idx

def generate_index_of_deg_less_than_n(dim, deg, rng):
    idx = [0] * dim

    # Get a random deg for the nonzero term
    goal_deg = rng.integers(1, deg + 1)

    # Get a random multivariate monomial with deg = goal_deg
    axis_nums = rng.integers(0, dim, size=goal_deg)
    for i in axis_nums:
        idx[i] += 1

    return idx
        
def gen_idxs(dim, deg, nonzero, rng):
    idxs = []

    idxs.append(generate_index_of_deg_n(dim, deg, rng))

    while len(idxs) < nonzero:
        add = True
        idx = generate_index_of_deg_less_than_n(dim, deg, rng)

        # Prevent duplicates
        for i in idxs:
            if np.array_equal(idx, i):
                add = False

        if add: 
            idxs.append(idx)

    return idxs

def make_dir(dir, path=None):
    if path is None:
        path = ""
    else:
        path = path.rstrip("/") + "/"
    try:
        os.mkdir(path + dir)
    except FileExistsError:
        pass

def full_coeff_matrix(dim, deg, coeff_info):
    # Designed to work with run_test in run_yroots_test2.py
    # Creates the coefficient matrix of a single test of given dim and degree

    # Create coeff matrix shape
    shape = [dim] + [(deg+1)]*dim
    coeff_matrix = np.zeros(shape)

    # Get the idxs and values of the nonzero terms
    coordinates = np.array(coeff_info[:, :, :dim], dtype=int)
    values = coeff_info[:, :, dim]

    for func in range(dim):
        for i, idx in enumerate(coordinates[func]):
            coeff_matrix[func, *idx] = values[func, i]

    return coeff_matrix

if __name__ == "__main__":
    dim = 40
    mindeg = 2
    maxdeg = 2
    nonzero = 3
    num_tests = 100
    rng = np.random.default_rng(seed=42)


    for deg in range(mindeg, maxdeg+1):
        # Create coefficient matrix
        # dim + 1 because [0 to (dim-1)] inclusive will be the respective power of x, y, z, ... of the multivariate monomial 
        # and [dim] will be the actual coefficient value
        
        shape = [num_tests, dim, nonzero+1, dim+1] 
        coeffs = np.zeros(shape)

        for test in range(num_tests):
            for func in range(dim):
                idxs = gen_idxs(dim, deg, nonzero, rng)

                coeffs[test,func, 0, dim] = rng.standard_normal() / 10

                for i in range(nonzero):
                    coeffs[test,func, i+1, :dim] = idxs[i]
                    coeffs[test,func, i+1, dim] = rng.standard_normal()

        # create the nested folder tree in one go
        outdir = os.path.join("coeffs", f"dim{dim}", f"deg{deg}")
        os.makedirs(outdir, exist_ok=True)

        # save the file into that directory
        outpath = os.path.join(outdir, f"num{nonzero}.npy")
        np.save(outpath, coeffs)

        print(f"Finished degree {deg} → saved {outpath}")
        