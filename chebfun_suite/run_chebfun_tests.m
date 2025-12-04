addpath('chebfun');
cheb.xy;

formatSpec = '%s\n';

time_fid = fopen("chebfun_results/2d_avg_times.txt",'w');
avg_res_fid = fopen("chebfun_results/2d_avg_resids.txt",'w');
max_res_fid = fopen("chebfun_results/2d_max_resids.txt",'w');
time_list = [];
max_resid_list = [];
avg_resid_list = [];

%1.1
all_resids = [];
f = @(x,y) 144*(x.^4+y.^4)-225*(x.^2+y.^2) + 350*x.^2.*y.^2+81;
g = @(x,y) y-x.^6;
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%1.2
all_resids = [];
f = @(x,y) (y.^2-x.^3).*((y-0.7).^2-(x-0.3).^3).*((y+0.2).^2-(x+0.8).^3).*((y+0.2).^2-(x-0.8).^3);
g = @(x,y) ((y+.4).^3-(x-.4).^2).*((y+.3).^3-(x-.3).^2).*((y-.5).^3-(x+.6).^2).*((y+0.3).^3-(2*x-0.8).^3);
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%1.3
all_resids = [];
f = @(x,y) y.^2-x.^3;
g = @(x,y)(y+.1).^3-(x-.1).^2;
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%1.4
all_resids = [];
f = @(x,y) x - y + .5;
g = @(x,y) x + y;
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 1.5
all_resids = [];
f = @(x, y) y + x/2 + 1/10;
g = @(x, y) y - 2.1*x + 2;
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 2.1
all_resids = [];
f = @(x,y)cos(10*x.*y);
g = @(x,y) x + y.^2;
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 2.2
all_resids = [];
f = @(x,y)x;
g = @(x,y) (x-.9999).^2 + y.^2-1;
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 2.3
all_resids = [];
f = @(x,y)sin(4*(x + y/10 + pi/10));
g = @(x,y) cos(2*(x-2*y+pi/7));
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 2.4
all_resids = [];
f = @(x,y)exp(x-2*x.^2-y.^2).*sin(10*(x+y+x.*y.^2));
g = @(x,y)exp(-x+2*y.^2+x.*y.^2).*sin(10*(x-y-2*x.*y.^2));
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 2.5
all_resids = [];
rect = 4*[-1 1 -1 1];
f = @(x,y)2*y.*cos(y.^2).*cos(2*x)-cos(y);
g = @(x,y)2*sin(y.^2).*sin(2*x)-sin(x);
start_time = tic;
my_roots = roots([chebfun2(f,rect);chebfun2(g,rect)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 3.1
all_resids = [];
f = @(x,y)((x-.3).^2+2*(y+0.3).^2-1);
g = @(x,y)((x-.49).^2+(y+.5).^2-1).*((x+0.5).^2+(y+0.5).^2-1).*((x-1).^2+(y-0.5).^2-1);
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 3.2
all_resids = [];
f = @(x,y)((x-0.1).^2+2*(y-0.1).^2-1).*((x+0.3).^2+2*(y-0.2).^2-1).*((x-0.3).^2+2*(y+0.15).^2-1).*((x-0.13).^2+2*(y+0.15).^2-1);
g = @(x,y)(2*(x+0.1).^2+(y+0.1).^2-1).*(2*(x+0.1).^2+(y-0.1).^2-1).*(2*(x-0.3).^2+(y-0.15).^2-1).*((x-0.21).^2+2*(y-0.15).^2-1);
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 4.1
all_resids = [];
f = @(x,y)sin(3*(x+y));
g = @(x,y)sin(3*(x-y));
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 4.2
all_resids = [];
f = @(x,y)((90000*y.^10 + (-1440000)*y.^9 + (360000*x.^4 + 720000*x.^3 + 504400*x.^2 + 144400*x +...
     9971200).*(y.^8) + ((-4680000)*x.^4 + (-9360000)*x.^3 + (-6412800)*x.^2 + (-1732800).*x +...
     (-39554400)).*(y.^7) + (540000*x.^8 + 2160000*x.^7 + 3817600*x.^6 + 3892800*x.^5 +...
     27577600*x.^4 + 51187200*x.^3 + 34257600*x.^2 + 8952800*x + 100084400).*(y.^6) +...
     ((-5400000)*x.^8 + (-21600000)*x.^7 + (-37598400)*x.^6 + (-37195200)*x.^5 +...
     (-95198400)*x.^4 + (-153604800)*x.^3 + (-100484000)*x.^2 + (-26280800).*x +...
     (-169378400)).*(y.^5) + (360000*x.^12 + 2160000*x.^11 + 6266400*x.^10 + 11532000*x.^9 +...
     34831200*x.^8 + 93892800*x.^7 + 148644800*x.^6 + 141984000*x.^5 + 206976800*x.^4 +...
     275671200*x.^3 + 176534800*x.^2 + 48374000*x + 194042000).*(y.^4) + ((-2520000)*x.^12 +...
     (-15120000)*x.^11 + (-42998400)*x.^10 + (-76392000)*x.^9 + (-128887200)*x.^8 + ...
     (-223516800)*x.^7 + (-300675200)*x.^6 + (-274243200)*x.^5 + (-284547200)*x.^4 + ...
     (-303168000)*x.^3 + (-190283200)*x.^2 + (-57471200).*x + (-147677600)).*(y.^3) +...
     (90000*x.^16 + 720000*x.^15 + 3097600*x.^14 + 9083200*x.^13 + 23934400*x.^12 +...
     58284800*x.^11 + 117148800*x.^10 + 182149600*x.^9 + 241101600*x.^8 + 295968000*x.^7 +...
     320782400*x.^6 + 276224000*x.^5 + 236601600*x.^4 + 200510400*x.^3 + 123359200*x.^2 + ...
     43175600*x + 70248800).*(y.^2) + ((-360000)*x.^16 + (-2880000)*x.^15 + (-11812800)*x.^14 +...
     (-32289600)*x.^13 + (-66043200)*x.^12 + (-107534400)*x.^11 + (-148807200)*x.^10 + (-184672800)*x.^9 + (-205771200)*x.^8 + (-196425600)*x.^7 + (-166587200)*x.^6 + (-135043200)*x.^5 + (-107568800)*x.^4 + (-73394400)*x.^3 + (-44061600)*x.^2 + (-18772000)*x + (-17896000)).*y + (144400*x.^18 + 1299600*x.^17 + 5269600*x.^16 + 12699200*x.^15 + 21632000*x.^14 + 32289600*x.^13 + 48149600*x.^12 + 63997600*x.^11 + 67834400*x.^10 + 61884000*x.^9 + 55708800*x.^8 +...
     45478400*x.^7 + 32775200*x.^6 + 26766400*x.^5 + 21309200*x.^4 + 11185200*x.^3 + 6242400*x.^2 + 3465600*x + 1708800)));
g = @(x,y)1e-4*(y.^7 + (-3)*y.^6 + (2*x.^2 + (-1)*x + 2).*y.^5 + (x.^3 + (-6)*x.^2 + x + 2).*y.^4 + ...
     (x.^4 + (-2)*x.^3 + 2*x.^2 + x + (-3)).*y.^3 + (2*x.^5 + (-3)*x.^4 + x.^3 + 10*x.^2 + (-1)*x + 1).*y.^2 + ((-1)*x.^5 + 3*x.^4 + 4*x.^3 + (-12)*x.^2).*y + (x.^7 + (-3)*x.^5 + (-1)*x.^4 + (-4)*x.^3 + 4*x.^2));
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 5.1
all_resids = [];
rect = 2*[-1 1 -1 1];
f = @(x,y)2*x.*y.*cos(y.^2).*cos(2*x)-cos(x.*y);
g = @(x,y)2*sin(x.*y.^2).*sin(3*x.*y)-sin(x.*y);
start_time = tic;
my_roots = roots([chebfun2(f,rect);chebfun2(g,rect)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 6.1
all_resids = [];
f = @(x,y)(y - 2*x).*(y+0.5*x);
g = @(x,y) x.*(x.^2+y.^2-1);
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 6.2
all_resids = [];
f = @(x,y)(y - 2*x).*(y+.5*x);
g = @(x,y) (x-.0001).*(x.^2+y.^2-1);
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 6.3
all_resids = [];
f = @(x,y)25*x.*y - 12;
g = @(x,y)x.^2+y.^2-1;
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 7.1
all_resids = [];
f = @(x,y)(x.^2+y.^2-1).*(x-1.1);
g = @(x,y)(25*x.*y-12).*(x-1.1);
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 7.2
all_resids = [];
f = @(x,y)y.^4 + (-1)*y.^3 + (2*x.^2).*(y.^2) + (3*x.^2).*y + (x.^4);
g = @(x,y)y.^10-2*(x.^8).*(y.^2)+4*(x.^4).*y-2;
h = @(x,y) g(2*x,2*(y+.5));
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(h)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(h(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 7.3
all_resids = [];
a = 1e-9;
rect = a*[-1 1 -1 1];
f = @(x,y)cos(x.*y/a^2)+sin(3*x.*y/a^2);
g = @(x,y)cos(y/a)-cos(2*x.*y/a^2);
start_time = tic;
my_roots = roots([chebfun2(f,rect);chebfun2(g,rect)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 7.4
all_resids = [];
f = @(x,y)sin(3*pi*x).*cos(x.*y);
g = @(x,y)sin(3*pi*y).*cos(sin(x.*y));
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 8.1
all_resids = [];
f = @(x,y)sin(10*x-y/10);
g = @(x,y)cos(3*x.*y);
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 8.2
all_resids = [];
f = @(x,y)sin(10*x-y/10) + y;
g = @(x,y)cos(10*y-x/10) - x;
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 9.1
all_resids = [];
f = @(x,y)x.^2+y.^2-.9^2;
g = @(x,y)sin(x.*y);
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 9.2
all_resids = [];
f = @(x,y)x.^2+y.^2-.49^2;
g = @(x,y)(x-.1).*(x.*y-.2);
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;

%Test 10.1
all_resids = [];
f = @(x,y) (x-1).*(cos(x.*y.^2)+2);
g = @(x,y) sin(8*pi*y).*(cos(x.*y)+2);
start_time = tic;
my_roots = roots([chebfun2(f);chebfun2(g)],'resultant');
end_time = toc(start_time);
for i=1:size(my_roots,1)
    all_resids(end+1) = abs(f(my_roots(i,1),my_roots(i,2)));
    all_resids(end+1) = abs(g(my_roots(i,1),my_roots(i,2)));
end
max_resid_list(end+1) = max(all_resids);
avg_resid_list(end+1) = sum(all_resids)/length(all_resids);
time_list(end+1) = end_time;


fprintf(time_fid,formatSpec,time_list);
fprintf(avg_res_fid,formatSpec,avg_resid_list);
fprintf(max_res_fid,formatSpec,max_resid_list);

fclose('all');
exit;