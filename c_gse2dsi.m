function [y] = c_gse2dsi( x, spin_axis, direction )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Usage:
%  function [out] = c_gse2dsi( inp, spin_axis, [direction])
%
%     Convert vector from GSE into DSI reference system.
%     DSI stands for DeSpun Inverted.
%        inp, out - vectors with 3 components,
%                   inp(:,1) is X,  inp(:,2) is Y ...
%        if more than 3 columns then columns
%                   inp(:,2) is X, inp(:,3) is Y ...
%        spin_axis = vector in GSE or ISDAT epoch.
%        direction = -1 to convert from DSI into GSE.
%
%     Assume the spin orientation does not change significantly during the
%     choosen interval. Only values at start time point is used.
%
%     See also c_gse2dsc
%
% $Id$
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
debug_flag=0;

error(nargchk(2,3,nargin))

lx=size(x,2);
if lx > 3
 inp=x(:,[2 3 4]); % assuming first column is time
elseif lx == 3
 inp=x;
else
 disp('too few components of vector')
 exit
end

if nargin<3, direction = 1; end
if abs(direction)~=1, direction = 1; warning('using GSE->DSI'), end
	
spin_axis=spin_axis/norm(spin_axis);
if debug_flag, disp('Spin axis orientation');spin_axis, end

% invert the spin axis
spin_axis = -spin_axis;

Rx = spin_axis(1);
Ry = spin_axis(2);
Rz = spin_axis(3);
a = 1/sqrt(Ry^2+Rz^2);
M = [[a*(Ry^2+Rz^2) -a*Rx*Ry -a*Rx*Rz];[0 a*Rz	-a*Ry];[Rx	Ry	Rz]];
Minv = inv(M);

if direction == 1
	out = M*inp';
	out = out';
	if length(out(:,1))==1
		if debug_flag == 1
			sprintf('x,y,z = %g, %g, %g [DSC]',out(1), out(2),out(3));
		end
	end
elseif direction==-1
	out = Minv*inp';
	out = out';
	if length(out(:,1))==1
		if debug_flag == 1
			sprintf('x,y,z = %g, %g, %g [GSE]',out(1), out(2),out(3));
		end
	end
else
	disp('No coordinate transformation done!')
end

y=x;
if lx > 3
 y(:,[2 3 4]) = out; % assuming first column is time
else
 y = out;
end

