%% Exam 2
% Kimia Vahdat 200262784
%% Question 1
%% Reading data
fn='Exam2DataS19.xlsx';
Prod = table2struct(readtable(fn,'sheet','P1-Data'));
% need to fit  regression model to get fixed cost and variable cost of
% production
x = [Prod.Production]'; % ton/week
y = [Prod.Costs]'*1000; % $/week
yest = @(x,p) p(1) + p(2)*x;
fh = @(p) sum((y - yest(x,p)).^2);
ab = fminsearch(fh,[0 1])
k = ab(1) % fixed cost of production (only happens if we have production in a period)
Cp = ab(2) % variable cost of production
plot(x,y,'r.')
hold on, fplot(@(x) yest(x,ab),[0 max(x)],'k-'), hold off
Dem=table2struct(readtable(fn,'sheet','P1-Demand'));
D=[Dem.Demand]'; % demand ton/week
h = 0.05/(12*4)+0.06/(12*4)+0.5/4;
Ci = cumsum(Cp,1)*h;      % inventory cost of product 1 for stage 1 ($/ton)
K=60; % Production capacity ton/week
yinit = 13;           % initial inventory (ton)
ycap=120;           % incentory capacity
yfinal = 13;     % final inventory (ton)
T=13; % number of periods
%% Create MILP model
Cp = reshape(repmat(Cp,[T 1]),1,T)     % create 1 x T array 
Ci = reshape(repmat(Ci,[T+1 1]),1,T+1) % create 1 x (T+1) array
Ci(:,1) = 0   % intital inventory cost already accounted for last period
k = reshape(repmat(k,[T 1]),1,T)     % create 1 x T  array
mp = Milp('PPlan');
mp.addobj('min',Cp,Ci,k)     
   for t = 1:T
      mp.addcstr({t},{[1 -1],{[t t+1]}},0,'=',D(t))
      mp.addcstr({t},0,'<=',{K,{t}})
   end
mp.addlb(0,horzcat(yinit,zeros(1,T-1),yfinal),0)
mp.addub(Inf,horzcat(yinit,repmat(ycap,1,T-1),yfinal),1)
mp.addctype('C','C','B')
%% Display contraint matrix
spy(mp.Model.A),shg
%% Solve using Gurobi
clear params
model = mp.milp2gb
params.outputflag = 1;
result = gurobi(model, params);
x = mp.namesolution(result.x)
TC = result.objval
%% Report results
Fp = x.Cp; mdisp(Fp)
Fi = x.Ci; mdisp(Fi)
Fk= x.k; mdisp(Fk)
D=D';
mdisp(D)
%% Question 2- First Approach
clear all
close all
fn='Exam2DataS19.xlsx';
DC= table2struct(readtable(fn,'sheet','P2-DC'));
Cust=table2struct(readtable(fn,'sheet','P2-Customers'));
DC_XY=[DC.Lon,DC.Lat];
C_XY=[Cust.Lon; Cust.Lat]'; %inputting first longitude then latitude
q=[Cust.Pkg];
XY=[DC_XY;C_XY];
b=1; e=[2:size(XY,1)];
tr=struct('b',b,'e',b,'Kwt',40);
sh = vec2struct('b',b,'e',e,'q',q,'tU',2/60);
sdisp(sh)
%% Get road network
expansionAroundXY = 0.1;
[XY2,IJD,isXY,isIJD] = subgraph(usrdnode('XY'),...
   isinrect(usrdnode('XY'),boundrect(XY,expansionAroundXY)),...
   usrdlink('IJD'));
%% Label type of road
s = usrdlink(isIJD);
isI = s.Type == 'I';         % Interstate highways
isIR = isI & s.Urban == ' '; % Rural Interstate highways
isIU = isI & ~isIR;          % Urban Interstate highways
isR = s.Urban == ' ' & ~isI; % Rural non-Interstate roads
isU = ~isI & ~isR;           % Urban non-Interstate roads
%% Plot roads
makemap(XY2,0.03)  % 3% expansion
h = [];  % Keep handle to each plot for legend
h = [h pplot(IJD(isR,:),XY2,'r-','DisplayName','Rural Roads')];
h = [h pplot(IJD(isU,:),XY2,'k-','DisplayName','Urban Roads')];
h = [h pplot(IJD(isI,:),XY2,'c-','DisplayName','Interstate Roads')];
%% Add connector roads from cities to road network
[IJD11,IJD12,IJD22] = addconnector(XY,XY2,IJD);
h = [h pplot(IJD12,[XY; XY2],'b-','DisplayName','Connector Roads')];
h = [h pplot(XY,'g.','DisplayName','Cities')];
%% Convert road distances to travel times (needs to be after ADDCONNECTOR)
v.IR = 75;  % Rural Interstate highways average speed (mph)
v.IU = 65;  % Urban Interstate highways average speed (mph)
v.R = 50;   % Rural non-Interstate roads average speed (mph)
v.U = 25;   % Urban non-Interstate roads average speed (mph)
v.C = 20;   % Facility to road connector average speed (mph)

IJT = IJD;
IJT(isIR,3) = IJD(isIR,3)/v.IR;
IJT(isIU,3) = IJD(isIU,3)/v.IU;
IJT(isR,3) = IJD(isR,3)/v.R;
IJT(isU,3) = IJD(isU,3)/v.U;

IJT22 = IJD22;                % road to road
IJT22(:,3) = IJT(:,3);
IJT12 = IJD12;                % facility to road
IJT12(:,3) = IJD12(:,3)/v.C;  % (IJD11 facility to facility arcs ignored)
%% Shortest time routes
n = size(XY,1);
[T,P] = dijk(list2adj([IJT12; IJT22]),1:n,1:n);
%% Distance of shortest time route
W = list2adj([IJD12; IJD22]);
D = zeros(n);  
for i = 1:n
   for j = 1:n
      D(i,j) = locTC(pred2path(P,i,j),W);
   end
end
%% Adding constraint
% defined a new function myrteTC
maxdist = 200;
%% Construct & improve routes:
rTDh = @(rte) myrteTC(rte,sh,tr,maxdist,T,D);
ph = @(rte) plotshmt(sh,XY,rte,tr);
IJS = pairwisesavings(rTDh,sh);
r = twoopt(savings(rTDh,sh,IJS,true),rTDh,true);
%% Add any single-shipment routes
[r,~,Time] = sh2rte(sh,r,rTDh);
%% Plot Routes
plotshmt(sh,XY,r,tr)
pplot(XY(1,:),'ks')
%% Route time, packages, distance
wt = [sh.q];
Pkg = cellfun(@(r)sum(wt(rte2idx(r))),r);
distance = rteTC(r,sh,D,tr);
vdisp('Time,Pkg,distance')
%% Display route output structure
% to get time windows output too I added the time constraint here to tr
tr=vec2struct(tr,'tbmin',8,'tbmax',17,'temin',8,'temax',17);
[TC,Xflg,out] = rteTC(r,sh,T,tr);
%% Gant chart
b = arrayfun(@(x) (x.Start(1)),out); b = b(:);
e = arrayfun(@(x) (x.Depart(end)),out); e = e(:);
combine=[0,0];
for j=1:(length(r)-1)
    for i=j+1:length(r)
    if(Time(i)+Time(j)+1<=9)
        combine=[combine;[j,i]];
    end 
    end
end
combine
% we can combine only rout 5 and 6
% creating new beginning and end time
b(6)=e(5)+1;
e(6)=b(6)+Time(6);
% therefore we need 5 vans 
mdisp([b e])
figure
gantt([b e])
routeNum=[1:5 5]';
vdisp('Time,Pkg,distance,b,e,routeNum')
%% Question 2-Second Approach
%% Adding constraint
% defined a new function myrteTC2
XY=[DC_XY;C_XY];
b=1; e=[2:size(XY,1)];
tr=struct('b',b,'e',b,'Kwt',40);
sh = vec2struct('b',b,'e',e,'q',q,'tU',2/60);
maxdist = 200;
%% Construct & improve routes:
rTDh = @(rte) myrteTC2(rte,sh,tr,maxdist,T,D);
ph = @(rte) plotshmt(sh,XY,rte,tr);
IJS = pairwisesavings(rTDh,sh);
r = twoopt(savings(rTDh,sh,IJS,true),rTDh,true);
%% Add any single-shipment routes
[r,~,Time] = sh2rte(sh,r,rTDh);
%% Plot Routes
plotshmt(sh,XY,r,tr)
pplot(XY(1,:),'ks')
%% Route time, packages, distance
wt = [sh.q];
Pkg = cellfun(@(r)sum(wt(rte2idx(r))),r);
distance = rteTC(r,sh,D,tr);
vdisp('Time,Pkg,distance')
%% Display route output structure
% to get time windows output too I added the time constraint here to tr
tr=vec2struct(tr,'tbmin',8,'tbmax',17,'temin',8,'temax',17);
[TC,Xflg,out] = rteTC(r,sh,T,tr);

%% Gant chart
b = arrayfun(@(x) (x.Start(1)),out); b = b(:);
e = arrayfun(@(x) (x.Depart(end)),out); e = e(:);
% we can combine each combination of 2 routes together
% creating new beginning and end time for each coupled routes
i=1;
while i<length(r)
b(i+1)=e(i)+1;
e(i+1)=b(i+1)+Time(i+1);
i=i+2;
end
mdisp([b e])
figure
gantt([b e])
routeNum=[1 1 2 2 3 3 4 4]';
% final result
vdisp('Time,Pkg,distance,b,e,routeNum')