import numpy as np
from subprocess import run
import os
from time import time

def set_up_input(A):
    f = open("BertiniLinux64_v1.6/input",'w')
    mystr = 'CONFIG\nSECURITYMAXNORM: 1;\nEND;\nINPUT\nfunction'

    for i in range(len(A)):
        mystr += ' f'+str(i) + ','
    mystr = mystr[:-1]

    mystr += ';\nvariable_group'
    # if len(A) > 2:
    #     # ERROR here
    for i in range(len(A)):
        mystr += ' x' + str(i) + ','
    mystr = mystr[:-1]

    mystr += ';\n'
    for i in range(len(A)):
        mystr += 'f' + str(i) + " = "
        for j in range(len(A[i])):
            for k in range(len(A[i][j])-j):
                if A[i][j][k] == 0:
                    continue
                mystr += str(A[i][j][k]) + '*x0^' + str(k) + '*x1^' + str(j) + ' + '
        mystr = mystr[:-3] + ';\n'
    mystr += 'END;'
    f.write(mystr)

dim = 2
maxdeg = 100
nonzero = 3
num_tests = 300

times_file = "bertini_results/dim{}/nonzero{}/dim{}_nz{}_avg_times.npy".format(dim,nonzero,dim,nonzero)
avg_times = np.array([])
avg_resids = np.array([])
max_resids = np.array([])
 

for deg in range(2,maxdeg+1):
    times = np.array([])
    resids = np.array([])
    coeffs = np.load("coeffs/dim{}/deg{}/num{}.npy".format(dim,deg,nonzero))

    for test in range(num_tests):
        set_up_input(coeffs[test])
        start = time()
        run(["BertiniLinux64_v1.6/bertini","BertiniLinux64_v1.6/input"])
        t = time() - start

        sol_file = "real_finite_solutions"
        target = f"bertini_results/dim{dim}/nonzero{nonzero}/roots_test{test+1}.txt"
        if os.path.exists(sol_file):
            os.rename(sol_file, target)
            
        else:
            print(f"[warn] test {test+1}: no '{sol_file}' produced — skipping")
        times = np.append(times, t)

    avg_times = np.append(avg_times,np.mean(times))
    np.save(times_file, avg_times)

createdFiles = ['failed_paths','main_data','finite_solutions','midpath_data','nonsingular_solutions',
               'raw_solutions','raw_data','output','singular_solutions',
               'start']

for fname in createdFiles:
    if os.path.exists(fname):
        os.remove(fname)