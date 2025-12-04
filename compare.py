import os
import numpy as np

# ======================
# Configuration
# ======================
dim = 2
nonzero = 3
maxdeg = 30           # check degrees 2..maxdeg
bertini_version = "v1.6"   # e.g. "v1.6" or "v1.7"

# numerical tolerances
imag_tol = 1e-10      # how big an imaginary part we still treat as "real"
root_tol = 1e-8       # tolerance for comparing real roots


# ======================
# Path setup
# ======================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# NEW: Bertini results now under sparse/results/bertini_results/<version>/dimX/nonzeroY
BERTINI_BASE = os.path.join(
    BASE_DIR,
    "sparse",
    "results",
    "bertini_results",
    bertini_version,
    f"dim{dim}",
    f"nonzero{nonzero}",
)

# yroots results unchanged
YROOTS_BASE = os.path.join(
    BASE_DIR,
    "sparse",
    "results",
    "yroots_results",
    f"dim{dim}",
    f"nonzero{nonzero}",
)


# ======================
# Parsing helpers
# ======================
def parse_bertini_roots(path):
    """
    Parse a Bertini real_finite_solutions wrapper file like roots_deg5.txt.

    Returns:
        dict: test_index -> list of (x0, x1) real roots
    """
    results = {}
    with open(path, "r") as f:
        lines = [line.rstrip("\n") for line in f]

    i = 0
    n = len(lines)

    while i < n:
        line = lines[i].strip()
        if line.startswith("===== TEST"):
            # Example: "===== TEST 1 ====="
            parts = line.split()
            # parts = ["=====", "TEST", "1", "====="]
            try:
                test_idx = int(parts[2])
            except (IndexError, ValueError):
                i += 1
                continue

            i += 1
            # skip blank lines
            while i < n and lines[i].strip() == "":
                i += 1

            if i >= n:
                break

            # line with number of real solutions (e.g. "3")
            N_line = lines[i].strip()
            try:
                N = int(N_line.split()[0])
            except ValueError:
                # malformed; skip this test
                i += 1
                continue

            i += 1
            # skip blank lines
            while i < n and lines[i].strip() == "":
                i += 1

            roots = []

            for _ in range(N):
                if i + 1 >= n:
                    break

                line_x0 = lines[i].strip()
                line_x1 = lines[i + 1].strip()

                if not line_x0 or not line_x1:
                    break

                try:
                    x0r, x0i = map(float, line_x0.split())
                    x1r, x1i = map(float, line_x1.split())
                except ValueError:
                    break

                # optionally enforce small imaginary parts
                if abs(x0i) > imag_tol or abs(x1i) > imag_tol:
                    # keep real parts anyway, but could warn if desired
                    pass

                roots.append((x0r, x1r))
                i += 2

                # skip blank lines between solutions
                while i < n and lines[i].strip() == "":
                    i += 1

            results[test_idx] = roots

        else:
            i += 1

    return results


def parse_yroots_roots(path):
    """
    Parse yroots results file, e.g. roots_tests.txt:

        Test 1
        x0 x1
        ...

        Test 2
        ...

    Returns:
        dict: test_index -> list of (x0, x1) roots
    """
    results = {}
    current_test = None

    with open(path, "r") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                # blank line: just skip
                continue

            if line.startswith("Test "):
                # Example: "Test 1"
                parts = line.split()
                try:
                    current_test = int(parts[1])
                except (IndexError, ValueError):
                    current_test = None
                    continue
                results[current_test] = []
            else:
                # root line
                if current_test is None:
                    continue
                parts = line.split()
                if len(parts) < 2:
                    continue
                try:
                    x0 = float(parts[0])
                    x1 = float(parts[1])
                except ValueError:
                    continue
                results[current_test].append((x0, x1))

    return results


# ======================
# Comparison helper
# ======================
def roots_match(roots1, roots2, tol=root_tol):
    """
    Compare two lists of (x0, x1) roots, ignoring order.

    Returns:
        bool
    """
    if len(roots1) != len(roots2):
        return False

    used = [False] * len(roots2)

    for (a0, a1) in roots1:
        found = False
        for j, (b0, b1) in enumerate(roots2):
            if used[j]:
                continue
            if abs(a0 - b0) <= tol and abs(a1 - b1) <= tol:
                used[j] = True
                found = True
                break
        if not found:
            return False

    return True


# ======================
# Main checking loop
# ======================
def main():
    total_degrees = 0
    total_tests = 0
    mismatches = []

    for deg in range(2, maxdeg + 1):
        bertini_file = os.path.join(
            BERTINI_BASE, f"roots_deg{deg}.txt"
        )
        yroots_file = os.path.join(
            YROOTS_BASE, f"deg{deg}", "roots_tests.txt"
        )

        if not os.path.exists(bertini_file) or not os.path.exists(yroots_file):
            print(f"[skip] deg {deg}: missing file(s)")
            continue

        total_degrees += 1
        print(f"Checking degree {deg}...")

        b_roots = parse_bertini_roots(bertini_file)
        y_roots = parse_yroots_roots(yroots_file)

        # union of test indices seen in either file
        all_tests = sorted(set(b_roots.keys()) | set(y_roots.keys()))

        for t in all_tests:
            total_tests += 1
            b_list = b_roots.get(t, [])
            y_list = y_roots.get(t, [])

            if not roots_match(b_list, y_list):
                mismatches.append((deg, t, b_list, y_list))
                print(
                    f"  [MISMATCH] deg={deg}, test={t}: "
                    f"Bertini has {len(b_list)} root(s), "
                    f"yroots has {len(y_list)}"
                )

        print(f"  degree {deg} done.")

    print("\n===== SUMMARY =====")
    print(f"Degrees checked: {total_degrees}")
    print(f"Total tests compared: {total_tests}")
    print(f"Total mismatches: {len(mismatches)}")

    if mismatches:
        print("\nSome example mismatches:")
        for (deg, t, b_list, y_list) in mismatches[:10]:
            print(f"\n  deg={deg}, test={t}")
            print(f"    Bertini roots ({len(b_list)}):")
            for r in b_list:
                print(f"      {r}")
            print(f"    yroots roots ({len(y_list)}):")
            for r in y_list:
                print(f"      {r}")


if __name__ == "__main__":
    main()