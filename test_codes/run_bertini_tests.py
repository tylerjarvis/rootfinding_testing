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
    for i in range(len(A)):
        mystr += ' x' + str(i) + ','
    mystr = mystr[:-1]
    mystr += ';\n'
    for i in range(len(A)):
        mystr += 'f' + str(i) + " = "
        for j in range(len(A[i])):
            for k in range(len(A[i][j])-j):
                # for l in range(len(A[i][j][k]) - j - k):
                #     for m in range(len(A[i][j][k][l]) - j - k - l):
                if j==0 and k==0: #and l == 0 and m ==0:
                    continue
                mystr += str(A[i][j][k]) + '*x0^' + str(k) + '*x1^' + str(j) + ' + '#+ '*x2^' + str(l) + '*x3^' + str(m) + ' + '
        mystr = mystr[:-3] + ';\n'
    mystr += 'END;'
    f.write(mystr)



dim = 2

times_file = "bertini_results/dim{}_avg_times.npy".format(dim)
avg_times = np.array([])
avg_resids = np.array([])
max_resids = np.array([])
 

for deg in range(2,3):
    times = np.array([])
    resids = np.array([])
    # coeffs = np.load("coeffs/dim{}_deg{}_randn.npy".format(dim,deg))
    coeffs = np.load("coeffs/example_sparse.npy")
    num_tests = len(coeffs)
    # print(num_tests)
    # 9/0
    for test in range(num_tests):
        # print(coeffs[test])
        set_up_input(coeffs[test])
        start = time()
        run(["BertiniLinux64_v1.6/bertini","BertiniLinux64_v1.6/input"])
        t = time() - start
        os.rename("real_finite_solutions","bertini_results/example_test{}_roots.txt".format(test+1))
        times = np.append(times,t)

    avg_times = np.append(avg_times,np.mean(times))
    np.save(times_file, avg_times)





createdFiles = ['failed_paths','main_data','finite_solutions','midpath_data','nonsingular_solutions',
               'raw_solutions','raw_data','output','singular_solutions',
               'start']
for file in createdFiles:
    os.remove(file)