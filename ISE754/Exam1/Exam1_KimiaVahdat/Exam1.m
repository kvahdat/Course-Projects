%% Exam 1
%%% Kimia Vahdat #200262784
%% Question 1
%% Input Data
cust.zip=[72118, 55372,15010,88012,87301,73099];
cust.f=[1600,1600,2200,1200,2600,1500]; % demand unit/year
uwt=175;
ucu= 38.2;
s=uwt/ucu
supp.city={'Richmond','Canton','Malden','Tyler'};
supp.st={'CA','OH','MA','TX'};
supp.f=[4,3,1,4]; %units/unit of product
rwt=[8,14,4,29]; rcu=[2.7,1.3,2.7,3.6];
rs=rwt./rcu
city2lonlat = @(city,st) ...
   uscity('XY',mand(city,uscity('Name'),st,uscity('ST')));
supp.XY=city2lonlat(supp.city,supp.st);
cust.XY= uszip5('XY',mand(cust.zip,uszip5('Code5')));
ppiTL=141.9;
CF= cust.f .* (uwt/2000) % ton per year
SF=(supp.f .* rwt./2000)*sum(cust.f) %ton per year 
%% Calculating
tr= struct('r',2*(ppiTL/102.7),'Kwt',25,'Kcu',2750);
shS=vec2struct('f',SF,'s',rwt./rcu);
sh = aggshmt(shS);
sh = [shS vec2struct(sh,'f',CF)];
sdisp(sh) 
qmax = maxpayld(sh,tr)
n = ([sh.f]./qmax);    % shipment frequency
w = n.*tr.r;            % monetary weight ($/mi)
[DCtc,Tc] = minisumloc([supp.XY; cust.XY],w,'mi')
 lonlat2city(DCtc)  % default is uscity50k which satisfies our condition
%% Question 2
%% Reading data
clear all
close all
fn = 'Exam1DataS19.xlsx';
inC = table2struct(readtable(fn,'Sheet','Customers'));
inP = table2struct(readtable(fn,'Sheet','Plants'));
%% Geolocate
city2lonlat = @(city,st) ...
   uscity('XY',mand(city,uscity('Name'),st,uscity('ST')));
for i = 1:length(inP)
   XYP(i,:) = city2lonlat(inP(i).City,inP(i).State);
end
XYC = uszip5('XY',mand([inC.Zip],uszip5('Code5')));
a=uszip5('LandArea',mand([inC.Zip],uszip5('Code5')));
makemap(XYC)
pplot(XYC,'r.')
hold on
pplot(XYP,'bo')
hold off
f = [inC.Demand];
cap=[inP.Capacity];

%% Allocated Plant demand to customers 
D = dists(XYP,XYC,'mi')*1.2; 
length([inC.Zip]) == length(unique([inC.Zip]))  % all customers in diff Zip
f = [inC.Demand];
F = sparse(argmin(D,1),1:length(inC),f);  % allocate customers to plants
increment= (sum(F,2)-cap').* ([inP.DistCost]' ./ cap')
r = (sum([inP.DistCost])+sum(increment))/sum(sum(F.*D))    % nominal network-wide $/ton-mi
D = dists([XYP; XYC],XYC,'mi')*1.2;           % can ignore circuity
C = r*(f(:)'.*D);
%% fix Cost
x = sum(F,2); % Aggregated demand for each plant is equal to its capacity
increment= (sum(F,2)-cap').* ([inP.ProdCost]' ./ cap')
y = ([inP.ProdCost]+increment')';
yest = @(x,p) p(1) + p(2)*x;
fh = @(p) sum((y - yest(x,p)).^2);
ab = fminsearch(fh,[0 1])
k = ab(1), c_prod = ab(2)
plot(x,y,'r.')
hold on, fplot(@(x) yest(x,ab),[0 max(x)],'k-'), hold off
%% Current TLC
yorig = 1:length(inP)
nNForig = length(yorig)
distCost_orig = sum([inP.DistCost])
fixedCost_orig = k * length(inP)
TLCorig = fixedCost_orig + distCost_orig
%% Adding a new NF   
clear mp
K=cap;
mp = Milp('CFL')
mp.Model;
[n m] = size(C)
kn = iff(isscalar(k),repmat(k,1,n),k(:)');  % expand if k is constant value
mp.addobj('min',kn,C)  % min sum_i(ki*yi) + sum_i(sum_j(cij*xij))
for j = 1:m
   mp.addcstr(0,{':',j},'=',1)   % sum_i(xij) = 1
end
for i = 1:3
   mp.addcstr({K(i),{i}},'>=',{f',{i,':'}})  
   
end
for i=4:n
    mp.addcstr({m,{i}},'>=',{i,':'}) % m*yi >= sum_j(xij)  (weak form.)
end
mp.addcstr({1,{1}},0,'=',1)
mp.addcstr({1,{2}},0,'=',1)
mp.addcstr({1,{3}},0,'=',1)
mp.addub(1,1)
mp.addctype('B','C')         % only k are integer (binary)
mp.Model
%% Solving with Gurobi
clear model params
model = mp.milp2gb;
params.outputflag = 1;
result = gurobi(model,params);
x = result.x;
TC = result.objval;
%% Display solution
x = mp.namesolution(x)
TC
TCcalc = sum(kn.*x.kn) + full(sum(sum(C.*x.C)))
idxNF = find(round(x.kn))  % Round in case y > 0 & y < eps
nNF = sum(x.kn)

vdisp('TCcalc,TLCorig,nNF,nNForig ')
sat_demand = sum(sum(f .* x.C)); %satisfied demand

disp(['Total demand satisfied is: '  num2str(sat_demand)  ' Out of total demand ' num2str(sum(f))])
aa=x.kn';
XY=aa(4:end).*XYC;
makemap(XYC)
pplot(XYC,'r.')
hold on
pplot(XYP,'bo')
pplot(XY,'go')
hold off
%% Question 3
%% Original problem
clear all
close all
sh = vec2struct('f',75,'d',625,'s',12,'v',12000,'h',.3,'a',1);
sdisp(sh)
ppiTL = 123.4, ppiLTL = 141.4,
tr.r = 2*(ppiTL/102.7); tr.Kwt = 25; tr.Kcu = 2750;
[TLC,q,isLTL] = minTLC(sh,tr,ppiLTL)
[TLC,TC,IC]=totlogcost(q,transcharge(q,sh,tr,ppiLTL),sh)
tdays = 365.25*q/sh.f
q1wk = 7*sh.f/365.25
[c,isLTL,cTL,cLTL] = transcharge(q1wk,sh,tr,ppiLTL)
[TLC1wk,TC1wk,IC1wk] = totlogcost(q1wk,c,sh)
increase_in_TLC = TLC1wk - TLC

%% First change a=1 to a=0.5 (batch production with constant rate consumption)
clear sh tr
sh = vec2struct('f',75,'d',625,'s',12,'v',12000,'h',.3,'a',0.5);
sdisp(sh)
ppiTL = 123.4, ppiLTL = 141.4,
tr.r = 2*(ppiTL/102.7); tr.Kwt = 25; tr.Kcu = 2750;
[TLCa,qa,isLTL] = minTLC(sh,tr,ppiLTL)
[TLCa,TCa,ICa]=totlogcost(qa,transcharge(qa,sh,tr,ppiLTL),sh)
tdays = 365.25*qa/sh.f
q1wka = 7*sh.f/365.25
[ca,isLTL,cTLa,cLTLa] = transcharge(q1wka,sh,tr,ppiLTL)
[TLC1wka,TC1wka,IC1wka] = totlogcost(q1wka,ca,sh)
increase_in_TLC = TLC1wka - TLCa

vdisp('[TLC;TLCa],[IC;ICa],[TC;TCa]')
vdisp('[TLC1wk;TLC1wka],[IC1wk;IC1wka],[TC1wk;TC1wka]')
%% Second change tmax=1 week to tmax= 20 days
clear sh tr
sh = vec2struct('f',75,'d',625,'s',12,'v',12000,'h',.3,'a',1);
sdisp(sh)
ppiTL = 123.4, ppiLTL = 141.4,
tr.r = 2*(ppiTL/102.7); tr.Kwt = 25; tr.Kcu = 2750;
[TLCb,qb,isLTL] = minTLC(sh,tr,ppiLTL)
[TLCb,TCb,ICb]=totlogcost(qb,transcharge(qb,sh,tr,ppiLTL),sh)
tdays = 365.25*qb/sh.f
q1wkb = 20*sh.f/365.25
[cb,isLTL,cTLb,cLTLb] = transcharge(q1wkb,sh,tr,ppiLTL)
[TLC1wkb,TC1wkb,IC1wkb] = totlogcost(q1wkb,cb,sh)
increase_in_TLC = TLC1wkb - TLCb

vdisp('[TLC;TLCb],[IC;ICb],[TC;TCb]')
vdisp('[TLC1wk;TLC1wkb],[IC1wk;IC1wkb],[TC1wk;TC1wkb]')
%% Third change: Product looses 60% of its value in 2 years
clear sh tr
sh = vec2struct('f',75,'d',625,'s',12,'v',12000,'h',0.04+0.06+0.6/2,'a',1);
sdisp(sh)
ppiTL = 123.4, ppiLTL = 141.4,
tr.r = 2*(ppiTL/102.7); tr.Kwt = 25; tr.Kcu = 2750;
[TLCc,qc,isLTL] = minTLC(sh,tr,ppiLTL)
[TLCc,TCc,ICc]=totlogcost(qc,transcharge(qc,sh,tr,ppiLTL),sh)
tdays = 365.25*qc/sh.f
q1wkc = 7*sh.f/365.25
[cc,isLTL,cTLc,cLTLc] = transcharge(q1wkc,sh,tr,ppiLTL)
[TLC1wkc,TC1wkc,IC1wkc] = totlogcost(q1wkc,cc,sh)
increase_in_TLC = TLC1wkc - TLCc

vdisp('[TLC;TLCc],[IC;ICc],[TC;TCc]')
vdisp('[TLC1wk;TLC1wkc],[IC1wk;IC1wkc],[TC1wk;TC1wkc]')

%% All Changes together
clear sh tr
sh = vec2struct('f',75,'d',625,'s',12,'v',12000,'h',0.04+0.06+0.6/2,'a',0.5);
sdisp(sh)
ppiTL = 123.4, ppiLTL = 141.4,
tr.r = 2*(ppiTL/102.7); tr.Kwt = 25; tr.Kcu = 2750;
[TLC_All,q_All,isLTL] = minTLC(sh,tr,ppiLTL)
[TLC_All,TC_All,IC_All]=totlogcost(q_All,transcharge(q_All,sh,tr,ppiLTL),sh)
tdays = 365.25*qc/sh.f
q1wk_All = 20*sh.f/365.25
[c_All,isLTL,cTL_All,cLTL_All] = transcharge(q1wk_All,sh,tr,ppiLTL)
[TLC1wk_All,TC1wk_All,IC1wk_All] = totlogcost(q1wk_All,c_All,sh)
increase_in_TLC = TLC1wk_All - TLC_All

vdisp('[TLC;TLC_All],[IC;IC_All],[TC;TC_All]')
vdisp('[TLC1wk;TLC1wk_All],[IC1wk;IC1wk_All],[TC1wk;TC1wk_All]')

