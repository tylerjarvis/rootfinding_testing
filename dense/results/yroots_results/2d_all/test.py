T = open("dim2_deg2_roots_randn.txt")
A = T.read()
A = A.replace(" ","")
A = A.replace("\n","")
A = A.replace(")","")
A=A.replace("array(","")
A = A.split("]],[[")
for item in A:
    item = item.split("],[")
for item in A:
    for item2 in item:
        item2 = item2.replace("]","")
        item2 = item2.replace("[","")
        item2 = item2.split(",")

print(A[0])
