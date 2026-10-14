% 加载包含台阶磨损情况的矩阵ans的文件
load('xyd.mat');

% 检查数据矩阵维度
if size(ans, 1) ~= 20301 || size(ans, 2) ~= 3
    error('Data matrix has incorrect dimensions');
end

% 提取x, y, d坐标和磨损深度
x = ans(:, 1);
y = ans(:, 2);
d = ans(:, 3);

% 核心假设相关参数
a = 1; % 假设单次踩踏磨损量恒定为1，可根据实际情况调整
N = 200; % 将坑横向位置均匀划分为200个区间

% 离散化空间
% 找到x的最小值和最大值
x_min = min(x);
x_max = max(x);
% 创建离散区间边界
bin_edges = linspace(x_min, x_max, N + 1);
% 将x值映射到离散区间
x_discrete = discretize(x, bin_edges);

% 检查离散化结果
if length(x_discrete) ~= length(x)
    error('Discretization result has incorrect length');
end

% 计算每个区间的踩踏次数Ni
Ni = zeros(N, 1);
for i = 1:N
    Ni(i) = sum(x_discrete == i);
end

% 检查Ni的长度
if length(Ni) ~= N
    error('Ni has incorrect length');
end

% 泊松回归建模与参数估计

% 模型构建：log(λ(x_i)) = β_0 + β_1 * x_i
% 初始化参数估计值
beta0_hat = 0;
beta1_hat = 0;

% 最大似然估计迭代求解参数
max_iter = 1000; % 最大迭代次数
tol = 0.000001; % 收敛容差
for iter = 1:max_iter
    % 计算对数似然函数的偏导数
    grad_beta0 = 0;
    grad_beta1 = 0;
    for i = 1:N
        idx = find(x_discrete == i); % 找到属于第i个区间的x的索引
        lambda_i = exp(beta0_hat + beta1_hat * x(idx));
        grad_beta0 = grad_beta0 + Ni(i) - sum(lambda_i);
        grad_beta1 = grad_beta1 + sum((Ni(i) - sum(lambda_i)).* x(idx));
    end

    % 计算信息矩阵
    I_beta0_beta0 = 0;
    I_beta0_beta1 = 0;
    I_beta1_beta0 = 0;
    I_beta1_beta1 = 0;
    for i = 1:N
        idx = find(x_discrete == i);
        lambda_i = exp(beta0_hat + beta1_hat * x(idx));
        I_beta0_beta0 = I_beta0_beta0 + sum(lambda_i);
        I_beta0_beta1 = I_beta0_beta1 + sum(x(idx).* lambda_i);
        I_beta1_beta0 = I_beta0_beta1;
        I_beta1_beta1 = I_beta1_beta1 + sum(x(idx).^2.* lambda_i);
    end
    Fisher_information = [I_beta0_beta0 I_beta0_beta1; I_beta1_beta0 I_beta1_beta1];

    % 检查信息矩阵维度
    if size(Fisher_information, 1) ~= 2 || size(Fisher_information, 2) ~= 2
        error('Fisher information matrix has incorrect dimensions');
    end

    % 计算参数更新量
    grad = [grad_beta0; grad_beta1];
    update = inv(Fisher_information) * grad;

    % 更新参数估计值
    beta0_hat = beta0_hat - update(1);
    beta1_hat = beta1_hat - update(2);

    % 检查是否收敛
    if norm(update) < tol
        break;
    end
end

% 计算标准误
% 计算方差 - 协方差矩阵
Var_cov_matrix = inv(Fisher_information);
% 检查方差 - 协方差矩阵维度
if size(Var_cov_matrix, 1) ~= 2 || size(Var_cov_matrix, 2) ~= 2
    error('Variance - covariance matrix has incorrect dimensions');
end

% 提取beta1_hat的标准误
SE_beta1_hat = sqrt(Var_cov_matrix(2, 2));

% 构造Wald统计量
Z = beta1_hat / SE_beta1_hat;

% 灵敏度分析：改变y的值，观察β_1和Z的变化
delta_y = 0.01; % 变化量，可根据需要调整
num_y = length(y);
sensitivity_beta1 = zeros(num_y, 1);
sensitivity_Z = zeros(num_y, 1);

for idx = 1:num_y
    y_temp = y;
    y_temp(idx) = y_temp(idx) + delta_y;

    % 重新进行离散化（这里简单假设y的变化不影响x的离散化，实际可能需要调整）
    x_discrete_temp = discretize(x, bin_edges);

    % 检查重新离散化结果
    if length(x_discrete_temp) ~= length(x)
        error('Re - discretization result has incorrect length');
    end

    % 重新计算每个区间的踩踏次数Ni
    Ni_temp = zeros(N, 1);
    for i = 1:N
        Ni_temp(i) = sum(x_discrete_temp == i);
    end

    % 检查重新计算的Ni长度
    if length(Ni_temp) ~= N
        error('Re - calculated Ni has incorrect length');
    end

    % 重新进行参数估计
    beta0_hat_temp = 0;
    beta1_hat_temp = 0;
    for iter = 1:max_iter
        % 计算对数似然函数的偏导数
        grad_beta0_temp = 0;
        grad_beta1_temp = 0;
        for i = 1:N
            idx = find(x_discrete_temp == i);
            lambda_i_temp = exp(beta0_hat_temp + beta1_hat_temp * x(idx));
            grad_beta0_temp = grad_beta0_temp + Ni_temp(i) - sum(lambda_i_temp);
            grad_beta1_temp = grad_beta1_temp + sum((Ni_temp(i) - sum(lambda_i_temp)).* x(idx));
        end

        % 计算信息矩阵
        I_beta0_beta0_temp = 0;
        I_beta0_beta1_temp = 0;
        I_beta1_beta0_temp = 0;
        I_beta1_beta1_temp = 0;
        for i = 1:N
            idx = find(x_discrete_temp == i);
            lambda_i_temp = exp(beta0_hat_temp + beta1_hat_temp * x(idx));
            I_beta0_beta0_temp = I_beta0_beta0_temp + sum(lambda_i_temp);
            I_beta0_beta1_temp = I_beta0_beta1_temp + sum(x(idx).* lambda_i_temp);
            I_beta1_beta0_temp = I_beta0_beta1_temp;
            I_beta1_beta1_temp = I_beta1_beta1_temp + sum(x(idx).^2.* lambda_i_temp);
        end
        Fisher_information_temp = [I_beta0_beta0_temp I_beta0_beta1_temp; I_beta1_beta0_temp I_beta1_beta1_temp];

        % 检查重新计算的信息矩阵维度
        if size(Fisher_information_temp, 1) ~= 2 || size(Fisher_information_temp, 2) ~= 2
            error('Re - calculated Fisher information matrix has incorrect dimensions');
        end

        % 计算参数更新量
        grad_temp = [grad_beta0_temp; grad_beta1_temp];
        update_temp = inv(Fisher_information_temp) * grad_temp;

        % 更新参数估计值
        beta0_hat_temp = beta0_hat_temp - update_temp(1);
        beta1_hat_temp = beta1_hat_temp - update_temp(2);

        % 检查是否收敛
        if norm(update_temp) < tol
            break;
        end
    end

    % 重新计算标准误
    Var_cov_matrix_temp = inv(Fisher_information_temp);
    % 检查重新计算的方差 - 协方差矩阵维度
    if size(Var_cov_matrix_temp, 1) ~= 2 || size(Var_cov_matrix_temp, 2) ~= 2
        error('Re - calculated variance - covariance matrix has incorrect dimensions');
    end

    SE_beta1_hat_temp = sqrt(Var_cov_matrix_temp(2, 2));

    % 重新计算Z统计量
    Z_temp = beta1_hat_temp / SE_beta1_hat_temp;

    % 计算灵敏度
    sensitivity_beta1(idx) = (beta1_hat_temp - beta1_hat) / delta_y;
    sensitivity_Z(idx) = (Z_temp - Z) / delta_y;
end

% 可视化灵敏度分析结果
figure;
subplot(2, 1, 1);
plot(y, sensitivity_beta1);
xlabel('y - coordinate');
ylabel('Sensitivity of β_1');
title('Sensitivity Analysis of y to β_1');

subplot(2, 1, 2);
plot(y, sensitivity_Z);
xlabel('y - coordinate');
ylabel('Sensitivity of Z');
title('Sensitivity Analysis of y to Z');
