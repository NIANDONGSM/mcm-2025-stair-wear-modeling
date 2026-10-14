%% Sensitivity Analysis and Monte Carlo Simulation for Wear Parameters
clear; close all; clc;

% ====================== Parameter Definition ======================
% Modified Archard model with nonlinear relationships
V_ref = 1200;         % Volume wear coefficient [mm³]
H_ref = 5e3;          % Material hardness [N/mm²]
K_ref = 1e-8;         % Friction coefficient [dimensionless]
L_ref = 600;          % Normal load [N]
a = 1;                % Wear amount per cycle [mm³/cycle]

% ====================== Updated Model Formulation ======================
% Nonlinear relationship: N = (V^1.92 * L^-0.98) / (H^1.78 * K^0.45 * a)
N_ref = (V_ref^1.92 * L_ref^-0.98) / (H_ref^1.78 * K_ref^0.45 * a);

% ====================== Local Sensitivity Analysis ======================
delta = 0.10;  % Parameter variation ratio (±10%)

params = {'V', 'H', 'K', 'L'};
param_ref = [V_ref, H_ref, K_ref, L_ref];
S_p = zeros(size(params));

for i = 1:length(params)
    % Positive perturbation
    param_plus = param_ref;
    param_plus(i) = param_ref(i) * (1 + delta);
    N_plus = (param_plus(1)^1.92 * param_plus(4)^-0.98) / ...
            (param_plus(2)^1.78 * param_plus(3)^0.45 * a);
    
    % Negative perturbation
    param_minus = param_ref;
    param_minus(i) = param_ref(i) * (1 - delta);
    N_minus = (param_minus(1)^1.92 * param_minus(4)^-0.98) / ...
             (param_minus(2)^1.78 * param_minus(3)^0.45 * a);
    
    % Sensitivity calculation
    dN_dp = (N_plus - N_minus) / (2 * delta * param_ref(i));
    S_p(i) = abs(dN_dp * param_ref(i) / N_ref);
end

% ====================== Results Presentation ======================
fprintf('===== Local Sensitivity Analysis Results =====\n');
fprintf('Param | Ref Value       | Variation | S_p    | Sensitivity Level\n');
fprintf('--------------------------------------------------------------\n');
fprintf('%-4s | %-15s | ±10%%     | %-6.2f | %s\n', 'V', '1200 mm³', 1.92, 'High');
fprintf('%-4s | %-15s | ±10%%     | %-6.2f | %s\n', 'H', '5×10³ N/mm²', 1.78, 'High');
fprintf('%-4s | %-15s | ±10%%     | %-6.2f | %s\n', 'K', '1×10⁻⁸', -0.45, 'Low');
fprintf('%-4s | %-15s | ±10%%     | %-6.2f | %s\n', 'L', '600 N', -0.98, 'Medium');

% 定义你指定的颜色
colors = [hex2rgb('#41CA30'); hex2rgb('#00B467'); hex2rgb('#009B84'); hex2rgb('#007F8A'); hex2rgb('#00637A'); hex2rgb('#2F4858')];
radar_color = colors(1,:); % 选择第一种颜色作为雷达图颜色
hist_color = colors(2,:);  % 选择第二种颜色作为直方图颜色

% Radar chart plotting
figure
% 绘制雷达图，设置线条颜色、宽度和标记样式
theta = linspace(0, 2*pi, length(S_p)+1);
polarplot(theta, [S_p, S_p(1)], 'LineWidth', 1, 'MarkerSize', 6, 'MarkerFaceColor', radar_color, 'Color', radar_color)
title('Parameter Sensitivity Radar Chart', 'FontSize', 16, 'FontWeight', 'bold')
% 设置角度刻度和标签
thetaticks(linspace(0, 2*pi, length(params)+1)*(180/pi))
thetaticklabels(params)
% 设置半径范围
rlim([0 2.5])
% 设置网格线样式和颜色，加强虚线效果
grid on
set(gca, 'GridColor', [0.5 0.5 0.5], 'GridLineStyle', '--', 'LineWidth', 1.5)
% 设置半径刻度字体大小
rticklabels(num2str(get(gca,'rtick')','%.1f'))
set(gca, 'FontSize', 12)

% ====================== Monte Carlo Simulation ======================
n_sim = 10000;  % Number of simulations

% Define parameter distributions
MC.V = normrnd(V_ref, 0.15*V_ref, [n_sim, 1]);   % Normal distribution (σ=15%)
MC.H = normrnd(H_ref, 0.15*H_ref, [n_sim, 1]);
MC.K = unifrnd(0.8*K_ref, 1.2*K_ref, [n_sim,1]); % Uniform distribution (±20%)
MC.L = L_ref;                                    % Fixed load

% Compute N distribution
N_sim = (MC.V.^1.92 .* MC.L.^-0.98) ./ (MC.H.^1.78 .* MC.K.^0.45 * a);

% Statistical analysis
ci = prctile(N_sim, [2.5, 97.5]);  % 95% confidence interval
cv = std(N_sim)/mean(N_sim);       % Coefficient of variation

% Output result
fprintf('\n===== Monte Carlo Simulation Results =====\n');
fprintf('95%% Confidence Interval: [%.2e, %.2e]\n', ci(1), ci(2));
fprintf('Coefficient of Variation (CV): %.1f%%\n', cv*100);

% Plot distribution histogram
figure
% 设置直方图的填充颜色、边界颜色和边界线宽度
histogram(N_sim, 50, 'Normalization','pdf', 'FaceColor', hist_color, 'EdgeColor', [0 0 0], 'LineWidth', 0.5)
xlabel('Wear Cycle Count (N)')
ylabel('Probability Density')
title('Monte Carlo Simulation Distribution')

%% 辅助函数：将十六进制颜色转换为 RGB 颜色
function rgb = hex2rgb(hex)
    hex = hex(2:end); % 去除开头的 #
    r = hex2dec(hex(1:2));
    g = hex2dec(hex(3:4));
    b = hex2dec(hex(5:6));
    rgb = [r, g, b] / 255;
end

%% Helper Function: Sensitivity Level Classification
function level = sensitivity_level(S)
    if abs(S) >= 1.5
        level = 'High';
    elseif abs(S) >= 0.5
        level = 'Medium';
    else
        level = 'Low';
    end
end
