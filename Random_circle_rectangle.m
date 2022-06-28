function out = random_circle_rectangle
%Generic model statements, equivalent to the model guidance section of COMSOL desktop, determining geometric dimensions, physical fields, etc.
import com.comsol.model.*
import com.comsol.model.util.*

model = ModelUtil.create('Model');
model.component.create('comp1', true); % Generate component 1
model.component('comp1').geom.create('geom1', 2); % Generate 2D geometry
model.component('comp1').mesh.create('mesh1'); % Generate grid
model.component("comp1").geom("geom1").lengthUnit("mm");
%set global parameters, currently in the string and value here is a bit confusing, if the direct model.param.set ('Length','1'), then the back can not use the direct call Length.
Length = 1;%Rectangular length, width and height
Width = 1.5;
model.param.set('Length', num2str(Length)); % Parameter name, value
model.param.set('Width', num2str(Width));
model.param.descr('Length', 'The Length of a cube');% Parameter Description
model.param.descr('Width', 'The Width of a cube');% Parameter Description
% vf = 0.5;% Volume fraction of filler
 vf = 0.9;
model.param.set('vf', num2str(vf));
model.param.descr('vf', 'The volume fraction of fillers');
Vsq = Length^2;
model.param.set('Vsq', num2str(Vsq));
% miu = 0.05;% Average radius of circle
miu = 0.05;
model.param.set('miu', num2str(miu)); % The normal distribution parameter used to control the size of the circle
model.param.descr('miu', 'Average radius');
% sigma = 0.02;% Standard deviation
sigma = 0.02;
model.param.set('sigma', num2str(sigma));
model.param.descr('sigma', 'standard deviation');

% Next we go to generate the geometry, first drawing a rectangle
model.component('comp1').geom('geom1').create('r1', 'Rectangle');
model.component('comp1').geom('geom1').feature('r1').set('lx', 'Length');
model.component('comp1').geom('geom1').feature('r1').set('ly', 'Width');
model.component('comp1').geom('geom1').feature('r1').set('pos', [0 0]); % Coordinate origin is the default value, this sentence can be omitted
model.component('comp1').geom('geom1').run('r1');

% At this point, you can use the 'mphgeom' command to see the effect in MATLAB
mphgeom(model,'geom1');

% The next step is to generate the coordinates and radius of the filled random circle
n = 10000;
Vsum = 0;
Pos = zeros(n,2);
R = zeros(n,1);
idx = 1; % index for circle 
flag = 0;

model.component('comp1').geom('geom1').lengthUnit('cm'); % Set the length unit of the geometry to cm
%Create a new selection set and add the label 'Tcir1' and the name 'CumulativeSelection'.。
model.component('comp1').geom('geom1').selection().create('Tcir1', 'CumulativeSelection'); 

while (Vsum < Vsq * vf)
    r = abs( normrnd(miu,sigma) ); % Randomly generated cicle
    pos = [Length * rand(1,1) Width * rand(1,1)];
    for k = 1:idx % Determine the distance between the randomly generated cicle and all existing cicles
        Distance = sqrt((pos(1)-Pos(k,1))^2+(pos(2)-Pos(k,2))^2);
        rsum = r+R(k);
        if Distance < rsum
            flag = 1;
            break;
        end
    end
    
    if flag == 1 % If the newly generated cicle overlaps with any of the existing cicles, the next round of loops will be performed and the generated cicle will be discarded
        flag = 0;
        continue;
    end
    
    if (pos(1)-r < 0) || (pos(1)+r > Length) || (pos(2)-r < 0) || (pos(2)+r > Width)% Determine if it is inside a square
        continue;
    end
   
    V = Vsum + 2 * pi * r * r;
    if V > vf * Vsq % Perform volume fraction condition determination
        break;
    end
    
    % So far, the randomly generated cicle parameters satisfy the non-overlap condition, 
    % the intra-square condition and the volume fraction condition judgment, which will formally generate the geometry
    cl_name = ['cl',num2str(idx)]; % cicle serial number
    model.component('comp1').geom('geom1').create(cl_name, 'Circle');
    model.geom('geom1').feature(cl_name).set('base', 'center');
    model.component('comp1').geom('geom1').feature(cl_name).set('r', num2str(r));
    model.component('comp1').geom('geom1').feature(cl_name).set('pos', pos);
    model.component('comp1').geom('geom1').feature(cl_name).set('contributeto', 'Tcir1'); % Specify that this sphere feature is part of the selection set named 'Tcir1'
    mphgeom(model,'geom1');
    
    Pos(idx,:) = pos;
    R(idx) = r;
    idx = idx +1;
    Vsum = Vsum + 2 * pi * r * r; 
    
end

model.component("comp1").geom("geom1").create("dif1", "Difference");
model.component("comp1").geom("geom1").feature("dif1").selection("input").set('r1');
model.component("comp1").geom("geom1").feature("dif1").selection("input2").named('Tcir1');
model.component("comp1").geom("geom1").run();
mphgeom(model,'geom1');
mphsave(model,'Random_circle_rectangle'); % Save the 'mph' file to the current folder
out = model;                
