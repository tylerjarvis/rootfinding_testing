times = {};
maxResids = {};
avgResids = {};

checkSolns = (
    maxResid = -1;
    avgResid = -1;
    resids = {};
    For[i = 1, i <= Length[#], i++, 
      a = Part[Part[#, i], 1];
      b = Part[Part[#, i], 2];
      AppendTo[resids, Abs[f[a, b]]];
      AppendTo[resids,Abs[g[a, b]]];
    ];
    maxResid = Max[resids];
    avgResid = Mean[resids];
    ) &;

(*1.1*)
f[x_, y_] = 144*(x^4 + y^4) - 225*(x^2 + y^2) + 350*x^2*y^2 + 81;
g[x_, y_] = y - x^6;
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*1.2*)
f[x_, y_] = (y^2 - 
     x^3)*((y - 0.7)^2 - (x - 0.3)^3)*((y + 0.2)^2 - (x + 
        0.8)^3)*((y + 0.2)^2 - (x - 0.8)^3);
g[x_, y_] = ((y + .4)^3 - (x - .4)^2)*((y + .3)^3 - (x - .3)^2)*((y - \
.5)^3 - (x + .6)^2)*((y + 0.3)^3 - (2*x - 0.8)^3);
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*1.3*)
f[x_, y_] = y^2 - x^3;
g[x_, y_] = (y + .1)^3 - (x - .1)^2;
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*1.4*)
f[x_, y_] = x - y + .5;
g[x_, y_] = x + y;
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*1.5*)
f[x_, y_] = y + x/2 + 1/10;
g[x_, y_] = y - 2.1*x + 2;
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*2.1*)
f[x_, y_] = Cos[10*x*y];
g[x_, y_] = x + y^2;
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*2.2*)
f[x_, y_] = x;
g[x_, y_] = (x - .9999)^2 + y^2 - 1;
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*2.3*)
f[x_, y_] = Sin[4*(x + y/10 + Pi/10)];
g[x_, y_] = Cos[2*(x - 2*y + Pi/7)];
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*2.4*)
f[x_, y_] = Exp[x - 2*x^2 - y^2]*Sin[10*(x + y + x*y^2)];
g[x_, y_] = Exp[-x + 2*y^2 + x*y^2]*Sin[10*(x - y - 2*x*y^2)];
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*2.5*)
f[x_, y_] = 2*y*Cos[y^2]*Cos[2*x] - Cos[y];
g[x_, y_] = 2*Sin[y^2]*Sin[2*x] - Sin[x];
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*3.1*)
f[x_, y_] = ((x - .3)^2 + 2*(y + 0.3)^2 - 1);
g[x_, y_] = ((x - .49)^2 + (y + .5)^2 - 
     1)*((x + 0.5)^2 + (y + 0.5)^2 - 1)*((x - 1)^2 + (y - 0.5)^2 - 
     1);
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*3.2*)
f[x_, y_] = ((x - 0.1)^2 + 2*(y - 0.1)^2 - 1)*((x + 0.3)^2 + 
     2*(y - 0.2)^2 - 1)*((x - 0.3)^2 + 2*(y + 0.15)^2 - 
     1)*((x - 0.13)^2 + 2*(y + 0.15)^2 - 1);
g[x_, y_] = (2*(x + 0.1)^2 + (y + 0.1)^2 - 
     1)*(2*(x + 0.1)^2 + (y - 0.1)^2 - 
     1)*(2*(x - 0.3)^2 + (y - 0.15)^2 - 1)*((x - 0.21)^2 + 
     2*(y - 0.15)^2 - 1);
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*4.1*)
f[x_, y_] = Sin[3*(x + y)];
g[x_, y_] = Sin[3*(x - y)];
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*4.2*)
f[x_, y_] = ((90000*y^10 + (-1440000)*
      y^9 + (360000*x^4 + 720000*x^3 + 504400*x^2 + 144400*x + 
        9971200)*(y^8) + ((-4680000)*x^4 + (-9360000)*
         x^3 + (-6412800)*x^2 + (-1732800)*
         x + (-39554400))*(y^7) + (540000*x^8 + 2160000*x^7 + 
        3817600*x^6 + 3892800*x^5 + 27577600*x^4 + 51187200*x^3 + 
        34257600*x^2 + 8952800*x + 
        100084400)*(y^6) + ((-5400000)*x^8 + (-21600000)*
         x^7 + (-37598400)*x^6 + (-37195200)*x^5 + (-95198400)*
         x^4 + (-153604800)*x^3 + (-100484000)*x^2 + (-26280800)*
         x + (-169378400))*(y^5) + (360000*x^12 + 2160000*x^11 + 
        6266400*x^10 + 11532000*x^9 + 34831200*x^8 + 93892800*x^7 + 
        148644800*x^6 + 141984000*x^5 + 206976800*x^4 + 
        275671200*x^3 + 176534800*x^2 + 48374000*x + 
        194042000)*(y^4) + ((-2520000)*x^12 + (-15120000)*
         x^11 + (-42998400)*x^10 + (-76392000)*x^9 + (-128887200)*
         x^8 + (-223516800)*x^7 + (-300675200)*x^6 + (-274243200)*
         x^5 + (-284547200)*x^4 + (-303168000)*x^3 + (-190283200)*
         x^2 + (-57471200)*x + (-147677600))*(y^3) + (90000*x^16 + 
        720000*x^15 + 3097600*x^14 + 9083200*x^13 + 23934400*x^12 + 
        58284800*x^11 + 117148800*x^10 + 182149600*x^9 + 
        241101600*x^8 + 295968000*x^7 + 320782400*x^6 + 
        276224000*x^5 + 236601600*x^4 + 200510400*x^3 + 
        123359200*x^2 + 43175600*x + 
        70248800)*(y^2) + ((-360000)*x^16 + (-2880000)*
         x^15 + (-11812800)*x^14 + (-32289600)*x^13 + (-66043200)*
         x^12 + (-107534400)*x^11 + (-148807200)*x^10 + (-184672800)*
         x^9 + (-205771200)*x^8 + (-196425600)*x^7 + (-166587200)*
         x^6 + (-135043200)*x^5 + (-107568800)*x^4 + (-73394400)*
         x^3 + (-44061600)*x^2 + (-18772000)*x + (-17896000))*
      y + (144400*x^18 + 1299600*x^17 + 5269600*x^16 + 
       12699200*x^15 + 21632000*x^14 + 32289600*x^13 + 
       48149600*x^12 + 63997600*x^11 + 67834400*x^10 + 61884000*x^9 + 
       55708800*x^8 + 45478400*x^7 + 32775200*x^6 + 26766400*x^5 + 
       21309200*x^4 + 11185200*x^3 + 6242400*x^2 + 3465600*x + 
       1708800)));
g[x_, y_] = .0001*(y^7 + (-3)*y^6 + (2*x^2 + (-1)*x + 2)*
      y^5 + (x^3 + (-6)*x^2 + x + 2)*
      y^4 + (x^4 + (-2)*x^3 + 2*x^2 + x + (-3))*
      y^3 + (2*x^5 + (-3)*x^4 + x^3 + 10*x^2 + (-1)*x + 1)*
      y^2 + ((-1)*x^5 + 3*x^4 + 4*x^3 + (-12)*x^2)*
      y + (x^7 + (-3)*x^5 + (-1)*x^4 + (-4)*x^3 + 4*x^2));
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*5.1*)
f[x_, y_] = 2*x*y*Cos[y^2]*Cos[2*x] - Cos[x*y];
g[x_, y_] = 2*Sin[x*y^2]*Sin[3*x*y] - Sin[x*y];
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -2 <= x <= 2 && -2 <= y <= 2;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*6.1*)
f[x_, y_] = (y - 2*x)*(y + 0.5*x);
g[x_, y_] = x*(x^2 + y^2 - 1);
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*6.2*)
f[x_, y_] = (y - 2*x)*(y + .5*x);
g[x_, y_] = (x - .0001)*(x^2 + y^2 - 1);
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*6.3*)
f[x_, y_] = 25*x*y - 12;
g[x_, y_] = x^2 + y^2 - 1;
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*7.1*)
f[x_, y_] = (x^2 + y^2 - 1)*(x - 1.1);
g[x_, y_] = (25*x*y - 12)*(x - 1.1);
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y},Method->"Homotopy"]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[times, myTime];
AppendTo[avgResids, avgResid];

(*7.2*)
f[x_, y_] = y^4 + (-1)*y^3 + (2*x^2)*(y^2) + (3*x^2)*y + (x^4);
h[x_, y_] = y^10 - 2*(x^8)*(y^2) + 4*(x^4)*y - 2;
g[x_, y_] = h[2*x, 2*(y + .5)];
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*7.3*)
m = 10^-9;
f[x_, y_] = Cos[x*y/(m^2)] + Sin[3*x*y/(m^2)];
g[x_, y_] = Cos[y/(m)] - Cos[2*x*y/(m^2)];
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -m <= x <= m && -m <= y <= m;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*7.4*)
f[x_, y_] = Sin[3*Pi*x]*Cos[x*y];
g[x_, y_] = Sin[3*Pi*y]*Cos[Sin[x*y]];
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*8.1*)
f[x_, y_] = Sin[10*x - y/10];
g[x_, y_] = Cos[3*x*y];
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*8.2*)
f[x_, y_] = Sin[10*x - y/10] + y;
g[x_, y_] = Cos[10*y - x/10] - x;
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*9.1*)
f[x_, y_] = x^2 + y^2 - .9^2;
g[x_, y_] = Sin[x*y];
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*9.2*)
f[x_, y_] = x^2 + y^2 - .49^2;
g[x_, y_] = (x - .1)*(x*y - .2);
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];

(*10.1*)
f[x_, y_] = (x - 1)*(Cos[x*y^2] + 2);
g[x_, y_] = Sin[8*Pi*y]*(Cos[x*y] + 2);
funcs = {f[x, y], g[x, y]};
bounds[x_, y_] = -1 <= x <= 1 && -1 <= y <= 1;
{myTime, mylist} = 
  AbsoluteTiming[NSolveValues[funcs == 0 && bounds[x, y], {x, y}]];
checkSolns[mylist];
AppendTo[maxResids, maxResid];
AppendTo[avgResids, avgResid];
AppendTo[times, myTime];


Export["NSolveValues_results/2d_times.txt",times];
Export["NSolveValues_results/2d_max_resids.txt",maxResids];
Export["NSolveValues_results/2d_avg_resids.txt",avgResids];