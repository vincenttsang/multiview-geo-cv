% triangulation based approach
% vanish point in two figures, compute 3D coordinate through triangulation
% find 3 vanishing points to determine a infinity plane
close all; clear all; clc;

% load point correspondences into variable pts_img_1 and pts_img_2
load('points.mat');
% establish the normalization transformation
T = [2/2500,0,-1;
   0,2/1875,-1;
   0,0,1];
T2=[2/1875,0,-1;
    0,2/2500,-1;
    0,0,1];
% do normalization for both iamges
norm_img1=(T*[pts_img_1';ones(1,20)])';
norm_img2=(T2*[pts_img_2';ones(1,20)])';

% linear solution
% build A matrix for computing fundamental
for i=1:20
    A(i,:)=[norm_img2(i,1)*pts_img_1(i,1),norm_img2(i,1)*norm_img1(i,2),norm_img2(i,1),norm_img2(i,2)*norm_img1(i,1),norm_img2(i,2)*norm_img1(i,2),norm_img2(i,2),norm_img1(i,1),norm_img1(i,2),1];
end
% SVD to obtain least square solution
[U,S,V]=svd(A);
null(A');
F=V(:,9);
F=(reshape(F,[3,3]))';
% constraint enforcement
% do svd on F=UDV^T
% D = s = diag(r, s, t)
[u,s,v]=svd(F);
% construct diag(r, s, 0)
s(3,3)=0;
% F' = Udiag(r, s, 0)V^T
F2=u*s*v';
% denormalize
F=T2'*F2*T;
% or use approaches from purdue
%[F] = estimate_Fundamental_Matrix(x1,x2,T,T2);

% epipole
e_2=null(F');
% [e']_x
skew_e_2=[0,-e_2(3),e_2(2);e_2(3),0,-e_2(1);-e_2(2),e_2(1),0];
% skew'
% camera matrix P' for figure 2
% [[e']_x F | e']
P_2=[skew_e_2*F,e_2];
% just I
% camera matrix P for figure 1
P_1=[1,0,0,0;0,1,0,0;0,0,1,0];

% estimate the actual 3d points
% by minimizing Ax through SVD
for i=1:20
    A_X(1,:)=pts_img_1(i,1)*P_1(3,:)-P_1(1,:);
    A_X(2,:)=pts_img_1(i,2)*P_1(3,:)-P_1(2,:);
    A_X(3,:)=pts_img_2(i,1)*P_2(3,:)-P_2(1,:);
    A_X(4,:)=pts_img_2(i,2)*P_2(3,:)-P_2(2,:);
    [u2,s2,v2]=svd(A_X);
    X(:,i)=v2(:,4)';
end

% compute 3 vanishing point in the actual 3d space
% 1st vanishing point in 3d space
line1_1=cross([pts_img_1(1,:),1],[pts_img_1(4,:),1]);
line1_2=cross([pts_img_1(5,:),1],[pts_img_1(8,:),1]);
vanish1_1=cross(line1_1,line1_2);
vanish2_1=F*vanish1_1';
line2_1=cross([pts_img_2(1,:),1],[pts_img_2(4,:),1]);
vanish3_1=cross(vanish2_1,line2_1);
A_matrix(1,:)=vanish1_1(1)/vanish1_1(3)*P_1(3,:)-P_1(1,:);
A_matrix(2,:)=vanish1_1(2)/vanish1_1(3)*P_1(3,:)-P_1(2,:);
A_matrix(3,:)=vanish3_1(1)/vanish3_1(3)*P_2(3,:)-P_2(1,:);
A_matrix(4,:)=vanish3_1(2)/vanish3_1(3)*P_2(3,:)-P_2(2,:);
% 3d coordinates for vanish point
vanishPt3d_1=null(A_matrix);
% 2nd vanish point in 3d space
line1_3=cross([pts_img_1(1,:),1],[pts_img_1(5,:),1]);
line1_4=cross([pts_img_1(4,:),1],[pts_img_1(8,:),1]);
vanish1_2=cross(line1_3,line1_4);
vanish2_2=F*vanish1_2';
line2_2=cross([pts_img_2(1,:),1],[pts_img_2(5,:),1]);
vanish3_2=cross(vanish2_2,line2_2);
A_matrix(1,:)=vanish1_2(1)/vanish1_2(3)*P_1(3,:)-P_1(1,:);
A_matrix(2,:)=vanish1_2(2)/vanish1_2(3)*P_1(3,:)-P_1(2,:);
A_matrix(3,:)=vanish3_2(1)/vanish3_2(3)*P_2(3,:)-P_2(1,:);
A_matrix(4,:)=vanish3_2(2)/vanish3_2(3)*P_2(3,:)-P_2(2,:);
% 3d coordinates for vanish point
vanishPt3d_2=null(A_matrix);
% 3rd vanish point in 3d space
line1_5=cross([pts_img_1(11,:),1],[pts_img_1(14,:),1]);
line1_6=cross([pts_img_1(15,:),1],[pts_img_1(18,:),1]);
vanish1_3=cross(line1_3,line1_4);
vanish2_3=F*vanish1_3';
line2_3=cross([pts_img_2(11,:),1],[pts_img_2(14,:),1]);
vanish3_3=cross(vanish2_3,line2_3);
A_matrix(1,:)=vanish1_3(1)/vanish1_3(3)*P_1(3,:)-P_1(1,:);
A_matrix(2,:)=vanish1_3(2)/vanish1_3(3)*P_1(3,:)-P_1(2,:);
A_matrix(3,:)=vanish3_3(1)/vanish3_3(3)*P_2(3,:)-P_2(1,:);
A_matrix(4,:)=vanish3_3(2)/vanish3_3(3)*P_2(3,:)-P_2(2,:);
% 3d coordinates for vanish point
vanishPt3d_3=null(A_matrix);

% infinity plane from 3 vanishing point
inf_plane=null([vanishPt3d_1';vanishPt3d_2';vanishPt3d_3']);
% build the homography used for affinity rectification
H=[1,0,0,0;0,1,0,0;0,0,1,0;inf_plane'];
% apply homography on estimated 3d pts
X = H * X;
for i = 1 : 4
    X(i, :) = X(i, :) ./ X(4, :);
end

% scatter the pts on the wall using green markers
scatter3(X(1, 1:8), X(2, 1:8), X(3, 1:8), 'g')
hold on;
% scatter the pts on the wall (but not used for reconstruction) using red
% markers
scatter3(X(1, 9 : 10), X(2, 9 : 10), X(3, 9 : 10), 'r')
hold on;
% scatter the pts on the floor (that are not used for reconstruction) using
% red markers
scatter3(X(1, 19 : 20),X(2, 19 : 20),X(3, 19 : 20), 'r')
hold on;
% scatter the pts on the floor (that are used for recons) using blue
% markers
scatter3(X(1, 11 : 18),X(2, 11 : 18),X(3, 11 : 18), 'b')
hold on;
% compute the numerical representation of the two planes
plane1=null([X(:, 1)';
    X(:, 4)';
    X(:, 5)']);
plane2=null([X(:, 11)';
    X(:, 14)';
    X(:, 15)']);
plane1 = plane1';
plane2 = plane2';
