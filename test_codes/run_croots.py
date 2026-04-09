import numpy as np
import pandas as pd
import subprocess
import os
from time import time
from yroots import polynomial as py

# -----------------------
# Configuration
# -----------------------
dim = 4                 # number of variables (assumed square system: n_eq = dim)
mindeg = 2
maxdeg = 5              
nonzero = 3             # used only in path names; keep consistent with how you saved coeffs
num_tests = 100         # max tests per degree
num_threads = 10        # number of threads to use

# -----------------------
# Paths based on this file's location
# -----------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Bertini directory: assumes BertiniLinux64_vX.Y is one level up from test_codes
CR_DIR = os.path.join("/data1/acme/Roots/alternate/CRoots/")

# Coefficients directory: assumes sparse/coeffs is one level up from test_codes
COEFF_DIR = os.path.join(BASE_DIR, "..", "sparse", "coeffs")

# Results directory: now under sparse/results/bertini_results/<version>/dimX/nonzeroY
RESULTS_BASE = os.path.join(
    BASE_DIR,
    "..",
    "sparse",
    "results",
    "croot_results",
    f"dim{dim}",
    f"nonzero{nonzero}"
)
os.makedirs(RESULTS_BASE, exist_ok=True)

# -----------------------
# Helper: write Bertini input file (SPARSE FORMAT)
# -----------------------
def set_up_input(A_test):
    """
    Given the sparse coefficient representation for ONE system (one test),
    write the Bertini input file into BERT_DIR/input.

    Expected structure of A_test:
        A_test[eq_idx][term_idx] = [e0, e1, coeff]
    where:
        e0, e1 : exponents for x0^e0 * x1^e1
        coeff  : coefficient (float)

    So A_test is effectively a list/array of length n_eq, and each entry is a
    list/array of triples [e0, e1, c].
    """
    input_path = os.path.join(CR_DIR, "input.txt")

    # Number of equations; for square systems this should equal dim
    n_eq = len(A_test)

    # Basic header
    mystr = f'PARAMETERS;\nnumThreads = {num_threads};\nuseTimer = true;\nPARAMETERS_END;\n\n'
    
    # Interval
    mystr+= 'INTERVAL;\n'
    for _ in range(dim):
        mystr += f'[-1, 1];\n'
    mystr += 'INTERVAL_END;\n\n'

    # function f0, f1, ..., f_{n_eq-1}
    mystr += 'FUNCTIONS;\nfunction'
    for i in range(n_eq):
        mystr += f' f{i},'
    mystr = mystr[:-1]  # remove trailing comma
    mystr += ';\n'

    # variable_group x0, x1, ..., x_{dim-1}
    mystr += '\nvariable_group'
    for i in range(dim):
        mystr += f' x{i},'
    mystr = mystr[:-1]  # remove trailing comma
    mystr += ';\n\n'

    # Polynomial definitions from sparse triples [e0, e1, coeff]
    for eq_idx in range(n_eq):
        mystr += f'f{eq_idx} = '
        first_term = True

        # Each term is [e0, e1, c] (Change depending on dimension)
        for term in A_test[eq_idx]:

            # Optionally skip exact zeros
            if term[-1] == 0 or term[-1] == 0.0:
                continue

            if not first_term:
                mystr += ' + '
            else:
                first_term = False

            mystr += f'{term[-1]}'

            for i in range(len(term) - 1):
                mystr += f'*x{i}^{int(term[i])}'

        # In case all coefficients were zero, we still want something valid
        if first_term:
            mystr += '0'

        mystr += ';\n'

    mystr += 'FUNCTIONS_END;\n\nEND;'

    with open(input_path, 'w') as f:
        f.write(mystr)

def get_resid(dim, deg, coeffs, roots):

    # Create coeff matrix shape
    shape = [dim] + [(deg+1)]*dim
    coeff_matrix = np.zeros(shape)

    # Get the idxs and values of the nonzero terms
    coordinates = np.array(coeffs[:, :, :dim], dtype=int)
    values = coeffs[:, :, dim]

    for func in range(dim):
        for i, idx in enumerate(coordinates[func]):
            coeff_matrix[func, *idx] = values[func, i]

    funcs = [py.MultiPower(c) for c in coeff_matrix]

    res = []
    for i in range(dim):
        for root in roots:
            res.append(abs(funcs[i](root))[0])
    return res

# -----------------------
# Main experiment
# -----------------------

# Average times file as TXT instead of NPY
times_file = os.path.join(RESULTS_BASE, f"avg_times.txt")
avg_resids_file = os.path.join(RESULTS_BASE, f"avg_resids.txt")
max_resids_file = os.path.join(RESULTS_BASE, f"max_resids.txt")
sum_resids_file = os.path.join(RESULTS_BASE, f"sum_resids.txt")

avg_times = np.array([])
avg_resids = np.array([])  # kept for future use if needed
max_resids = np.array([])  # kept for future use if needed
sum_resids = np.array([])

for deg in range(mindeg, maxdeg + 1):
    times = np.array([])
    resids = []  # not populated yet, but kept for structure

    # Path to the coefficient file for this degree
    coeff_path = os.path.join(
        COEFF_DIR,
        f"dim{dim}",
        f"deg{deg}",
        f"num{nonzero}.npy"
    )

    # Allow pickle because sparse structures are often saved as object arrays
    coeffs = np.load(coeff_path, allow_pickle=True)

    # coeffs is expected to be something like:
    # coeffs[test][eq_idx][term_idx] = [e0, e1, coeff]

    # Combined output file for this degree, version-tagged via RESULTS_BASE
    deg_results_path = os.path.join(
        RESULTS_BASE,
        f"roots_deg{deg}.txt"
    )

    # Open once per degree; overwrite any previous file for this degree
    with open(deg_results_path, "w") as deg_out:
        for test in range(num_tests):
            A_test = coeffs[test]  # sparse representation for ONE system

            # Build CRoot input for this test
            set_up_input(A_test)

            # Run CRoot
            croots_exec = os.path.join(CR_DIR, "yroots_solver")
            start = time()

            # Run Bertini in BERT_DIR so all its outputs land there
            subprocess.run(
                [croots_exec, "input.txt"],
                cwd=CR_DIR,
                check=True,
                stdout=subprocess.DEVNULL,
            )
            t = time() - start

            # Now real_finite_solutions really is in BERT_DIR
            sol_file = os.path.join(CR_DIR, "roots.csv")

            try:
                # Read solution text and convert to numpy array
                df = pd.read_csv(sol_file, header=None)
                if test == 70:
                    print(df)

                df_cleaned = df.dropna(how='all')
                roots = df_cleaned.to_numpy()

                # Extract solutions from 'real_finite_solutions'
                resids = resids + get_resid(dim, deg, A_test, roots)
                times = np.append(times, t)

                deg_out.write(f"Test {test + 1}\n")
                np.savetxt(deg_out, roots, fmt="%.17g")
                deg_out.write("\n")

                # Remove the individual solution file after consuming it
                os.remove(sol_file)

            except pd.errors.EmptyDataError:
                print(f"Degree {deg}, test {test+1}: roots.csv has no parseable data")
                times = np.append(times, t)
                deg_out.write(f"Test {test + 1}\n\n")
                os.remove(sol_file)

    # Store average time for this degree and save incrementally
    avg_times = np.append(avg_times, np.mean(times))
    max_resids = np.append(max_resids, np.max(resids))
    avg_resids = np.append(avg_resids, np.mean(resids))
    sum_resids = np.append(sum_resids, np.sum(resids))

    # Save as a TXT file instead of NPY
    np.savetxt(times_file, avg_times)
    np.savetxt(max_resids_file, max_resids)
    np.savetxt(avg_resids_file, avg_resids)
    np.savetxt(sum_resids_file, sum_resids)

print("Program Finished")