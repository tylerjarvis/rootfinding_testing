addpath('chebfun');
cheb.xy;

formatSpec = '%s\n';

dim = 2;

maxDeg = 100;
numTests = 300;
nonZero = 3;

time_fid = fopen("chebfun_results/dim"+dim+"_avg_times.txt",'w');
avg_res_fid = fopen("chebfun_results/dim"+dim+"_avg_resids.txt",'w');
max_res_fid = fopen("chebfun_results/dim"+dim+"_max_resids.txt",'w');
sum_res_fid = fopen("chebfun_results/dim"+dim+"_sum_resids.txt",'w');

for deg = 2:maxDeg
myFile = "mathematica_coeffs/example_sparse.txt";
A = fileread(myFile);
A = replace(A,"]["," ");
rep = ["[","]"];
A = replace(A,rep,"");
A = strip(A);
A = [strings(0);split(A)];
A= double(A);
all_times = [];
all_resids = [];

for test = 1:numTests
B = A((test-1)*dim*(deg+1)^dim+1:(test-1)*dim*(deg+1)^dim+(deg+1)^2);
C = A((test-1)*dim*(deg+1)^dim+(deg+1)^dim+1:(test-1)*dim*(deg+1)^dim+(deg+1)^dim+(deg+1)^2);
F = @(x,y) 0;
G = @(x,y) 0;
for i=1:deg+1
    for j=1:deg+2-i
        if i~=1 || j~=1
            F = @(x,y) F(x,y) + B((i-1)*(deg+1)+j)*(y.^(i-1)).*(x.^(j-1));
            G = @(x,y) G(x,y) + C((i-1)*(deg+1)+j)*(y.^(i-1)).*(x.^(j-1));
        end
    end
end
start_time = tic;
my_roots = roots([chebfun2(F);chebfun2(G)],'resultant');
end_time = toc(start_time);
all_times(end+1) = end_time;

for i=1:size(my_roots,1)
    all_resids(end+1) = abs(F(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(G(my_roots(i,1),my_roots(i,2)));
end

writematrix(my_roots,"chebfun_results/example_roots" + test +".txt",'Delimiter',' ');
if test/10 == floor(test/10)
    disp("deg "+deg+": "+test+" tests completed");
end
end
avg_time = sum(all_times)/length(all_times);
fprintf(time_fid,formatSpec,avg_time);
avg_resid = sum(all_resids)/length(all_resids);
max_resid = max(all_resids);
sum_resid = sum(all_resids);
fprintf(avg_res_fid,formatSpec,avg_resid);
fprintf(max_res_fid,formatSpec,max_resid);
fprintf(sum_res_fid,formatSpec,sum_resid);

end
fclose('all');
exit;