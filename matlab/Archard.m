function Archard()
    % 参数设置（单位：厘米）
    step_length = 200;   % 台阶长度200cm
    step_width = 100;    % 台阶宽度100cm
    resolution = 1;      % 网格分辨率1cm
    
    % 生成磨损表面数据
    [X, Y, Z] = generate_worn_surface(step_width, step_length, resolution);
    
    % 绘制三维表面图
    plot_3d_surface(X, Y, Z, step_width, step_length);
    
    % 绘制平面热力图
    plot_2d_heatmap(X, Y, Z, step_width, step_length);
    
    % 绘制 x = 40 的截面图
    plot_x_section(X, Y, Z, 40);
    
    % 绘制 y = 40 的截面图
    plot_y_section(X, Y, Z, 40);
end

%% 磨损表面生成函数（改进版）
function [X, Y, Z] = generate_worn_surface(width, length, res)
    % 创建坐标网格
    x = 0:res:width;
    y = 0:res:length;
    [X, Y] = meshgrid(x, y);
    
    % 生成基准平面
    Z = zeros(size(X));
    
    % ===== 主要磨损区域 =====
    % 主凹陷参数（中心偏右）
    main_center_x = width*0.5;       % 中心x坐标（60%宽度处）
    main_center_y = length*0.5;      % 中心y坐标
    % 增大x和y方向的扩散范围，使凹陷更平缓
    main_sigma_x = 1000;               
    main_sigma_y = 3000;               
    % 减小最大深度
    main_depth = -0.75;               
    
    % 生成各向异性高斯凹陷
    main_dent = main_depth * exp(-...
        ((X-main_center_x).^2/(2*(main_sigma_x)^2) +...
         (Y-main_center_y).^2/(2*(main_sigma_y)^2)));
    
    % ===== 次要磨损区域 =====
    % 参数设置
    num_minor_dents = 3;             % 次要凹痕数量
    % 减小次要凹痕最大深度
    minor_max_depth = -0.15;          
    % 减小次要凹痕最小深度
    minor_min_depth = -0.05;          
    
    minor_dents = zeros(size(X));
    for i = 1:num_minor_dents
        % 随机参数生成
        cx = width * (0.3 + 0.4*rand());  % 集中在30%-70%宽度范围
        cy = length * rand();
        % 增大x方向的扩散范围
        sx = 16 + 10*rand();
        % 增大y方向的扩散范围
        sy = 30 + 20*rand();
        depth = minor_min_depth + (minor_max_depth - minor_min_depth)*rand();
        
        % 生成凹痕
        minor_dent = depth * exp(-...
            ((X-cx).^2/(2*sx^2) + (Y-cy).^2/(2*sy^2)));
        
        minor_dents = minor_dents + minor_dent;
    end
    
    % ===== 组合表面 =====
    Z = Z + main_dent + minor_dents;
    
    % 添加轻微噪声（RMS 减小到 0.02cm）
    Z = Z + 0.02*randn(size(Z));
end

%% 三维表面图绘制（优化版）
function plot_3d_surface(X, Y, Z, width, length)
    figure('Position', [100 100 1000 600], 'Color','w');
    
    % 创建表面图
    s = surf(X, Y, Z, 'EdgeColor','none');
    
    % 设置材质属性
    s.DiffuseStrength = 0.25;
    s.SpecularStrength = 0.6;
    s.AmbientStrength = 0.5;
    
    % 颜色和光照设置
    cmap = turbo(256);
    cmap(1:50,:) = cmap(1:50,:)*0.8; % 加深蓝色部分
    colormap(cmap);
    clim([-1.5 0.2]);
    
    lighting gouraud;
    light('Position',[width*0.7 length*0.3 50],'Style','local');
    light('Position',[width*0.3 length*0.7 30],'Style','local');
    
    % 视角和坐标轴设置
    view(-25, 35);
    axis([0 width 0 length -1.5 0.5]);
    set(gca, 'FontSize',10,...
             'XTick',0:20:width,...
             'YTick',0:40:length,...
             'ZLim',[-1.5 0.5]);
    
    % 标签和标题
    xlabel('x (mm)', 'FontSize',12);
    ylabel('y (mm)', 'FontSize',12);
    zlabel('d (cm)', 'FontSize',12);
    title('Realistic Step Wear 3D Visualization',...
          'FontSize',14, 'FontWeight','normal');
    
    % 修改此处，使用旧的设置属性方式
    h = colorbar('southoutside');
    set(get(h, 'Label'), 'String', 'Depth (cm)');
end

%% 修正后的平面热力图绘制函数
function plot_2d_heatmap(X, Y, Z, width, length)
    figure('Position', [200 200 1200 500], 'Color','w');
    
    % 使用旧版调用方式
    imagesc([0 width], [0 length], Z);
    axis xy;
    
    % 颜色设置（避免直接修改矩阵）
    cmap = turbo(256);
    adjusted_part = cmap(1:50,:) * 0.8;
    cmap(1:50,:) = adjusted_part;
    colormap(cmap);
    clim([-1.5 0.2]);
    
    % 等高线标注（移除透明度）
    hold on;
    contour(X, Y, Z, [-1.2 -0.8 -0.4],...
            'LineColor', [0.4 0.4 0.4],...
            'LineWidth', 1.2);
    
    % 坐标轴设置
    set(gca, 'FontSize',10,...
             'XTick',0:20:width,...
             'YTick',0:40:length);
    
    % 标签和标题
    xlabel('x (mm)', 'FontSize',12);
    ylabel('y (mm)', 'FontSize',12);
    title('Wear Depth Heatmap with Contours',...
          'FontSize',14, 'FontWeight','normal');
    grid on;
    set(gca, 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.3);
    
    % 同样修改此处，使用旧的设置属性方式
    h = colorbar('eastoutside');
    set(get(h, 'Label'), 'String', 'Depth (cm)');
end

%% 绘制 x = x0 的截面图
function plot_x_section(X, Y, Z, x0)
    % 找到最接近 x0 的索引
    [~, idx] = min(abs(X(1,:) - x0));
    
    % 获取该截面的数据
    y_data = Y(:, idx);
    z_data = Z(:, idx);
    
    % 绘制截面图
    figure;
    plot(y_data, z_data,'Color','#d56320');
    xlabel('y (mm)');
    ylabel('d (cm)');
    title(['Cross-section at x = ', num2str(x0), ' mm']);
    grid on;
end

%% 绘制 y = y0 的截面图
function plot_y_section(X, Y, Z, y0)
    % 找到最接近 y0 的索引
    [~, idx] = min(abs(Y(:,1) - y0));
    
    % 获取该截面的数据
    x_data = X(idx, :);
    z_data = Z(idx, :);
    
    % 绘制截面图
    figure;
    plot(x_data, z_data,'Color','#d56320');
    xlabel('x (mm)');
    ylabel('d (cm)');
    title(['Cross-section at y = ', num2str(y0), ' mm']);
    grid on;
end
