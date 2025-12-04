include("Julia-Rootfinding/src/CombinedSolver.jl")
using NPZ
using DelimitedFiles
using Statistics

dim = 2
degs = 2:2

open("jroots_results/july7/dim$(dim)_avg_times.txt","w")
open("jroots_results/july7/dim$(dim)_avg_resids.txt","w")
open("jroots_results/july7/dim$(dim)_max_resids.txt","w")
open("jroots_results/july7/dim$(dim)_sum_resids.txt","w")
for deg in degs
    times_file = open("jroots_results/july7/dim$(dim)_avg_times.txt","a")
    avg_resids_file = open("jroots_results/july7/dim$(dim)_avg_resids.txt","a")
    max_resids_file = open("jroots_results/july7/dim$(dim)_max_resids.txt","a")
    sum_resids_file = open("jroots_results/july7/dim$(dim)_sum_resids.txt","a")
    all_res = []
    timer = 0;
    # coeffs = npzread("coeffs/dim$(dim)_deg$(deg)_randn.npy");
    coeffs = npzread("coeffs/example_sparse.npy")
    reps = size(coeffs)[1]; # should be 300
    A = []
    #minimize compilation time error by running a few tests without times
    for i in 1:10
        for idx in 1:dim
            coeffs[i,idx,Int.(ones(dim))...] = 0
        end
        f = [MultiPower(to_python(coeffs[i, j, :, :])) for j in 1:dim];  #edit line: match number of colons to dim
        solve(f,-ones(dim),ones(dim))
    end
    for i in 1:reps
        if i%10 == 0 || true
            println("running deg $(deg) test $(i)")
        end
        for idx in 1:dim
            coeffs[i,idx,Int.(ones(dim))...] = 0
        end
        #coeffs[i,1,1,1,1,1] = 0
        #coeffs[i,2,1,1,1,1] = 0
        #coeffs[i,3,1,1,1,1] = 0
        #coeffs[i,4,1,1,1,1] = 0
        f = [MultiPower(to_python(coeffs[i, j, :, :])) for j in 1:dim];  #edit line: match number of colons to dim
        ans = @timed solve(f,-ones(dim),ones(dim))
        A = ans.value;
        timer += ans.time;
        for j=1:length(A)
            for idx in 1:dim
                append!(all_res,abs(eval_MultiPower(f[idx], A[j])))
            end
        end
        writedlm("jroots_results/example_roots_test$(i).txt",A)
    end
    timings = timer/(reps-1)
    avg_res = mean(all_res)
    max_res = maximum(all_res)
    sum_res = sum(all_res)
    write(times_file,string(timings) * "\n")
    write(avg_resids_file,string(avg_res) * "\n")
    write(max_resids_file,string(max_res) * "\n")
    write(sum_resids_file,string(sum_res) * "\n")
    close(times_file)
    close(avg_resids_file)
    close(max_resids_file)
    close(sum_resids_file)
end