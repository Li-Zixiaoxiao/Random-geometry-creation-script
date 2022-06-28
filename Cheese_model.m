function out = Cheese_model
% cheese.m
import com.comsol.model.*
import com.comsol.model.util.*
model = ModelUtil.create('Cheese_model');
model.component.create('comp1', true); % Generate component 1
model.component('comp1').geom.create('geom1', 3); % Generate 3D geometry
model.component('comp1').mesh.create('mesh1'); % Generate grid

% Initialization parameters for small holes in cheese
number_of_hols = 100; % Initialize and define the total number of small holes in the cheese
ind = 0; % Initialize and define the index counter for subsequent steps
Pos = zeros(1,3);
hr = 0.0; % xyz position and radius of each small hole.

% Define the height, radius, ringline thickness, and maximum and minimum radius of the small holes of the cheese
h_cheese = 1.0;
r_cheese = 2.0;
thickness = 0.02;
rmin_hole = 0.1;
rmax_hole = 1.5;
model.component('comp1').geom('geom1').lengthUnit('mm'); % Set the length unit of the geometry to cm
model.component('comp1').geom('geom1').selection().create('csel1', 'CumulativeSelection'); % Create a new selection set and add the label csel and the name CumulativeSelection.

while (ind < number_of_hols) % Initialize the while loop and create the specified number of holes
    Pos(1) = (2.0*rand-1.0)*r_cheese; % Define the hole coordinates by calling the random method and scaling the output so that the hole lies within the outer boundaries of the cheese model.
    Pos(2) = (2.0*rand-1.0)*r_cheese;
    Pos(3) = rand*h_cheese;
    hr = rand*(rmax_hole-rmin_hole)+rmin_hole; % Define the small hole radius within the specified limits
  
    if ((sqrt(Pos(1)^2+Pos(2)^2)+hr) > r_cheese-thickness) 
        continue;
    end % Check that the position and size of the small holes do not make it out of the cheese.
    if (((Pos(3)-hr) < thickness) || ((Pos(3)+hr) > h_cheese-thickness)) 
        continue;
    end
  
    sph = ['sph',num2str(ind)];
    model.component('comp1').geom('geom1').create(sph, 'Sphere');% Create a sphere so that its name is based on the current index value
    model.component('comp1').geom('geom1').feature(sph).set('r', hr); % Specifies the radius and position of the newly created sphere.
    model.component('comp1').geom('geom1').feature(sph).set('pos', Pos);
    model.component('comp1').geom('geom1').feature(sph).set('contributeto', 'csel1'); % Specifies that this sphere feature is part of the selection set named csel1
    ind = ind + 1;
end

model.component('comp1').geom('geom1').create('cyl1', 'Cylinder'); % Create a cylinder representing a disc of cheese
model.component('comp1').geom('geom1').feature('cyl1').set('r', r_cheese);
model.component('comp1').geom('geom1').feature('cyl1').set('h', h_cheese);
model.component('comp1').geom('geom1').create('dif1', 'Difference'); % Create a Boolean difference set operation. The object to be added is a cylinder and the object to be subtracted is a selection of all spheres
model.component('comp1').geom('geom1').feature('dif1').selection('input').set('cyl1');
model.component('comp1').geom('geom1').feature('dif1').selection('input2').named('csel1');
model.component('comp1').geom('geom1').run(); % Run the entire geometric sequence, excising all the spheres from the cylinder and eventually forming the disc cheese
model.component('comp1').view('view1').set('transparency', true);
mphgeom(model,'geom1');
mphsave(model,'cheese');
out = model;
