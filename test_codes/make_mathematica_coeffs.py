import numpy as np
import sys
import json
import os
np.set_printoptions(threshold=sys.maxsize)
np.set_printoptions(linewidth=np.inf)

dim = 5
mindeg = 2
maxdeg = 10

for i in range(mindeg, maxdeg + 1):
    data = np.load(f"../sparse/coeffs/dim{dim}/deg{i}/num3.npy")
    filedir = f"../sparse/coeffs_mathematica_json/dim{dim}/deg{i}"

    os.makedirs(filedir, exist_ok=True)

    filepath = os.path.join(filedir, "num3.txt")

    with open(filepath, "w") as f:
        json.dump(data.tolist(), f)
        print(f"Written for dim {dim} deg", i)

    # f = open(filepath, "w")
    # f.write(str(data))
    # print(f"Written for dim {dim} deg", i)