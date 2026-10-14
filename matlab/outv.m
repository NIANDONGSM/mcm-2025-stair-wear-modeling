clc,clear;
% 加载数据文件
load('xyd.mat');

% 提取x、y和d列
x = ans(:,1);
y = ans(:,2);
d = ans(:,3);

% 获取唯一的x和y值，并排序
unique_x = unique(x);
unique_y = unique(y);

% 计算x和y方向的间距
dx = unique_x(2) - unique_x(1);
dy = unique_y(2) - unique_y(1);

% 检查网格是否规则
if any(diff(unique_x) ~= dx) || any(diff(unique_y) ~= dy)
    error('网格间距不均匀，无法计算体积。');
end

% 确认数据点构成完整网格
if numel(d) ~= numel(unique_x) * numel(unique_y)
    error('数据点不构成完整网格，可能存在缺失。');
end

% 计算总磨损体积（凹陷值之和乘以单位面积）
total_volume = sum(d) * dx * dy;

% 输出结果
disp(['总磨损体积为：', num2str(total_volume)]);
