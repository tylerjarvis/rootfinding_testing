import numpy as np
from matplotlib import pyplot as plt
import matplotlib.ticker as mticker
import os


def stacktoarray(list):
    list = list.replace(" ", "")
    list = list.replace("*^", "e")
    list = list.split("\n")
    while list[-1] == "":
        list.pop()
    for i in range(len(list)):
        list[i] = abs(float(list[i]))
    return list

args = ["avg_times", "avg_resids", "max_resids", "sum_resids"]
names = ["Average Times", "Average Residuals", "Max Residuals", "Sum of Residuals"]
dims = [4]
plt.rcParams['figure.dpi'] = 400

for dim in dims:
    for v, arg in enumerate(args):
        # Read data of each method
        YR = open("results/yroots_results/nov1/dim{}_{}_randn.txt".format(dim, arg))
        YR = stacktoarray(YR.read())
        YR = YR[:9]

        JR = open("results/jroots_results/nov1/dim{}_{}.txt".format(dim, arg))
        JR = stacktoarray(JR.read())
        JR = JR[:9]

        TR = open("results/telen_results/dim{}_{}.txt".format(dim, arg))
        TR = stacktoarray(TR.read())

        if arg == "avg_times":
            BR = np.load("results/bertini_results/dim{}_{}.npy".format(dim, arg))
        else:
            BR = open("results/bertini_results/dim{}_{}.txt".format(dim, arg))
            BR = stacktoarray(BR.read())

        if dim in [2, 3]:
            NR = open("results/NSolveValues_results/dim{}_{}2_cont.txt".format(dim, arg))
        else:
            NR = open("results/NSolveValues_results/dim{}/{}.txt".format(dim, arg))
        NR = stacktoarray(NR.read())

        if False and arg != "avg_times":
            NRM = np.load("results/NSolveValues_results/dim2_missing_roots.npy")
            NRD = np.load("results/NSolveValues_results/dim2_double_roots.npy")

        RR = open("results/reduce_results/dim{}_{}.txt".format(dim, arg))
        RR = stacktoarray(RR.read())

        if dim == 2:
            CR = open("results/chebfun_results/dim{}_{}.txt".format(dim, arg))
            CR = stacktoarray(CR.read())

        # Graph each data
        line_args = [YR, TR, BR, NR, RR, JR]
        labels = ["Yroots", "MTV", "Bertini", "NSolveValues", "Reduce", "Jroots"]
        colors = ["royalblue", "tab:purple", "tab:green", "tab:red", "m", "navy"]

        if dim == 2:
            line_args.append(CR)
            labels.append("Chebfun")
            colors.append("tab:orange")
        
        fig, ax1 = plt.subplots()
        ax1.set_yscale("log")
        for i in range(len(line_args)):
            X = np.arange(2, min(len(line_args[i]), 30) + 2)
            ax1.plot(X, line_args[i], colors[i], label=labels[i])
        if arg == "avg_times":
            ax1.set_ylabel("Time Log Scale")
        else:
            # ax1.set_ylim(1e-17,1)
            ax1.set_ylabel("Residual")
        plt.title("Dim {} {}".format(dim, names[v]))
        ax1.set_xlabel("Degree")
        ax1.xaxis.set_major_locator(mticker.MaxNLocator(integer=True))
        ax1.legend()
        #plt.savefig(
        #    "graphs/dim{}_{}.pdf".format(dim, arg), dpi=300, bbox_inches="tight"
        #)

        os.makedirs(f"../graphs/dim{dim}", exist_ok=True)

        plt.savefig("../graphs/dim{}/dim{}_{}.png".format(dim, dim, arg))
        plt.clf()

    # Currently Unused Code
 
    # X = np.arange(2,min(len(NRM),30)+2)
    # plt.plot(X,NRM,":r",label="NSolveValues Missing Roots")
    # plt.plot(X,NRD,"-.r",label="NSolveValues Double Roots")
    # plt.legend()
    # plt.ylim(0,300)
    # plt.savefig("graphs/dim{}_NSolve_bad.png".format(dim))
    # plt.clf()
