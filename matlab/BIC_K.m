clc,clear;
%% Data Preparation
load('xyd.mat'); 
y_data = ans(:,2); % Extract Y-coordinate column
data = zscore(y_data); % Standardization

%% BIC Calculation & Optimal K Selection
maxK = 8; 
bic = inf(maxK,1); 
color_set = {'#41CA30', '#00B467', '#009B84', '#007F8A', '#00637A', '#2F4858'};

% 增加迭代次数和正则化参数
for k = 1:maxK
    try
        gmm = fitgmdist(data, k, ...
            'CovarianceType', 'diagonal', ...
            'RegularizationValue', 1e-3, ... % 增大正则化值
            'Options', statset('MaxIter',1000), ... % 增加迭代次数
            'Replicates', 5); % 增加重复次数
        bic(k) = gmm.BIC;
    catch
        bic(k) = inf; 
    end
end

[~, optimalK] = min(bic);
fprintf('Optimal components: K = %d\n', optimalK);

%% Visualization
figure('Color','w','Position',[100 100 1200 500])

% BIC Curve
subplot(1,2,1)
plot(1:maxK, bic, 'o-',...
    'Color', color_set{3},...
    'MarkerFaceColor', color_set{2},...
    'MarkerEdgeColor', color_set{4},...
    'LineWidth',1.5)
hold on
plot(optimalK, bic(optimalK), 'p',...
    'Color', color_set{1},...
    'MarkerSize',15,...
    'MarkerFaceColor', color_set{1})
xlabel('Number of Components (K)')
ylabel('BIC Value')
title(sprintf('Optimal K = %d', optimalK))
grid on
set(gca,'XTick',1:maxK)

% GMM Fit Visualization
subplot(1,2,2)
try
    % 使用与BIC阶段相同的协方差类型
    final_gmm = fitgmdist(data, optimalK, ...
        'CovarianceType', 'diagonal', ... % 保持协方差类型一致
        'RegularizationValue', 1e-3, ...
        'Options', statset('MaxIter',1000), ...
        'Replicates', 5);
catch
    error('Final GMM fitting failed. Try reducing K.');
end

% Probability Density
x = linspace(min(data), max(data), 1000)';
pdf_est = pdf(final_gmm, x);

% Histogram and PDF Plot
histogram(data, 50, ...
    'Normalization','pdf',...
    'FaceColor', color_set{5},...
    'EdgeColor','none')
hold on
plot(x, pdf_est, '-',...
    'Color', color_set{1},...
    'LineWidth',2)
xlabel('Standardized Y-coordinate')
ylabel('Probability Density')
title('Gaussian Mixture Model Fit')
legend('Data Distribution','GMM Fit',...
       'Location','northwest')

%% Component Parameters
mu = final_gmm.mu; 
sigma = final_gmm.Sigma; % 直接提取协方差矩阵
weights = final_gmm.ComponentProportion; 

% 确保维度一致性 (针对对角协方差)
if strcmpi(final_gmm.CovarianceType, 'diagonal')
    sigma = squeeze(sigma)'; % 转换为 [K×1] 向量
end

fprintf('\n=== Gaussian Component Parameters ===\n');
disp(table(mu, sigma, weights, ...
    'VariableNames',{'Mean','Variance','Weight'},...
    'RowNames',cellstr("Component "+string(1:optimalK))'))
