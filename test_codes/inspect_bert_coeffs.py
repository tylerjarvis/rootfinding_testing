#!/usr/bin/env python3
import argparse
import json
import os
import numpy as np

def load_coeffs(coeffs_root, dim, deg, nonzero):
    path = os.path.join(coeffs_root, f"dim{dim}", f"deg{deg}", f"num{nonzero}.npy")
    arr = np.load(path, allow_pickle=False)
    return arr, path

def nonzero_terms(Ai):
    terms = []
    J, K = Ai.shape
    for j in range(J):
        for k in range(K):
            c = float(Ai[j, k])
            if c != 0.0:
                terms.append((j, k, c))
    terms.sort(key=lambda t: (t[0] + t[1], t[0], t[1]))
    return terms

def poly_to_string(terms, varnames=("x0","x1")):
    if not terms:
        return "0"
    parts = []
    for j, k, c in terms:
        if np.isclose(c, 0.0):
            continue
        coef = f"{c:.17g}"
        m = []
        if k != 0:
            m.append(f"{varnames[0]}^{k}" if k != 1 else f"{varnames[0]}")
        if j != 0:
            m.append(f"{varnames[1]}^{j}" if j != 1 else f"{varnames[1]}")
        mon = "*".join(m) if m else "1"
        parts.append(f"{coef}*{mon}" if mon != "1" else f"{coef}")
    return " + ".join(parts) if parts else "0"

def compute_min_degree_constant(Ai, r):
    terms = nonzero_terms(Ai)
    pos_terms = [(j,k,c) for (j,k,c) in terms if not (j==0 and k==0)]
    if not pos_terms:
        return 0.0, 0
    min_tot = min(j+k for (j,k,_) in pos_terms)
    mindeg_terms = [(j,k,c) for (j,k,c) in pos_terms if (j+k)==min_tot]
    s = 0.0
    for j,k,c in mindeg_terms:
        s += c * (r[0]**k) * (r[1]**j)
    return -s, min_tot

def eval_poly(Ai, x):
    x0, x1 = x
    J, K = Ai.shape
    x0_pows = np.array([x0**k for k in range(K)], dtype=float)
    x1_pows = np.array([x1**j for j in range(J)], dtype=float)
    return float(np.sum(Ai * np.outer(x1_pows, x0_pows)))

def eval_poly_grid(Ai, X, Y):
    """
    Efficiently evaluate Ai[j,k] * x0^k * x1^j on a meshgrid (X, Y).
    X, Y: (m, n) arrays. Returns (m, n).
    """
    J, K = Ai.shape
    # precompute powers
    x0 = X
    x1 = Y
    # Powers along last axis via broadcasting
    x0_pows = np.stack([x0**k for k in range(K)], axis=-1)  # (m,n,K)
    x1_pows = np.stack([x1**j for j in range(J)], axis=-1)  # (m,n,J)
    # Outer via broadcasting: sum_{j,k} Ai[j,k]*x0^k*x1^j
    # (m,n,J,K) = (m,n,J,1)*(m,n,1,K)
    prod = x1_pows[..., :, None] * x0_pows[..., None, :]
    return np.tensordot(prod, Ai, axes=([2,3],[0,1]))  # (m,n)

def maybe_plot(A, args):
    if not args.plot:
        return

    # Delay import so CLI runs fine on headless boxes unless plotting is requested.
    import matplotlib
    # If no display, default to Agg to allow saving without X11.
    if not os.environ.get("DISPLAY") and not args.show:
        matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    # Construct grid
    x = np.linspace(args.x_min, args.x_max, args.samples)
    y = np.linspace(args.y_min, args.y_max, args.samples)
    X, Y = np.meshgrid(x, y)

    # Evaluate f0 and f1 on grid
    if A.shape[0] < 2:
        raise SystemExit("Plotting expects dim=2 (two equations).")
    Z0 = eval_poly_grid(A[0], X, Y)
    Z1 = eval_poly_grid(A[1], X, Y)

    fig, ax = plt.subplots(figsize=(6.5, 5.5), dpi=args.dpi)

    # Zero-level contours for f0 (solid) and f1 (dashed)
    c0 = ax.contour(X, Y, Z0, levels=[0.0], linewidths=2.0, linestyles='solid')
    c1 = ax.contour(X, Y, Z1, levels=[0.0], linewidths=2.0, linestyles='dashed')

    ax.clabel(c0, fmt={0.0: "f0=0"}, inline=True, fontsize=9)
    ax.clabel(c1, fmt={0.0: "f1=0"}, inline=True, fontsize=9)

    # Highlight near-intersection pixels where both |f| <= tol
    if args.abs_tol is not None and args.abs_tol > 0:
        mask = (np.abs(Z0) <= args.abs_tol) & (np.abs(Z1) <= args.abs_tol)
        # Subsample to avoid overplot
        step = max(1, args.samples // 200)
        yy, xx = np.where(mask)
        if yy.size:
            ax.scatter(X[yy[::step], xx[::step]], Y[yy[::step], xx[::step]],
                       s=10, marker='o', facecolors='none', edgecolors='k',
                       linewidths=0.6, label=f"|f0|,|f1| ≤ {args.abs_tol:g}")

    ax.set_xlabel("x0")
    ax.set_ylabel("x1")
    ax.set_title(f"Zero-level contours: f0 (solid), f1 (dashed)\n"
                 f"deg={args.deg} test={args.test}")
    ax.grid(True, alpha=0.25)
    ax.legend(loc="best")

    if args.save:
        os.makedirs(os.path.dirname(args.save) or ".", exist_ok=True)
        fig.savefig(args.save, bbox_inches="tight")
        print(f"[plot] saved → {args.save}")

    if args.show:
        plt.show()

def main():
    p = argparse.ArgumentParser(description="Inspect coefficients for a given degree/test.")
    p.add_argument("--deg", type=int, required=True, help="Degree (e.g., 2..100)")
    p.add_argument("--test", type=int, required=True, help="1-based test index (e.g., 1..300)")
    p.add_argument("--dim", type=int, default=2, help="Dimension (default: 2)")
    p.add_argument("--nonzero", type=int, default=3, help="Nonzero monomials per f_i besides constant (default: 3)")
    p.add_argument("--coeffs-root", default="coeffs", help="Root folder where .npy files live (default: coeffs)")
    p.add_argument("--json", action="store_true", help="Also print a JSON dump of nonzero terms")
    p.add_argument("--eval-x0", type=float, default=0.3, help="x0 for evaluation (default: 0.3)")
    p.add_argument("--eval-x1", type=float, default=0.3, help="x1 for evaluation (default: 0.3)")

    # ---- NEW plotting options ----
    p.add_argument("--plot", action="store_true", help="Plot zero-level contours to visualize intersections")
    p.add_argument("--x-min", type=float, default=-1.0, help="Plot range: x0 min (default: -1)")
    p.add_argument("--x-max", type=float, default= 1.0, help="Plot range: x0 max (default: 1)")
    p.add_argument("--y-min", type=float, default=-1.0, help="Plot range: x1 min (default: -1)")
    p.add_argument("--y-max", type=float, default= 1.0, help="Plot range: x1 max (default: 1)")
    p.add_argument("--samples", type=int, default=400, help="Grid resolution per axis (default: 400)")
    p.add_argument("--abs-tol", type=float, default=1e-3, help="Mark points where both |f0|,|f1| ≤ tol (default: 1e-3)")
    p.add_argument("--save", type=str, default="", help="If set, save plot to this path (e.g., plots/deg3_t44.png)")
    p.add_argument("--show", action="store_true", help="Show an interactive window (if possible)")
    p.add_argument("--dpi", type=int, default=140, help="Figure DPI (default: 140)")

    args = p.parse_args()

    arr, path = load_coeffs(args.coeffs_root, args.dim, args.deg, args.nonzero)
    ntests = arr.shape[0]
    if args.test < 1 or args.test > ntests:
        raise SystemExit(f"Requested test {args.test} out of range 1..{ntests}")

    A = arr[args.test - 1]  # shape: (dim, deg+1, deg+1) for dim=2
    if args.dim != 2:
        raise SystemExit("This inspector currently assumes dim=2 (variables x0, x1).")

    degp1 = args.deg + 1
    if A.shape != (args.dim, degp1, degp1):
        raise SystemExit(f"Unexpected per-function tensor shape {A.shape}, expected ({args.dim},{degp1},{degp1}).")

    print(f"# Loaded: {path}")
    print(f"# Shape: {arr.shape}  (num_tests, dim, deg+1, deg+1) = ({ntests}, {args.dim}, {degp1}, {degp1})")
    print(f"# Inspecting: degree={args.deg}, test={args.test}")
    print()

    x_eval = (args.eval_x0, args.eval_x1)

    all_json = []
    for i in range(args.dim):
        Ai = A[i]
        terms = nonzero_terms(Ai)
        poly_str = poly_to_string(terms, varnames=("x0","x1"))
        val = eval_poly(Ai, x_eval)

        c_recomp, mindeg = compute_min_degree_constant(Ai, x_eval)
        c_actual = float(Ai[0,0])

        print(f"=== f{i}(x0,x1) ===")
        print(f"Constant term A[{i},0,0]      : {c_actual:.17g}")
        print(f"Min-degree-only c (recomputed): {c_recomp:.17g}  (using min total degree = {mindeg})")
        print(f"Difference (actual - recomputed): {c_actual - c_recomp:.17g}")
        print(f"Nonzero term count             : {len(terms)}")
        print(f"Evaluate f{i} at (x0,x1) = {x_eval}: {val:.17g}")
        print("Polynomial:")
        print(f"  f{i}(x0,x1) = " + poly_str)
        print()

        if args.json:
            all_json.append({
                "function": i,
                "constant_actual": c_actual,
                "constant_min_degree_recomputed": c_recomp,
                "min_total_degree_used": mindeg,
                "eval_point": {"x0": x_eval[0], "x1": x_eval[1]},
                "value_at_eval_point": val,
                "terms": [{"j": int(j), "k": int(k), "coef": float(c)} for (j,k,c) in terms]
            })

    if args.json:
        print(json.dumps({"degree": args.deg, "test": args.test, "dim": args.dim,
                          "nonzero": args.nonzero, "coeffs_file": path,
                          "functions": all_json}, indent=2))

    # Plot last (so text appears even if plotting fails)
    maybe_plot(A, args)

if __name__ == "__main__":
    main()