import numpy as np
import subprocess
import os
from time import time
from yroots import polynomial as py

# -----------------------
# Configuration
# -----------------------
dim = 8          # number of variables (assumed square system: n_eq = dim)
maxdeg = 5
nonzero = 3      # used only in path names; keep consistent with how you saved coeffs
num_tests = 100  # max tests per degree

# Bertini version tag: change this to "v1.6", "v1.7", etc.
BERT_VERSION = "v1.6"

# -----------------------
# Paths based on this file's location
# -----------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Bertini directory: assumes BertiniLinux64_vX.Y is one level up from test_codes
BERT_DIR = os.path.join(BASE_DIR, "..", f"BertiniLinux64_{BERT_VERSION}")

# Coefficients directory: assumes sparse/coeffs is one level up from test_codes
COEFF_DIR = os.path.join(BASE_DIR, "..", "sparse", "coeffs")

# Results directory: now under sparse/results/bertini_results/<version>/dimX/nonzeroY
RESULTS_BASE = os.path.join(
    BASE_DIR,
    "..",
    "sparse",
    "results",
    "bertini_results",
    BERT_VERSION,
    f"dim{dim}",
    f"nonzero{nonzero}"
)
os.makedirs(RESULTS_BASE, exist_ok=True)

# Average times file as TXT instead of NPY
times_file = os.path.join(RESULTS_BASE, f"avg_times.txt")
avg_resids_file = os.path.join(RESULTS_BASE, f"avg_resids.txt")
max_resids_file = os.path.join(RESULTS_BASE, f"max_resids.txt")
sum_resids_file = os.path.join(RESULTS_BASE, f"sum_resids.txt")

# File to log skipped tests
skipped_log_path = os.path.join(RESULTS_BASE, "skipped_tests.txt")


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
    input_path = os.path.join(BERT_DIR, "input")

    # Number of equations; for square systems this should equal dim
    n_eq = len(A_test)

    # Basic header
    mystr = 'CONFIG\nSECURITYMAXNORM: 1;\nEND;\nINPUT\nfunction'

    # function f0, f1, ..., f_{n_eq-1}
    for i in range(n_eq):
        mystr += f' f{i},'
    mystr = mystr[:-1]  # remove trailing comma

    # variable_group x0, x1, ..., x_{dim-1}
    mystr += ';\nvariable_group'
    for i in range(dim):
        mystr += f' x{i},'
    mystr = mystr[:-1]  # remove trailing comma
    mystr += ';\n'

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

    mystr += 'END;'

    with open(input_path, 'w') as f:
        f.write(mystr)

# Extract roots from real_finite_solutions
def read_bertini_solutions(path, nvars, imag_tol=1e-10):
    with open(path, "r") as f:
        # strip blank lines
        lines = [ln.strip() for ln in f if ln.strip()]

    nsol = int(lines[0])
    sols = []
    idx = 1
    for _ in range(nsol):
        sol = []
        is_real = True
        for _ in range(nvars):
            re_str, im_str = lines[idx].split()
            re, im = float(re_str), float(im_str)
            if abs(im) > imag_tol:
                is_real = False
            sol.append(re)  # keep just real part
            idx += 1
        if is_real:
            sols.append(sol)
    return sols

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
avg_times = np.array([])
avg_resids = np.array([])  # kept for future use if needed
max_resids = np.array([])  # kept for future use if needed
sum_resids = np.array([])

# open the skipped-log file once for this run (overwrite each time)
with open(skipped_log_path, "w") as skipped_log:

    for deg in range(2, maxdeg + 1):
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
        n_tests_total = len(coeffs)
        n_tests = min(num_tests, n_tests_total)

        # Combined output file for this degree, version-tagged via RESULTS_BASE
        deg_results_path = os.path.join(
            RESULTS_BASE,
            f"roots_deg{deg}.txt"
        )

        # Open once per degree; overwrite any previous file for this degree
        with open(deg_results_path, "w") as deg_out:

            # Optional header for the degree
            deg_out.write(
                f"===== RESULTS FOR dim={dim}, deg={deg}, nonzero={nonzero}, "
                f"Bertini {BERT_VERSION} =====\n\n"
            )

            for test in range(n_tests):
                A_test = coeffs[test]  # sparse representation for ONE system

                # Build Bertini input for this test
                set_up_input(A_test)

                # Run Bertini
                start = time()
                bertini_exec = os.path.join(BERT_DIR, "bertini")

                # Run Bertini in BERT_DIR so all its outputs land there
                subprocess.run([bertini_exec, "input"], cwd=BERT_DIR, 
                    check=True,
                    stdout=subprocess.DEVNULL,
                )
                t = time() - start

                # Now real_finite_solutions really is in BERT_DIR
                sol_file = os.path.join(BERT_DIR, "real_finite_solutions")

                if os.path.exists(sol_file):
                    # Read solution text
                    with open(sol_file, "r") as sf:
                        sol_text = sf.read()

                    # Append a header + the solution to the degree file
                    deg_out.write(f"===== TEST {test + 1} =====\n")
                    deg_out.write(sol_text)
                    deg_out.write("\n\n")  # blank line between tests

                    # Extract solutions from 'real_finite_solutions'
                    real_solutions = read_bertini_solutions(sol_file, dim, imag_tol=1e-12)
                    resids = resids + get_resid(dim, deg, A_test, real_solutions)

                    # Remove the individual solution file after consuming it
                    os.remove(sol_file)

                else:
                    # Log the skipped test with all relevant info
                    skipped_log.write(
                        f"SKIPPED: dim={dim}, deg={deg}, nonzero={nonzero}, "
                        f"test={test + 1}, coeff_file={coeff_path}, "
                        f"bertini_version={BERT_VERSION}\n"
                    )
                    print(
                        f"[warn] test {test + 1} (deg={deg}): "
                        f"no '{sol_file}' produced — skipping"
                    )

                times = np.append(times, t)

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


# -----------------------
# Cleanup Bertini intermediate files
# -----------------------
createdFiles = [
    'failed_paths', 'main_data', 'finite_solutions', 'midpath_data',
    'nonsingular_solutions', 'raw_solutions', 'raw_data', 'output',
    'singular_solutions', 'start'
]

for fname in createdFiles:
    fpath = os.path.join(BERT_DIR, fname)
    if os.path.exists(fpath):
        os.remove(fpath)