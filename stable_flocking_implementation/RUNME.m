clear; matlabrc; clc; close all;
addpath(genpath('controllers'))
addpath(genpath('dynamics'))
addpath(genpath('tools'))

% Time settings:
dt = 1;
duration = 600;
tspan = 0:dt:duration;

% Agent definitions:
num_agents = 6;

% Virtual leader:
vl = [-30 30 .25 -.75]; %(rx,ry,vx,vy)
d0 = 20;

% Obstacles:
num_obs = 1;
obs = [30 20 10];

% Memory allocation:
L = length(tspan);
u = zeros(2*num_agents,L);
r = zeros(2*num_agents,L);
v = zeros(2*num_agents,L);
vl_rv = zeros(4,L);

% Initial conditions
r(:,1) = 20*randn(2*num_agents,1);
v(:,1) = 1*randn(2*num_agents,1);
vl_rv(:,1) = vl';

max_v = 5;
max_u = 1;

for ii = 1:L-1
    % Propagate the dynamics:
    X_out = RK4(@equations_of_motion,dt,[r(:,ii);v(:,ii)],u(:,ii));
    r(:,ii+1) = X_out(1:2*num_agents);
    v(:,ii+1) = X_out(2*num_agents+1:4*num_agents);
    vl_rv(:,ii+1) = RK4(@equations_of_motion,dt,vl_rv(:,ii),[0;0]);
    
    % Calculate the control:
    u(:,ii+1) = controller(r(:,ii+1),v(:,ii+1),vl_rv(:,ii+1)',d0);
    
    % Apply limitations on control input:
    u_vec = reshape(u(:,ii+1)',2,[])';
    [u_norm,u_norms] = normr(u_vec);
    u_vec(u_norms > max_u,:) = u_norm(u_norms > max_u,:)*max_u;
    
    % Apply limit to max velocity:
    v_vec = reshape(v(:,ii+1)',2,[])';
    v_vec2 = v_vec + u_vec*dt;
    [v2_norm,v2_norms] = normc(v_vec2);
    u_vec(v2_norms > max_v) = 0;
    
    u(:,ii+1) = reshape(u_vec',[],1);
end

% Create flock animation:
figure()
    % Initialize the animation:
    jj = 1;
    virtual_leader = plot(vl_rv(1,1),vl_rv(2,1),'sr','MarkerSize',10,'MarkerFaceColor','r'); hold on
    obstacles = gobjects(num_obs,1);
    for ii = 1:num_obs
        obstacles(ii) = circle(obs(ii,1),obs(ii,2),obs(ii,3));
    end
    agents = gobjects(num_agents,1);
    for ii = 1:2:2*num_agents
        agents(jj) = plot(r(ii,1),r(ii+1,1),'.','MarkerSize',20);
        jj = jj+1;
    end
    axis equal
    grid on
    legend([virtual_leader, agents(1),obstacles(1)],'Virtual Leader','Agents','Obstacle')
    
    % Actuall show the animation:
    for ii = 1:L
        % Add track history:
        r_vec = reshape(r(:,ii)',2,[])';
        plot(r_vec(:,1),r_vec(:,2),'.','color',[.5 .5 .5],'MarkerSize',2); hold on
        for jj = 1:num_agents
            set(agents(jj),'XData',r_vec(jj,1),'YData',r_vec(jj,2));
        end
        set(virtual_leader,'XData',vl_rv(1,ii),'YData',vl_rv(2,ii));
        xlim([-100 100])
        ylim([-100 100])
        drawnow
        pause(.1)
    end

% Plot summary of the results:
% figure()
%     subplot(2,3,1)
%         for ii = 1:2:2*num_agents
%             plot(tspan,r(ii,:)); hold on
%         end
%         grid on
%         title('R_x')
%     subplot(2,3,4)
%         for ii = 1:2:2*num_agents
%             plot(tspan,r(ii+1,:)); hold on
%         end
%         grid on
%         title('R_y')
%         
%     subplot(2,3,2)
%         for ii = 1:2:2*num_agents
%             plot(tspan,v(ii,:)); hold on
%         end
%         grid on
%         title('V_x')
%     subplot(2,3,5)
%         for ii = 1:2:2*num_agents
%             plot(tspan,v(ii+1,:)); hold on
%         end
%         grid on
%         title('V_y')
%         
%     subplot(2,3,3)
%         for ii = 1:2:2*num_agents
%             plot(tspan,u(ii,:)); hold on
%         end
%         grid on
%         title('U_x')
%     subplot(2,3,6)
%         for ii = 1:2:2*num_agents
%             plot(tspan,u(ii+1,:)); hold on
%         end
%         grid on
%         title('U_y')