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


maxResidFile = "NSolveValues_results/dimq_max_resids2.txt";
avgResidFile = "NSolveValues_results/dimq_avg_resids2.txt";
sumResidFile = "NSolveValues_results/dimq_sum_resids2.txt"
avgTimesFile = "NSolveValues_results/dimq_avg_times2.txt";
numRootsFile = "NSolveValues_results/dimq_numroots2.txt";

maxResidFile = StringReplacePart[maxResidFile,ToString[dim],{25,25}];
avgResidFile = StringReplacePart[avgResidFile,ToString[dim],{25,25}];
sumResidFile = StringReplacePart[sumResidFile,ToString[dim],{25,25}];
avgTimesFile = StringReplacePart[avgTimesFile,ToString[dim],{25,25}];
numRootsFile = StringReplacePart[numRootsFile,ToString[dim],{25,25}];

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
outputFileName = "NSolveValues_results/dimp_degq_output2.txt";


readFileName = StringReplacePart[readFileName,ToString[deg],{28,28}];
readFileName = StringReplacePart[readFileName,ToString[dim],{23,23}];
outputFileName = StringReplacePart[outputFileName,ToString[deg],{30,30}];
outputFileName = StringReplacePart[outputFileName,ToString[dim],{25,25}];
readFileName = "mathematica_coeffs/example_sparse.txt";
outputFileName = "NSolveValues_results/example_output.txt";

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
{myTime,myList} = AbsoluteTiming[NSolveValues[solveFuncs == 0 && -1<=vars<=1,vars,Reals,15]];
myList = DeleteDuplicates[myList];
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
Write[outputFileName,"Roots: ",myList];

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

