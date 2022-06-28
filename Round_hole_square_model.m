function out = Round_hole_square_model
import com.comsol.model.*
import com.comsol.model.util.*
model = ModelUtil.create('Model');
model.component.create('comp1', true); % Generate component 1
model.component('comp1').geom.create('geom1', 3); % Generate 3D geometry
model.component('comp1').mesh.create('mesh1'); % Generate grid
model.component('comp1').geom('geom1').lengthUnit('mm'); % Set the length unit of the geometry to mm

% Define the length, width and height of the rectangle and the maximum and minimum radii of the holes
length = 1;
width = 1;
height = 1;
model.param.set('length', num2str(length)); % Parameter name, value
model.param.set('width', num2str(width));
model.param.set('height', num2str(height));
model.param.descr('length', 'The length of a cube');% Parameter Description
model.param.descr('width', 'The width of a cube');% Parameter Description
model.param.descr('height', 'The height of a cube');% Parameter Description

% volume fraction of filler
vf = 0.9;
model.param.set('vf', num2str(vf));
model.param.descr('vf', 'The volume fraction of fillers');
Vsq = length*width*height;% volume of the rectangle
model.param.set('Vsq', num2str(Vsq));
% Average radius of the ball
miu = 0.1;
model.param.set('miu', num2str(miu)); % Normal distribution parameters used to control ball size
model.param.descr('miu', 'Average radius');
% Standard deviation
sigma = 0.02;
model.param.set('sigma', num2str(sigma));
model.param.descr('sigma', 'standard deviation');

% Create a rectangular body
model.component('comp1').geom('geom1').create('blk1', 'Block');
model.component('comp1').geom('geom1').feature('blk1').set('lx', length);
model.component('comp1').geom('geom1').feature('blk1').set('ly', width);
model.component('comp1').geom('geom1').feature('blk1').set('lz', height);
model.component('comp1').geom('geom1').feature('blk1').set('pos', [0 0 0]); % Coordinate origin is the default value, this sentence can be omitted
model.component('comp1').geom('geom1').run('blk1');

% At this point you can use the mphgeom command to see the effect in MATLAB
mphgeom(model,'geom1');

% Next go to generate the coordinates and radius of the filled random ball
n = 200;
Vsum = 0;
Pos = zeros(n,3);
R = zeros(n,1);
idx = 1; % index for Sphere 
flag = 0;

model.component('comp1').geom('geom1').lengthUnit('mm'); % Set the length unit of the geometry to mm
% Create a new selection set and add the label Tsp1 and the name CumulativeSelection.
model.component('comp1').geom('geom1').selection().create('Tsp1', 'CumulativeSelection');


while (Vsum < Vsq * vf)
    r = abs( normrnd(miu,sigma) ); % Randomly generated balls
    pos = [length * rand(1,1) width * rand(1,1) height * rand(1,1)];
    for k = 1:idx % Distance the randomly generated sphere from all existing spheres
        Distance = sqrt((pos(1)-Pos(k,1))^2+(pos(2)-Pos(k,2))^2+(pos(3)-Pos(k,3))^2);
        rsum = r+R(k);
        if Distance < rsum
            flag = 1;
            break;
        end
    end
    
    if flag == 1 % If the newly generated Spherer overlaps with any of the existing Spheres, go to the next round and discard the generated Sphere 
        flag = 0;
        continue;
    end
    
    if (pos(1)-r < 0) || (pos(1)+r > length) || (pos(2)-r < 0) || (pos(2)+r > width)|| (pos(3)-r < 0) || (pos(3)+r > height)
        % Determine if it is in the positive side
        continue;
    end
   
    V = Vsum + 4/3 * pi * r * r * r;
    if V > vf * Vsq % Volume fraction condition determination
        break;
    end
    
    % At this point, the randomly generated Sphere parameters satisfy the non-overlap condition,
    % the intra-square condition and the volume fraction condition, 
    % and the geometry is formally generated
    sp_name = ['sp',num2str(idx)]; % Sphere Serial Number
    model.component('comp1').geom('geom1').create(sp_name, 'Sphere');
%     model.geom('geom1').feature(sp_name).set('base', 'center');
    model.component('comp1').geom('geom1').feature(sp_name).set('r', num2str(r));
    model.component('comp1').geom('geom1').feature(sp_name).set('pos', pos);
    model.component('comp1').geom('geom1').feature(sp_name).set('contributeto', 'Tsp1'); % Specify that this sphere feature is part of the selection set named Tsp1
    
    Pos(idx,:) = pos;
    R(idx) = r;
    idx = idx +1;
    Vsum = Vsum + 4/3 * pi * r * r * r; 

    if idx > n
        break;
    end
end


model.component('comp1').geom('geom1').create('dif1', 'Difference'); % Create a Boolean difference set operation. The object to be added is a cylinder and the object to be subtracted is a selection of all spheres
model.component('comp1').geom('geom1').feature('dif1').selection('input').set('blk1');
model.component('comp1').geom('geom1').feature('dif1').selection('input2').named('Tsp1');
model.component('comp1').geom('geom1').run(); % Run the entire geometry sequence, removing all spheres
model.component('comp1').view('view1').set('transparency', true);
mphgeom(model,'geom1');
mphsave(model,'Round_hole_square_model');
out = model;
