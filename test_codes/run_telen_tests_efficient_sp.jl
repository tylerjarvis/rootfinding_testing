using Pkg
using DynamicPolynomials
using NPZ
using DelimitedFiles
using Statistics
using EigenvalueSolver
using Printf
using Combinatorics  # for product()

# ------------------ user-config ------------------
dim      = 2
degs     = 2:10          # keep your editable degrees list here
nonzero  = 3            # matches num{nonzero}.npy
numTests = 100
tol      = 1.0e-14      # imag-part tolerance

@polyvar x[1:dim]

# ------------------ output layout (telen_results) ------------------
base_dir = "../sparse/results/telen_results/dim$(dim)/nonzero$(nonzero)"
isdir(base_dir) || mkpath(base_dir)

avg_time_path  = joinpath(base_dir, "avg_times.txt")
max_resid_path = joinpath(base_dir, "max_resids.txt")
avg_resid_path = joinpath(base_dir, "avg_resids.txt")
sum_resid_path = joinpath(base_dir, "sum_resids.txt")

# truncate summary files once
open(avg_time_path,  "w") do _ end
open(max_resid_path, "w") do _ end
open(avg_resid_path, "w") do _ end
open(sum_resid_path, "w") do _ end

# append one numeric value per line (no degree labels)
function append_value(path::AbstractString, v::Real)
    open(path, "a") do io
        @printf(io, "%.17g\n", float(v))
    end
end

# build vector of polynomials from one test
function build_sparse_polys(coeffs, dim::Int, test::Int, nonzero::Int)
    # create a vector of polynomials of length dim
    f = Vector{typeof(x[1])}(undef, dim)

    # iterate iver each dimension
    for func in 1:dim
        # extract monomials and initialize zero monomial to then add to and form term
        poly_data = coeffs[test, func, :,:]
        p = zero(x[1])

        # get number of rows (terms) and then go through each
        rows = size(poly_data, 1)
        for row in 1:rows
            # get exponents and coefficient of the monomial
            exps = poly_data[row, 1:dim]
            coeff = poly_data[row, dim+1]

            # skip zero coefficients (just in case)
            if coeff == 0.0
                continue
            end

            # make sure exponents are integers 
            exps_int = Int.(round.(exps))
            
            # start with coefficient then multiply by every variable times corresponding exponent
            mon = coeff
            for j in 1:dim
                e = exps_int[j]
                if e != 0
                    mon *= x[j]^e
                end
            end
            
            # add to polynomial once finished
            p += mon
        end
        # store full polynomial in its corresponding slot in the vector,
        f[func] = p
    end
    return f
end


println("Program Started!")

for deg in degs
    println("--- Degree $(deg) ---")

    # per-degree roots folder
    out_dir = joinpath(base_dir, "deg$(deg)")
    isdir(out_dir) || mkpath(out_dir)
    roots_test_file = open(joinpath(out_dir, "roots_test.txt"), "w")

    # Load coefficients with the same function you were using
    # Expected shape: (numTests, dim, deg+1, deg+1)
    coeff_path = "../sparse/coeffs/dim$(dim)/deg$(deg)/num$(nonzero).npy"
    coeffs = npzread(coeff_path)   # keep npzread per your request

    # CHECK THIS
    # basis = [prod(x[k]^a[k] for k in 1:dim) for a in Iterators.product(fill(0:deg, dim)...)]
    reps  = min(size(coeffs, 1), numTests)

    # --- warm-up (same structure, no coeff modifications) ---
    for i in 1:min(10, reps)
        # CHECK THIS
        f = build_sparse_polys(coeffs, dim, i, nonzero)
        EigenvalueSolver.solve_CI_dense(f, x)
    end

    timer_sum = 0.0
    all_res   = Float64[]

    for i in 1:reps
        if (i % 10) == 0
            println("  test $(i)/$(reps)")
        end

        # Build polynomials exactly as before
        # CHECK THIS
        f = build_sparse_polys(coeffs, dim, i, nonzero)

        ans = @timed EigenvalueSolver.solve_CI_dense(f, x)
        A   = ans.value
        timer_sum += ans.time

        # (a) nearly real (same strict tolerance check)
        mask = trues(length(A))
        for j in 1:length(A)
            # CHECK This
            # Check for and drop and NaN
            if any(isnan, A[j])
                mask[j] = false
                continue
            end


            for k in 1:dim
                if abs(imag(A[j][k])) > tol
                    mask[j] = false
                    break
                end
            end
        end
        A = A[mask]
        A = real.(A)

        # (b) inside (-1,1) strictly (same as original)
        mask = trues(length(A))
        for j in 1:length(A)
            inside = true
            for k in 1:dim
                v = A[j][k]
                if v ≥ 1 || v ≤ -1
                    inside = false
                    break
                end
            end
            mask[j] = inside
        end
        Q = A[mask]

        # residuals: |f_k(root)|
        for j in 1:length(Q)
            vals = Tuple(Q[j])
            ## move dictionary above
            subs_dict = Dict(x[l] => vals[l] for l in 1:dim)
            for k in 1:dim
                # CHECK THIS
                
                r = abs(real(f[k](subs_dict...)))
                # r = abs(real(f[k](x[1] => vals[1], x[2] => vals[2])))      # Change with dim
                push!(all_res, r)
            end
        end

        # write roots per test with writedlm (text), as before
        if length(Q) == 0
            roots_mat = Array{Float64}(undef, 0, dim)
        else
            roots_mat = Array{Float64}(undef, length(Q), dim)
            for (row, tup) in enumerate(Q)
                for k in 1:dim
                    roots_mat[row, k] = real(tup[k])
                end
            end
        end

        write(roots_test_file, "Test $(i)\n")
        writedlm(roots_test_file, roots_mat)
        write(roots_test_file, "\n")

        #writedlm(joinpath(out_dir, "roots_test$(i).txt"), roots_mat)
    end
    close(roots_test_file)

    # --- summaries computed exactly like your original ---
    # (no special-casing / no NaN/zero fallbacks)
    avg_time  = timer_sum / reps
    avg_res   = mean(all_res)
    max_res   = maximum(all_res)
    sum_res   = sum(all_res)

    append_value(avg_time_path,  avg_time)
    append_value(max_resid_path, max_res)
    append_value(avg_resid_path, avg_res)
    append_value(sum_resid_path, sum_res)
end

println("Program Finished!")