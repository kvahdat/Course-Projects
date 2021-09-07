function TC = myrteTC(rte,sh,tr,maxdist,T,D)
% My VRP constraints
newsh=vec2struct('b',[sh.b],'e',[sh.e],'q',[sh.q]);
TC = rteTC(rte,newsh,D,tr);
if TC > maxdist
   TC = Inf;
else
    tr=vec2struct(tr,'maxTC',9); %17-8=9
    TC=rteTC(rte,sh,T,tr);
end
