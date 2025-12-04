Off[Reduce::ratnz]
Off[Set::shape]

useTensor = (
Module[{myFun,myCoord,i,cVal},
myFun = 1;
myCoord = Append[#2,0];
If[#1 == 0,
cVal = 1;
For [i = 1, i <= dim, i++,
myFun *= vars[[i]]^(#2[[i]]);
cVal += ((deg+1)^(i-1))*(#2[[i]]);
];
myFun *= coeffs[[cVal]];
Throw[myFun];
];
myFun = 0;
For[i=0,i<=deg,i++,
myCoord = ReplacePart[myCoord,Length[myCoord]->i];
myFun += Catch[useTensor[#1-1,myCoord]];
];
Throw[myFun];
];
)&;

analyze = (
For[i = 1, i <= Length[#],i++,
myRoot = Part[#,i];
For[j=1,j<=dim,j++,
allResids = Append[allResids,Abs[myFuncs[[j]][myRoot]]];
];
];
)&;

getMyCoeffs = (
Txt = StringReplace[Txt,{"\n"->"","["->"","]"->""," "->","}];
While[Txt!=StringReplace[Txt,",,"->","],Txt = StringReplace[Txt,",,"->","]];
allCoeffs = StringSplit[Txt,","];
For[i = 1, i <= Length[allCoeffs],i++,
allCoeffs[[i]] = Interpreter["Number"][allCoeffs[[i]]];
];
myCoeffs = {};
While[Length[allCoeffs]>1,
myCoeffs = Append[myCoeffs,allCoeffs[[1;;(deg+1)^dim]]];
allCoeffs = allCoeffs[[(deg+1)^dim+1;;-1]];
];
)&;



dim = ToExpression[$ScriptCommandLine[[2]]];
minDeg = ToExpression[$ScriptCommandLine[[3]]];
maxDeg = ToExpression[$ScriptCommandLine[[4]]];


maxResidFile = "reduce_results/dimq_max_resids.txt";
avgResidFile = "reduce_results/dimq_avg_resids.txt";
sumResidFile = "reduce_results/dimq_sum_resids.txt"
avgTimesFile = "reduce_results/dimq_avg_times.txt";
numRootsFile = "reduce_results/dimq_numroots.txt";

maxResidFile = StringReplacePart[maxResidFile,ToString[dim],{19,19}];
avgResidFile = StringReplacePart[avgResidFile,ToString[dim],{19,19}];
sumResidFile = StringReplacePart[sumResidFile,ToString[dim],{19,19}];
avgTimesFile = StringReplacePart[avgTimesFile,ToString[dim],{19,19}];
numRootsFile = StringReplacePart[numRootsFile,ToString[dim],{19,19}];

Print["dim = ",dim];
Print["mindeg = ",minDeg];
Print["maxdeg = ",maxDeg];

vars = {};
myVars = {};
myFuncs = {};
endStr = "end";
For[i=1,i<=dim,i++,
vars = Append[vars,ToExpression[StringJoin["x",ToString[i]]]];
myVars = Append[myVars,ToExpression[StringJoin[{"x",ToString[i],"_"}]]];
myFuncs = Append[myFuncs,ToExpression[StringJoin["F",ToString[i]]]];
];


For[deg=minDeg,deg<=maxDeg,deg++,

readFileName = "mathematica_coeffs/dimp_degq_randn.txt";
outputFileName = "reduce_results/dimp_degq_output.txt";


readFileName = StringReplacePart[readFileName,ToString[deg],{28,28}];
readFileName = StringReplacePart[readFileName,ToString[dim],{23,23}];
outputFileName = StringReplacePart[outputFileName,ToString[deg],{24,24}];
outputFileName = StringReplacePart[outputFileName,ToString[dim],{19,19}];
readFileName = "mathematica_coeffs/example_sparse.txt";
outputFileName = "reduce_results/example_output.txt";

maxResid = -1;
allResids = {};
allTimes = {};
allRoots = {};

Txt = ReadString[readFileName];
getMyCoeffs[];

For[test=1,test<=10,test++,
solveFuncs = {};
For[i=1,i<=dim,i++,
coeffs = myCoeffs[[i+(test-1)*dim]];
coeffs[[1]] = 0;
myFuncs[[i]][myVars] = Catch[useTensor[dim,{}]];
solveFuncs = Append[solveFuncs,myFuncs[[i]][vars]];
];
{myTime,myList} = AbsoluteTiming[N[Reduce[solveFuncs == 0 && -1<=vars<=1,vars,Reals,Backsubstitution->True]]];
myList = DeleteDuplicates[myList];
myList = NSolveValues[myList,vars];
analyze[myList];
allTimes = Append[allTimes,myTime];
allRoots = Append[allRoots,Length[myList]];
Write[outputFileName,test,endStr];
For[i=1,i<=Length[myFuncs],i++,
derivs = {};
For[j=1,j<=Length[vars],j++,
derivs = Append[derivs,D[myFuncs[[i]][vars],vars[[j]]]];
];
Write[outputFileName,"F",i,"[",vars,"] = ",myFuncs[[i]][vars],endStr];
Write[outputFileName,derivs,endStr];
];

If[test/10 == Floor[test/10],Print["Completed dim ",dim," deg ",deg," test ",test]];
];
maxResid = Max[allResids];
avgResid = Mean[allResids];
avgTime = Mean[allTimes];
sumResid = Sum[Part[allResids,t],{t,Length[allResids]}];

Write[maxResidFile,maxResid];
Write[avgResidFile,avgResid];
Write[sumResidFile,sumResid];
Write[avgTimesFile,avgTime];
Write[numRootsFile,allRoots];

];