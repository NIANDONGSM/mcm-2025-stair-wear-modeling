% Load data and check data structure
clear all;
load('xyd.mat');
data = ans; 
x = data(:,1);
d = data(:,3); 

% ==== Data Preprocessing ====
% 1. Ensure non-negative depression depth
if any(d < 0)
    warning('Negative depression depths detected, automatically taking absolute values');
    d = abs(d); 
end

% ==== Parameter Settings ====
N_bins = 200;        % Number of horizontal bins
a = 1;               % Wear amount per tread (must be positive)
assert(a > 0, 'Parameter a must be positive');

% ==== Coordinate Normalization ====
x_min = min(x);
x_max = max(x);
x_normalized = (x - x_min) / (x_max - x_min + eps);  % Avoid division by zero

% ==== Binning and Statistics ====
edges = linspace(0, 1, N_bins+1);
[~, ~, bin] = histcounts(x_normalized, edges);

% Calculate total depression depth per bin (enforce non-negative)
D = accumarray(bin, d, [N_bins 1], @sum, 0); 
D(D < 0) = 0;  % Secondary validation

% ==== Calculate Tread Count ====
N_i = D / a;
% Handle zero/negative values
N_i(N_i <= 0) = eps;    % Replace with small positive value
N_i(isnan(N_i)) = eps;  % Handle NaN
N_i(isinf(N_i)) = eps;  % Handle Inf

% ==== Prepare Regression Data ====
% Identify valid bins (excluding all-zero bins)
valid_bins = (D > 0);  
x_centers = (edges(1:end-1) + edges(2:end)) / 2;
x_centers = x_centers(valid_bins)';
N_i = N_i(valid_bins);

% ==== Poisson Regression Fitting ====
[beta, ~, stats] = glmfit(x_centers(:), N_i, 'poisson', 'link', 'log');

% ==== Direction Preference Testing ====
beta1 = beta(2);
se_beta1 = stats.se(2);
Z = beta1 / se_beta1;
p_value = 2 * (1 - normcdf(abs(Z)));

% ==== Result Output ====
disp('===== Analysis Results =====');
fprintf('Baseline tread rate beta0: %.4f\n', beta(1));
fprintf('Position coefficient beta1: %.4f (SE=%.4f)\n', beta1, se_beta1);
fprintf('Wald test: Z=%.4f, p=%.4f\n', Z, p_value);

if abs(Z) > 1.96
    fprintf('Conclusion: Significant directional preference (');
    if beta1 < 0
        fprintf('Front-end usage is more frequent)\n');
    else
        fprintf('Rear-end usage is more frequent)\n');
    end
else
    fprintf('Conclusion: No significant directional preference\n');
end

% ==== Visualization ====
xx = linspace(0,1,100);
lambda = exp(beta(1) + beta(2)*xx);
figure
plot(xx, lambda, 'LineWidth', 2)
hold on
scatter(x_centers, N_i, 40, 'filled', 'MarkerFaceAlpha',0.5)
xlabel('Normalized Position'), ylabel('Predicted Tread Rate')
title('Spatial Distribution of Tread Rate')
legend('Model Prediction', 'Observed Values')
grid on
