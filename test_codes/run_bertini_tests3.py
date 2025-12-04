import numpy as np
from subprocess import run
import os
from time import time

# -----------------------
# Configuration
# -----------------------
dim = 2          # number of variables (assumed square system: n_eq = dim)
maxdeg = 30
nonzero = 3      # used only in path names; keep consistent with how you saved coeffs
num_tests = 300  # max tests per degree

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
times_file = os.path.join(RESULTS_BASE, f"dim{dim}_nz{nonzero}_avg_times.txt")

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

        # Each term is [e0, e1, c]
        for term in A_test[eq_idx]:
            e0, e1, c = term  # term may be list or np.array

            # Optionally skip exact zeros
            if c == 0 or c == 0.0:
                continue

            if not first_term:
                mystr += ' + '
            else:
                first_term = False

            e0_int = int(e0)
            e1_int = int(e1)

            mystr += f'{c}*x0^{e0_int}*x1^{e1_int}'

        # In case all coefficients were zero, we still want something valid
        if first_term:
            mystr += '0'

        mystr += ';\n'

    mystr += 'END;'

    with open(input_path, 'w') as f:
        f.write(mystr)


# -----------------------
# Main experiment
# -----------------------
avg_times = np.array([])
avg_resids = np.array([])  # kept for future use if needed
max_resids = np.array([])  # kept for future use if needed

# open the skipped-log file once for this run (overwrite each time)
with open(skipped_log_path, "w") as skipped_log:

    for deg in range(2, maxdeg + 1):
        times = np.array([])
        resids = np.array([])  # not populated yet, but kept for structure

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
                run([bertini_exec, "input"], cwd=BERT_DIR)
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
        # Save as a TXT file instead of NPY
        np.savetxt(times_file, avg_times)


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