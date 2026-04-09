from yroots import MultiPower
import yroots as yr
import numpy as np
from time import time
import sys



def residuals(dim, funcs, roots):
    residuals = []
    for i in range(dim):
        resids_fi = []
        for j in range(len(roots)):
            fi_resids = abs(funcs[i].__call__(roots[j]))[0]
            resids_fi.append(fi_resids)
        residuals.append(resids_fi)
    return residuals



def run_test(dim,deg,nonzero,num,roots_only = True):
    coeffs = np.load("coeffs/dim{}/deg{}/num{}.npy".format(dim,deg,nonzero))
    # coeffs = np.load("coeffs/example_sparse.npy")
    a = -np.ones(dim)
    b = np.ones(dim)
    funcs = []
    for coeff in coeffs[num-1]:
        # print(coeff)
        # constant_spot = tuple([0]*dim)
        # coeff[constant_spot] = 0. # set constant term to zero so all systemss go through origin
        funcs.append(MultiPower(coeff)) # this changes coeffs to a list of functions that we can actually call
    # print(funcs
    if (roots_only):
        roots = (yr.solve(funcs,a,b))
        return roots
    else:
        start = time()
        roots = (yr.solve(funcs,a,b))
        t = time()-start
        res = residuals(dim,funcs,roots)
        return (res,roots,t)




if(__name__=="__main__"):


    dim = 2
    maxdeg = 100
    nonzero = 7
    a = -np.ones(dim)
    b = np.ones(dim)
    # times_file = open("yroots_results/july7/dim{}_avg_times_randn.txt".format(dim),"w")
    # max_res_file = open("yroots_results/july7/dim{}_max_resids_randn.txt".format(dim),"w")
    # avg_res_file = open("yroots_results/july7/dim{}_avg_resids_randn.txt".format(dim),"w")
    # sum_res_file = open("yroots_results/july7/dim{}_sum_resids_randn.txt".format(dim),"w")
    times_file = open("yroots_results/roots/dim2/nonzero{}/dim{}_nz{}_avg_times_randn.txt".format(nonzero, dim, nonzero),"w")
    max_res_file = open("yroots_results/roots/dim2/nonzero{}/dim{}_nz{}_max_resids_randn.txt".format(nonzero, dim, nonzero),"w")
    avg_res_file = open("yroots_results/roots/dim2/nonzero{}/dim{}_nz{}_avg_resids_randn.txt".format(nonzero, dim, nonzero),"w")
    sum_res_file = open("yroots_results/roots/dim2/nonzero{}/dim{}_nz{}_sum_resids_randn.txt".format(nonzero, dim, nonzero),"w")
    all_times = list()
    all_res = list()
    run_test(dim,2,nonzero,1)
    for deg in range(2,maxdeg+1):
        print(f"--- Starting degree {deg}/{maxdeg} ---")
        all_times = []
        all_res = np.array([])
        num_tests=300
        # num_tests=10
        for test in range(num_tests):
            if((test+1)/10 == int((test+1)/10)):
                print(f'Dim {dim} Deg {deg}: running test {test+1}/{num_tests}')
            (res,roots,t) = run_test(dim,deg,nonzero,test+1,False)
            all_times.append(t)
            all_res = np.append(all_res,res)
            # roots_file = "yroots_results/{}d_all/deg{}/test{}_roots_randn.npy".format(dim,deg,test+1)
            roots_file = "yroots_results/roots/dim2/nonzero{}/roots_test{}.npy".format(nonzero, test+1)
            np.save(roots_file,roots)

        all_res = all_res.flatten()
        avg_res = sum(all_res)/len(all_res)
        sum_res = sum(all_res)
        max_res_file.write(str(max(all_res))+"\n")
        avg_res_file.write(str(avg_res)+"\n")
        sum_res_file.write(str(sum_res)+"\n")
        avg_time = sum(all_times)/len(all_times)
        times_file.write(str(avg_time)+"\n")