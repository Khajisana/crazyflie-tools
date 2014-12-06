function luenbergerObserver()

L = 0.2;

vicon_object_channel = 'crazyflie_squ_ext';
input_channel = 'crazyflie_input';
state_estimate_channel = 'crazyflie_state_estimate'; 

xhat = zeros(12,1);

options.floating = true;
p = RigidBodyManipulator('Crazyflie.URDF',options);

% turns out using the Vicon specified rate gives better
% estimates than the timestamps
dt = 1/120;

lc = lcm.lcm.LCM.getSingleton();

vicon_aggregator = lcm.lcm.MessageAggregator();
%vicon_aggregator.setMaxBufferSize(1);
lc.subscribe(vicon_object_channel, vicon_aggregator);

input_aggregator = lcm.lcm.MessageAggregator();
%input_aggregator.setMaxBufferSize(1);
lc.subscribe(input_channel, input_aggregator);

q_measured = zeros(6,1);
while true
  
  input_data = input_aggregator.getNextMessage(0);
  vicon_data = vicon_aggregator.getNextMessage(0);

  if (length(vicon_data)>0)
    
    vicon_msg = vicon_t.vicon_pos_t(vicon_data.data);
    if (vicon_msg.q(1)<=-1000000)
      % vicon lost the crazyflie
      vicon_msg.q = xhat(1:6);
    end
    vicon_msg.q(4:6) = quat2rpy(angle2quat(vicon_msg.q(4),vicon_msg.q(5),vicon_msg.q(6),'XYZ'));
    unwrapped_rpy = unwrap([q_measured(4:6)';vicon_msg.q(4:6)']);
    vicon_msg.q(4:6) = unwrapped_rpy(2,:);
    
    qd_measured = (vicon_msg.q-q_measured)/dt;
    q_measured = vicon_msg.q;
    y = [q_measured;qd_measured];

    if (length(input_data)>0)
      input_msg = crazyflie_t.crazyflie_thrust_t(input_data.data);    
      u = [input_msg.thrust1 input_msg.thrust2 input_msg.thrust3 input_msg.thrust4]'+32768;
    else
      u = zeros(4,1);
    end

    xhat = xhat + dt*p.dynamics(0,xhat,u) + L*(y-xhat);
    
    % if there is a delay, propagate the state estimate forward
    %delay = 0.001;
    %xhat = xhat + delay*p.dynamics(0,xhat,u);
    
    estimate_msg = crazyflie_t.crazyflie_state_estimate_t();
    estimate_msg.xhat = xhat;
    lc.publish(state_estimate_channel, estimate_msg);
  end
end

end
