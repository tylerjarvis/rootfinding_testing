#!/usr/bin/env python3
import shutil
import subprocess
from time import time
from pathlib import Path

import numpy as np

# Python yroots only for residual evaluation (not solving)
from yroots import MultiPower

def full_coeff_matrix_from_efficient(dim: int, deg: int, test_block: np.ndarray) -> np.ndarray:
    """
    test_block shape: (dim, nonzero+1, dim+1)
      last axis 0..dim-1 = exponent multi-index
      last axis dim      = coefficient
    Produces coeffs_full shape: (dim, deg+1, ..., deg+1)  (dim times)
    """
    shape = [dim] + [(deg + 1)] * dim
    coeffs_full = np.zeros(shape, dtype=float)

    coordinates = np.array(test_block[:, :, :dim], dtype=int)
    values      = np.array(test_block[:, :,  dim], dtype=float)

    for fi in range(dim):
        for k, idx in enumerate(coordinates[fi]):
            coeffs_full[fi, *idx] = values[fi, k]

    return coeffs_full


def residuals(dim: int, funcs, roots: np.ndarray) -> np.ndarray:
    """Return |f_i(root_j)| array of shape (dim, nroots)."""
    if roots.size == 0:
        return np.zeros((dim, 0), dtype=float)

    res = np.zeros((dim, roots.shape[0]), dtype=float)
    for i in range(dim):
        for j, r in enumerate(roots):
            res[i, j] = float(np.abs(funcs[i](r))[0])
    return res


# C++ input writer

def _format_coeff(c: float) -> str:
    return f"{c:.17g}"


def _monomial_str(var_names, exps) -> str:
    """
    Build monomial like x1^2*x3*x7^5
    C++ parser supports '^' per Function.hpp (POWER: x^y).
    """
    parts = []
    for v, e in zip(var_names, exps):
        e = int(e)
        if e <= 0:
            continue
        if e == 1:
            parts.append(v)
        else:
            parts.append(f"{v}^{e}")
    return "*".join(parts) if parts else "1"


def poly_expr_from_testblock(test_block: np.ndarray, func_idx: int, var_names) -> str:
    """
    Construct expression string for one polynomial:
      sum_{terms} coeff * Π v_i^{exp_i}
    """
    rows = test_block[func_idx]  # (nonzero+1, dim+1)
    dim = len(var_names)

    terms = []
    for row in rows:
        exps = row[:dim]
        c = float(row[dim])
        if c == 0.0:
            continue

        mon = _monomial_str(var_names, exps)
        if mon == "1":
            terms.append(_format_coeff(c))
        else:
            terms.append(f"({_format_coeff(c)})*({mon})")

    if not terms:
        return "0"

    return "(" + " + ".join(terms) + ")"


def write_cpp_input_file(
    input_path: Path,
    dim: int,
    test_block: np.ndarray,
    *,
    num_threads: int = 3,
    interval_lo: float = -1.0,
    interval_hi: float =  1.0,
) -> None:
    """
    Writes an input.txt matching your exampleInput.txt grammar:
      PARAMETERS; ... PARAMETERS_END;
      INTERVAL; ... INTERVAL_END;
      FUNCTIONS; ... FUNCTIONS_END;
      END;
    """
    var_names  = [f"x{i+1}" for i in range(dim)]
    func_names = [f"f{i+1}" for i in range(dim)]

    lines = []

    lines.append("PARAMETERS;\n")
    lines.append(f"numThreads = {int(num_threads)};\n")
    lines.append("PARAMETERS_END;\n\n")

    lines.append("INTERVAL;\n")
    for _ in range(dim):
        lines.append(f"[{_format_coeff(interval_lo)}, {_format_coeff(interval_hi)}];\n")
    lines.append("INTERVAL_END;\n\n")

    lines.append("FUNCTIONS;\n")
    lines.append("function " + ", ".join(func_names) + ";\n")
    lines.append("variable_group " + ", ".join(var_names) + ";\n")

    for i, fname in enumerate(func_names):
        expr = poly_expr_from_testblock(test_block, i, var_names)
        lines.append(f"{fname} = {expr};\n")

    lines.append("FUNCTIONS_END;\n\n")
    lines.append("END;\n")

    input_path.write_text("".join(lines))


# Root parsing (locked to C++ RootTracker output)

def read_roots_csv(workdir: Path, dim: int) -> np.ndarray:
    """
    RootTracker::logResults() writes workdir/roots.csv.
    Format: one root per line, comma-separated coordinates.
    There can be blank lines (e.g., between thread blocks).
    """
    path = workdir / "roots.csv"
    if not path.exists():
        return np.zeros((0, dim), dtype=float)

    rows = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        parts = [p.strip() for p in line.split(",") if p.strip() != ""]
        if len(parts) != dim:
            # Safer to fail loudly than to silently reshape garbage.
            raise ValueError(
                f"roots.csv line does not have dim={dim} entries:\n"
                f"  line: {line}\n"
                f"  parsed parts ({len(parts)}): {parts}"
            )
        rows.append([float(x) for x in parts])

    return np.array(rows, dtype=float) if rows else np.zeros((0, dim), dtype=float)


# Runner utilities

def run_cpp_solver(exe_path: Path, input_file: Path, workdir: Path, timeout_s: int = 3600) -> float:
    """
    Run solver; returns wall time. C++ writes roots.csv in workdir.
    """
    # avoid stale outputs if a previous run crashed
    out_csv = workdir / "roots.csv"
    if out_csv.exists():
        out_csv.unlink()

    start = time()
    proc = subprocess.run(
        [str(exe_path), str(input_file.name)],
        cwd=str(workdir),
        capture_output=True,
        text=True,
        timeout=timeout_s,
    )
    elapsed = time() - start

    if proc.returncode != 0:
        raise RuntimeError(
            f"C++ solver failed (code {proc.returncode}).\n"
            f"WORKDIR: {workdir}\n"
            f"STDOUT:\n{proc.stdout}\n\nSTDERR:\n{proc.stderr}\n"
        )

    return elapsed


def ensure_empty_file(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("")


def append_value(path: Path, value: float) -> None:
    with path.open("a") as f:
        f.write(f"{value:.17g}\n")

# Main

def main():
    dim = 2
    mindeg = 2
    maxdeg = 50
    nonzero = 3
    num_tests = 100

    coeff_root = Path("../sparse/coeffs")

    base_dir = Path(f"../sparse/results/croots_results/dim{dim}/nonzero{nonzero}")
    base_dir.mkdir(parents=True, exist_ok=True)

    avg_time_path  = base_dir / "avg_times.txt"
    max_resid_path = base_dir / "max_resids.txt"
    avg_resid_path = base_dir / "avg_resids.txt"
    sum_resid_path = base_dir / "sum_resids.txt"
    for p in (avg_time_path, max_resid_path, avg_resid_path, sum_resid_path):
        ensure_empty_file(p)

    # Path
    exe_path = Path("/data1/acme/Roots/alternate/CRoots/yroots_solver")


    if not exe_path.exists():
        raise FileNotFoundError(f"Executable not found: {exe_path.resolve()}")

    for deg in range(mindeg, maxdeg + 1):
        print(f"--- C++ Dim {dim} Degree {deg}/{maxdeg} ---", flush=True)

        coeff_path = coeff_root / f"dim{dim}" / f"deg{deg}" / f"num{nonzero}.npy"
        if not coeff_path.exists():
            raise FileNotFoundError(f"Coeff file not found: {coeff_path.resolve()}")

        coeffs = np.load(coeff_path)  # (num_tests, dim, nonzero+1, dim+1)
        reps = min(coeffs.shape[0], num_tests)

        out_dir = base_dir / f"deg{deg}"
        out_dir.mkdir(parents=True, exist_ok=True)

        roots_test_path = out_dir / "roots_tests.txt"
        roots_test_path.write_text("")

        all_times = []
        all_res_flat = []

        # Optional warmup (comment out for strict timing comparability)
        if reps > 0:
            warm_dir = out_dir / "tmp_warmup"
            if warm_dir.exists():
                shutil.rmtree(warm_dir)
            warm_dir.mkdir(parents=True, exist_ok=True)
            write_cpp_input_file(warm_dir / "input.txt", dim, coeffs[0], num_threads=3)
            try:
                _ = run_cpp_solver(exe_path, warm_dir / "input.txt", warm_dir)
            except Exception:
                pass
            shutil.rmtree(warm_dir, ignore_errors=True)

        for tnum in range(reps):
            if (tnum + 1) % 10 == 0:
                print(f"  test {tnum + 1}/{reps}", flush=True)

            workdir = out_dir / f"tmp_test{tnum+1}"
            if workdir.exists():
                shutil.rmtree(workdir)
            workdir.mkdir(parents=True, exist_ok=True)

            input_file = workdir / "input.txt"
            test_block = coeffs[tnum]

            write_cpp_input_file(
                input_file,
                dim,
                test_block,
                num_threads=3,
                interval_lo=-1.0,
                interval_hi= 1.0,
            )

            wall_time = run_cpp_solver(exe_path, input_file, workdir)
            all_times.append(wall_time)

            roots = read_roots_csv(workdir, dim)

            # Save roots
            with roots_test_path.open("a") as rf:
                rf.write(f"Test {tnum + 1}\n")
                if roots.size:
                    np.savetxt(rf, roots, fmt="%.17g")
                rf.write("\n")

            # Residuals in Python (same as your other pipelines)
            coeffs_full = full_coeff_matrix_from_efficient(dim, deg, test_block)
            funcs = [MultiPower(c) for c in coeffs_full]
            res = residuals(dim, funcs, roots)
            all_res_flat.extend(res.flatten().tolist())

            shutil.rmtree(workdir, ignore_errors=True)

        arr = np.array(all_res_flat, dtype=float)
        avg_time  = float(np.mean(all_times)) if all_times else float("nan")
        max_resid = float(arr.max())          if arr.size   else float("nan")
        avg_resid = float(arr.mean())         if arr.size   else float("nan")
        sum_resid = float(arr.sum())          if arr.size   else float("nan")

        append_value(avg_time_path,  avg_time)
        append_value(max_resid_path, max_resid)
        append_value(avg_resid_path, avg_resid)
        append_value(sum_resid_path, sum_resid)

    print("Program Finished")


if __name__ == "__main__":
    main()
