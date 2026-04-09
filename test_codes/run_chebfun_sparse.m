addpath('../chebfun');
cheb.xy;

% User‐configurable parameters
dim       = 2;
nonZero   = 3;
numTests  = 100;

minDeg    = 2;
maxDeg    = 30;

% === Directory layout (with batch_num in summary files) ===
baseDir = sprintf("../sparse/results/chebfun_results/dim%d/nonzero%d", dim, nonZero);
if ~exist(baseDir, 'dir'), mkdir(baseDir); end

% Open summary files in append mode
time_fid    = fopen(fullfile(baseDir, "avg_times.txt"), 'w');
avg_res_fid = fopen(fullfile(baseDir, "avg_resids.txt"), 'w');
max_res_fid = fopen(fullfile(baseDir, "max_resids.txt"), 'w');
sum_res_fid = fopen(fullfile(baseDir, "sum_resids.txt"), 'w');
num_roots_fid = fopen(fullfile(baseDir, "num_roots.txt"), 'w');

for deg = minDeg:maxDeg
    % Per-degree dir (for per-test roots)
    degDir = fullfile(baseDir, sprintf("deg%d", deg));
    if ~exist(degDir, 'dir'), mkdir(degDir); end

    % Load coefficients
    coeffFile = sprintf("../sparse/coeffs_mathematica_json/dim%d/deg%d/num%d.txt", dim, deg, nonZero);
    txt = fileread(coeffFile);
    A = jsondecode(txt);

    numTests = min(numTests, size(A,1));

    all_times  = nan(1, numTests);
    all_resids = [];
    all_num_roots = zeros(1, numTests);

    for test = 1:numTests
        F_coeffs = squeeze(A(test, 1, :, :));
        G_coeffs = squeeze(A(test, 2, :, :));

        % Create evaluators (support scalar or array x,y; elementwise)
        F = @(x,y) evalSparse2D(F_coeffs, x, y);
        G = @(x,y) evalSparse2D(G_coeffs, x, y);

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

% ---- helper function ----
function val = evalSparse2D(T, x, y)
    % T: nTerms x 3, columns are [x_exp, y_exp, coeff]
    xe = T(:,1);
    ye = T(:,2);
    c  = T(:,3);

    % elementwise evaluation, same size output as x and y
    val = zeros(size(x));
    for k = 1:numel(c)
        val = val + c(k) .* (x.^xe(k)) .* (y.^ye(k));
    end
end