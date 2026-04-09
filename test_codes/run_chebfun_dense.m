addpath('chebfun');
cheb.xy;

% User‐configurable parameters
dim       = 2;
nonZero   = 3;
numTests  = 300;

minDeg    = 26;
maxDeg    = 50;
batch_num = 2;

% === Directory layout (with batch_num in summary files) ===
baseDir = sprintf("chebfun_results/dim%d/nonzero%d", dim, nonZero);
if ~exist(baseDir, 'dir'), mkdir(baseDir); end

% Open summary files in append mode (per batch_num)
time_fid    = fopen(fullfile(baseDir, sprintf("avg_times_%d.txt",   batch_num)), 'a');
avg_res_fid = fopen(fullfile(baseDir, sprintf("avg_resids_%d.txt",  batch_num)), 'a');
max_res_fid = fopen(fullfile(baseDir, sprintf("max_resids_%d.txt",  batch_num)), 'a');
sum_res_fid = fopen(fullfile(baseDir, sprintf("sum_resids_%d.txt",  batch_num)), 'a');
num_roots_fid = fopen(fullfile(baseDir, sprintf("num_roots_%d.txt", batch_num)), 'a');

for deg = minDeg:maxDeg
    % Per-degree dir (for per-test roots)
    degDir = fullfile(baseDir, sprintf("deg%d", deg));
    if ~exist(degDir, 'dir'), mkdir(degDir); end

    % Load coefficients
    coeffFile = sprintf("mathematica_coeffs/dim%d/deg%d/num%d.txt", dim, deg, nonZero);
    txt = fileread(coeffFile);

    % === Cleanup ===
    txt = replace(txt, "][", " ");
    txt = replace(txt, ["[", "]"], "");
    txt = replace(txt, ",", " ");
    tok = split(strtrim(txt));
    A   = str2double(tok);
    assert(~any(isnan(A)), "Found NaNs in A—text parsing went awry!");

    blockSize  = dim * (deg+1)^dim;
    all_times  = nan(1, numTests);
    all_resids = [];
    all_num_roots = zeros(1, numTests);

    for test = 1:numTests
        baseIdx = (test-1) * blockSize;
        B = A(baseIdx + (1:(deg+1)^dim));
        C = A(baseIdx + (deg+1)^dim + (1:(deg+1)^dim));

        % Build F, G
        F = @(x,y) 0;  G = @(x,y) 0;
        for i = 1:(deg+1)
            for j = 1:(deg+2-i)
                idx = (i-1)*(deg+1) + j;
                Fprev = F; Gprev = G;
                F = @(x,y) Fprev(x,y) + B(idx) * y.^(i-1) .* x.^(j-1);
                G = @(x,y) Gprev(x,y) + C(idx) * y.^(i-1) .* x.^(j-1);
            end
        end

        try
            tStart = tic;
            roots_ = roots([chebfun2(F); chebfun2(G)], 'resultant');
            all_times(test) = toc(tStart);
        catch ME
            warning("Skipping deg %d test %d: %s", deg, test, ME.message);
            roots_ = zeros(0,2); % no roots recorded
        end

        % Residuals and root count
        for k = 1:size(roots_,1)
            all_resids(end+1) = abs(F(roots_(k,1), roots_(k,2)));
            all_resids(end+1) = abs(G(roots_(k,1), roots_(k,2)));
        end
        all_num_roots(test) = size(roots_,1);

        % Write roots for this test to .../deg{deg}/roots_test{test}.txt
        rootFile = fullfile(degDir, sprintf("roots_test%d.txt", test));
        fid = fopen(rootFile, 'a'); % append mode per test
        if fid < 0
            warning("Could not open %s for appending.", rootFile);
        else
            if ~isempty(roots_)
                for k = 1:size(roots_,1)
                    fprintf(fid, '%.17g %.17g\n', roots_(k,1), roots_(k,2));
                end
            else
                fprintf(fid, "# (no roots)\n");
            end
            fclose(fid);
        end

        if mod(test,10) == 0
            fprintf("deg %d: %d/%d tests completed\n", deg, test, numTests);
        end
    end

    % ---- Per-degree summaries (append one line to each file) ----
    valid = ~isnan(all_times);
    perDegTime = mean(all_times(valid));
    perDegAvg  = mean(all_resids);
    perDegMax  = max(all_resids);
    perDegSum  = sum(all_resids);

    fprintf(time_fid,    '%.17g\n', perDegTime);
    fprintf(avg_res_fid, '%.17g\n', perDegAvg);
    fprintf(max_res_fid, '%.17g\n', perDegMax);
    fprintf(sum_res_fid, '%.17g\n', perDegSum);

    % num_roots: one line per degree with numTests integers
    fprintf(num_roots_fid, '%d', all_num_roots(1));
    for t = 2:numTests
        fprintf(num_roots_fid, ' %d', all_num_roots(t));
    end
    fprintf(num_roots_fid, '\n');
end

fclose(time_fid);
fclose(avg_res_fid);
fclose(max_res_fid);
fclose(sum_res_fid);
fclose(num_roots_fid);

exit;