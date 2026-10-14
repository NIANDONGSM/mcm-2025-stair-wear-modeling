function wear_matrix = Archard2() % 修改函数定义以返回磨损矩阵
    % 参数设置（单位：厘米）
    step_length = 200;   % 台阶长度200cm
    step_width = 100;    % 台阶宽度100cm
    resolution = 1;      % 网格分辨率1cm
    
    % 生成磨损表面数据
    [X, Y, Z] = generate_worn_surface(step_width, step_length, resolution);
    
    % ===== 新增核心部分：生成(x,y,d)矩阵 =====
    wear_matrix = [X(:), Y(:), Z(:)]; % 展开为N×3矩阵
    
    % 可视化部分（保持原有功能）
    plot_3d_surface(X, Y, Z, step_width, step_length);
    plot_2d_heatmap(X, Y, Z, step_width, step_length);
    plot_x_section(X, Y, Z, 40);
    plot_y_section(X, Y, Z, 40);
end

%% 磨损表面生成函数（保持不变）
function [X, Y, Z] = generate_worn_surface(width, length, res)
    % 创建坐标网格
    x = 0:res:width;
    y = 0:res:length;
    [X, Y] = meshgrid(x, y);
    
    % 生成基准平面
    Z = zeros(size(X));
    
    % 主凹陷参数
    main_center_x = width*0.5;    
    main_center_y = length*0.5;   
    main_sigma_x = 1000;          
    main_sigma_y = 3000;          
    main_depth = -0.75;           
    
    main_dent = main_depth * exp(-...
        ((X-main_center_x).^2/(2*(main_sigma_x)^2) +...
         (Y-main_center_y).^2/(2*(main_sigma_y)^2)));
    
    % 次要凹陷参数
    num_minor_dents = 3;          
    minor_max_depth = -0.15;      
    minor_min_depth = -0.05;      
    
    minor_dents = zeros(size(X));
    for i = 1:num_minor_dents
        cx = width * (0.3 + 0.4*rand());
        cy = length * rand();
        sx = 16 + 10*rand();
        sy = 30 + 20*rand();
        depth = minor_min_depth + (minor_max_depth - minor_min_depth)*rand();
        
        minor_dent = depth * exp(-...
            ((X-cx).^2/(2*sx^2) + (Y-cy).^2/(2*sy^2)));
        
        minor_dents = minor_dents + minor_dent;
    end
    
    % 组合表面
    Z = Z + main_dent + minor_dents;
    
    % 添加噪声
    Z = Z + 0.02*randn(size(Z));
end

%% 以下可视化函数保持不变
function plot_3d_surface(X, Y, Z, width, length)
    figure('Position', [100 100 1000 600], 'Color','w');
    s = surf(X, Y, Z, 'EdgeColor','none');
    s.DiffuseStrength = 0.25;
    s.SpecularStrength = 0.6;
    s.AmbientStrength = 0.5;
    
    cmap = turbo(256);
    cmap(1:50,:) = cmap(1:50,:)*0.8;
    colormap(cmap);
    clim([-1.5 0.2]);
    
    lighting gouraud;
    light('Position',[width*0.7 length*0.3 50],'Style','local');
    light('Position',[width*0.3 length*0.7 30],'Style','local');
    
    view(-25, 35);
    axis([0 width 0 length -1.5 0.5]);
    set(gca, 'FontSize',10,...
             'XTick',0:20:width,...
             'YTick',0:40:length,...
             'ZLim',[-1.5 0.5]);
    
    xlabel('x (mm)', 'FontSize',12);
    ylabel('y (mm)', 'FontSize',12);
    zlabel('d (cm)', 'FontSize',12);
    title('Realistic Step Wear 3D Visualization','FontSize',14);
    
    h = colorbar('southoutside');
    set(get(h, 'Label'), 'String', 'Depth (cm)');
end

function plot_2d_heatmap(X, Y, Z, width, length)
    figure('Position', [200 200 1200 500], 'Color','w');
    imagesc([0 width], [0 length], Z);
    axis xy;
    
    cmap = turbo(256);
    cmap(1:50,:) = cmap(1:50,:)*0.8;
    colormap(cmap);
    clim([-1.5 0.2]);
    
    hold on;
    contour(X, Y, Z, [-1.2 -0.8 -0.4],...
            'LineColor', [0.4 0.4 0.4],...
            'LineWidth', 1.2);
    
    set(gca, 'FontSize',10,...
             'XTick',0:20:width,...
             'YTick',0:40:length);
    
    xlabel('x (mm)', 'FontSize',12);
    ylabel('y (mm)', 'FontSize',12);
    title('Wear Depth Heatmap with Contours','FontSize',14);
    grid on;
    set(gca, 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.3);
    
    h = colorbar('eastoutside');
    set(get(h, 'Label'), 'String', 'Depth (cm)');
end

function plot_x_section(X, Y, Z, x0)
    [~, idx] = min(abs(X(1,:) - x0));
    y_data = Y(:, idx);
    z_data = Z(:, idx);
    
    figure;
    plot(y_data, z_data,'Color','#d56320');
    xlabel('y (mm)');
    ylabel('d (cm)');
    title(['Cross-section at x = ', num2str(x0), ' mm']);
    grid on;
end

function plot_y_section(X, Y, Z, y0)
    [~, idx] = min(abs(Y(:,1) - y0));
    x_data = X(idx, :);
    z_data = Z(idx, :);
    
    figure;
    plot(x_data, z_data,'Color','#d56320');
    xlabel('x (mm)');
    ylabel('d (cm)');
    title(['Cross-section at y = ', num2str(y0), ' mm']);
    grid on;
end
