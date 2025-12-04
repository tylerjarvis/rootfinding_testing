using Pkg
using DynamicPolynomials
using NPZ
using DelimitedFiles
using Statistics
using EigenvalueSolver


dim = 2
edit_degs = [2]
# Edit dimension 5 systems
tol = 10^-14
degs = edit_degs
@polyvar x[1:dim]
times_file = open("telen_results/dim$(dim)_avg_times.txt","w")
max_resids_file = open("telen_results/dim$(dim)_max_resids.txt","w")
avg_resids_file = open("telen_results/dim$(dim)_avg_resids.txt","w")
sum_resids_file = open("telen_results/dim$(dim)_sum_resids.txt","w")
for deg in degs
    times_file = open("telen_results/dim$(dim)_avg_times.txt","a")
    avg_resids_file = open("telen_results/dim$(dim)_avg_resids.txt","a")
    max_resids_file = open("telen_results/dim$(dim)_max_resids.txt","a")
    sum_resids_file = open("telen_results/dim$(dim)_sum_resids.txt","a")
    all_res = []
    timer = 0;
    # coeffs = npzread("coeffs/dim$(dim)_deg$(deg)_randn.npy");
    coeffs = npzread("coeffs/example_sparse.npy");
    basis = [x[1]^i*x[2]^j for i in 0:deg for j in 0:deg];
    reps = size(coeffs)[1];
    A = []
    Q = []
    bad_tests = []
    #minimize compilation time error by running a few tests without times
    for i in 1:10
        coeffs[i,1,1,1] = 0
        coeffs[i,2,1,1] = 0
        # coeffs[i,3,1,1] = 0
        # coeffs[i,4,1,1] = 0
        f = [vec(coeffs[i, j, :, :])' * basis for j in 1:dim];
        EigenvalueSolver.solve_CI_dense(f,x);
    end
    for i in 1:reps
        println("running deg $(deg) test $(i)")
        coeffs[i,1,1,1] = 0
        coeffs[i,2,1,1] = 0
        # coeffs[i,3,1,1] = 0
        # coeffs[i,4,1,1] = 0
        f = [vec(coeffs[i, j, :, :])' * basis for j in 1:dim];
        ans = @timed EigenvalueSolver.solve_CI_dense(f,x);
        A = ans.value;
        timer += ans.time;
        mymask = fill(true,length(A));
        for j= 1:length(A)
            if abs(imag(A[j][1]))>tol || abs(imag(A[j][2]))>tol #|| abs(imag(A[j][3]))>tol || abs(imag(A[j][4]))>tol
                mymask[j] = false
            end
        end
        A = A[mymask]
        A = real(A)
        mymask = fill(true,length(A))
        for j=1:length(A)
            if A[j][1]>=1 || A[j][1]<=-1 || A[j][2]>=1 || A[j][2]<=-1# || A[j][3]>=1 || A[j][3]<=-1 || A[j][4]>=1 || A[j][4]<=-1
                mymask[j] = false
            end
        end
        Q = A[mymask]
        for j=1:length(Q)
            append!(all_res,abs(real(f[1](x[1]=>Q[j][1],x[2]=>Q[j][2]))));
            append!(all_res,abs(real(f[2](x[1]=>Q[j][1],x[2]=>Q[j][2]))));
            # append!(all_res,abs(real(f[3](x[1]=>Q[j][1],x[2]=>Q[j][2]))));
            # append!(all_res,abs(real(f[4](x[1]=>Q[j][1],x[2]=>Q[j][2]))));
            if abs(real(f[1](x[1]=>Q[j][1],x[2]=>Q[j][2]))) > 1e-6 || abs(real(f[2](x[1]=>Q[j][1],x[2]=>Q[j][2]))) > 1e-6 #|| abs(real(f[3](x[1]=>Q[j][1],x[2]=>Q[j][2],x[3]=>Q[j][3],x[4]=>Q[j][4]))) > 1e-6
                append!(bad_tests,i);
            end
        end
        # writedlm("telen_results/$(dim)d_all/dim$(dim)_deg$(deg)_test$(i)_roots_randn.txt",Q)
        writedlm("telen_results/example_roots$(i).txt",Q)
    end
    timings = timer/reps
    avg_res = mean(all_res)
    max_res = maximum(all_res)
    sum_res = sum(all_res)
    writedlm("telen_results/$(dim)d_deg$(deg)_redo_tests.txt",bad_tests)
    write(times_file,string(deg) * " " * string(timings) * "\n")
    write(avg_resids_file,string(deg) * " " * string(avg_res) * "\n")
    write(max_resids_file,string(deg) * " " * string(max_res) * "\n")
    write(sum_resids_file,string(deg) * " " * string(sum_res) * "\n")
    close(times_file)
    close(avg_resids_file)
    close(max_resids_file)
    close(sum_resids_file)
end
close(times_file)
close(avg_resids_file)
close(max_resids_file)
close(sum_resids_file)