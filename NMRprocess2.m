(* ::Package:: *)

(************************************************************************)
(* This file was generated automatically by the Mathematica front end.  *)
(* It contains Initialization cells from a Notebook file, which         *)
(* typically will have the same name as this file except ending in      *)
(* ".nb" instead of ".m".                                               *)
(*                                                                      *)
(* This file is intended to be loaded into the Mathematica kernel using *)
(* the package loading commands Get or Needs.  Doing so is equivalent   *)
(* to using the Evaluate Initialization Cells menu command in the front *)
(* end.                                                                 *)
(*                                                                      *)
(* DO NOT EDIT THIS FILE.  This entire file is regenerated              *)
(* automatically each time the parent Notebook file is saved in the     *)
(* Mathematica front end.  Any changes you make to this file will be    *)
(* overwritten.                                                         *)
(************************************************************************)



BeginPackage["NMRProcess2`"];

NMRprocess::VersionNumber="2.0.0 " <> DateString[FileDate[FindFile["NMRProcess2.m"]]];

Print["NMR Processing
Version ", NMRprocess::VersionNumber, "
(c)2016 Marcel Utz
marcel.utz@southampton.ac.uk"];



Format[FID[assoc_]] := "-|NMR.." <> ToString[assoc[Dim] ] <> "--"


FID[q_][x_]:= q[x]


ReadBruker[fname_, OptionsPattern[{ByteOrdering->-1,NumberFormat->"Integer32"}]] := 
		Module[{fid,fidcomplex,fidmatrix,l },
						
		(* Read Raw Data; we assume Integer32 numbers with Little Endian order unless specified otherwise*)
		
		fid=BinaryReadList[fname,OptionValue[NumberFormat],ByteOrdering->OptionValue[ByteOrdering]];
		l=Length[fid];
		fidcomplex=1.0fid[[1;;l;;2]] - 1.0 I fid[[2;;l;;2]] ;
		FID[<|Dim->1,data->fidcomplex,Points->l/2|>] 
];




AddRaw[FID[q1_],FID[q2_]] := 
	Module[{qnew=q1},
		qnew[data]=q1[data]+q2[data];
		FID[qnew]
];
	


ReadVarian[fname_] := Module[
						  {nblocks, ntraces, np, ebytes, tbytes, bbytes, versId, status, 
							  nbheaders, sdata, sspec, s32, sfloat, scomplex, shyper, re, im,
							  scale, bstatus, index, mode, ctcount, lpval, rpval, lvl, tlt, b, t,
							  datatype},
						  
						  (* Read Header Information *)
						  
						  nblocks = BinaryRead[fname, "Integer32", ByteOrdering -> 1];
						  ntraces = BinaryRead[fname, "Integer32", ByteOrdering -> 1];
						  np = BinaryRead[fname, "Integer32", ByteOrdering -> 1];
						  ebytes = BinaryRead[fname, "Integer32", ByteOrdering -> 1];
						  tbytes = BinaryRead[fname, "Integer32", ByteOrdering -> 1];
						  bbytes = BinaryRead[fname, "Integer32", ByteOrdering -> 1];
						  versId = BinaryRead[fname, "Integer16", ByteOrdering -> 1];
						  status = BinaryRead[fname, "Integer16", ByteOrdering -> 1];
						  nbheaders = BinaryRead[fname, "Integer32", ByteOrdering -> 1];
						  sdata = BitGet[status, 0] == 1;
						  sspec = BitGet[status, 1] == 1;
						  s32 = BitGet[status, 2] == 1;
						  sfloat = BitGet[status, 3] == 1;
						  scomplex = BitGet[status, 4] == 1;
						  shyper = BitGet[status, 5] == 1;
						  
						  datatype = "Integer16";
						  If[s32, datatype = "Integer32"];
						  If[sfloat, datatype = "Real32"];
						  
						  Print["Reading ",nblocks, " blocks of ", np/2, " complex points; data type: ", datatype];
						  (* Print[datatype]; *)
						  (* Read Blocks *)
						  
						  re = {} ;
						  Do[
							 (* Print["Reading block ",b]; *)
							 
							 (* Read block header *)
							 
							 scale = BinaryRead[fname, "Integer16", ByteOrdering -> 1];
							 bstatus = BinaryRead[fname, "Integer16", ByteOrdering -> 1];
							 index = BinaryRead[fname, "Integer16", ByteOrdering -> 1];
							 mode = BinaryRead[fname, "Integer16", ByteOrdering -> 1];
							 ctcount = BinaryRead[fname, "Integer32", ByteOrdering -> 1];
							 lpval = BinaryRead[fname, "Real32", ByteOrdering -> 1];
							 rpval = BinaryRead[fname, "Real32", ByteOrdering -> 1];
							 lvl = BinaryRead[fname, "Real32", ByteOrdering -> 1];
							 tlt = BinaryRead[fname, "Real32", ByteOrdering -> 1];
							 
							 Do[
								data = 
								Table[BinaryRead[fname, datatype, ByteOrdering -> 1], {k, 1, 
								 np}];
								
								(* Note: minus sign in the following expression leads to spectra plotted in the conventional NMR 
								   order (chemical shift and frequency increase to the left). If the other convention is desired, 
								   use the complex conjugate of the data. *)
								
								re = Join[re, {data[[1 ;; ;; 2]] + I data [[2 ;; ;; 2]]}];
								
								, {t, 1, ntraces}];
							 
							 ,
							 {b, 1, nblocks}] ;
						  
						  Close[fname];
						  {nblocks, ntraces, np, ebytes, tbytes, bbytes, versId, status, 
							  nbheaders, sdata} ;

						FID[<|Dim->1,data->Flatten[re],Points->nblocks*np/2|>]
						  
		];




SetTimeDomain[FID[q_],TD_List]:= 
	Module[{qnew=q},
		qnew[Dim]=Length[TD];
		qnew[Points]=TD;
		qnew[data] = ArrayReshape[q[data],Reverse[TD]];
		FID[qnew]
] 


SetProp[FID[q_],key_->value_] := 
	Module[{qnew=q},
	qnew[key]=value;
	FID[qnew]
];

SetProp[F_FID, R_List] :=
	Module[{},
	Do[F=SetProp[F,next],{next,R}];
	F
];


ExtractTransient[FID[q_], n_List]:=Module[
	{qnew= <|Dim->1|>, selector= Join[n,{;;}]/.List->Sequence },

	qnew[data] = q[data][[selector]];
	qnew[Points] = Length[qnew[data]];
	qnew[Offset] = q[Offset][[1]];
	qnew[SpectralWidth] = q[SpectralWidth][[1]];
	FID[qnew]	
];

	 


FourierShift[data_?ListQ]:=
	Module[ {l},
		l=Length[data];
		Join[Take[data,-Floor[l/2]+1],Take[data,Floor[l/2]]]
	]


BaseLineCorrect[s_List,OptionsPattern[{Output->{1,-1},Regions->128,
									  Window->32,
									  KFactor->5,
									  InterpolationOrder->5}]]:=Module[{n=Length[s],nReg=OptionValue[Regions],win=OptionValue[Window],K=OptionValue[KFactor],order=OptionValue[InterpolationOrder],lreg,mindev,baslpoints,data,f},
(* Automatic Baseline correction, using the algorithm by S. Golotvin, A. Williams, J. Magn. Reson. 146 (1) (2000) 122\[Dash]125. *)

(* Find minimum standard deviation *)
lreg=Floor[n/nReg];
mindev=Min[Table[StandardDeviation[s[[k;;k+lreg]]],{k,1,n-lreg,lreg}]];

(* select baseline points *)
baslpoints= Cases[Range[1+win/2,n-win/2,Round[win/10]],k_/;StandardDeviation[s[[k-win/2;;k+win/2]]]<K mindev] ;

data=Transpose[{baslpoints,s[[baslpoints]]}];

(* Fit polynomial to baseline points and subtract from data *)

f[x_]=Fit[data,Table[x^k,{k,0,order}],x];
OptionValue[Output][[1]]s+OptionValue[Output][[2]] f[Range[1,n]]

];



FFT1D[FID[q_],OptionsPattern[{SI->1024,Phase0->Automatic,Phase1->0,Pivot->0,LeftShift->67,Apod->0.5}]]:= Module[
	{qnew=q,fid=q[data],apod,n,sf,pc1,pivot,si=OptionValue[SI],ls=OptionValue[LeftShift],p0=0,p1=0},

	If[q[Dim]!= 1, Throw["FFT1D::Can only process 1D Data"]];

	If[OptionValue[Phase0]===Automatic, 
		p0=Arg[fid[[ls+1]]],
		p0=\[Pi] OptionValue[Phase0]/180;
	];

	(* 1st order PC is measured in Degrees/SpectralWidth *)
	p1=\[Pi] OptionValue[Phase1]/180;
	pivot=si/2;
	
	apod=Table[Exp[-OptionValue[Apod]\[Pi] k / si],{k,1,si}]; 
	pc1=Table[Exp[I p1 (k-pivot)/si],{k,1,si}];

	sf = Reverse@BaseLineCorrect[FourierShift@Re[pc1*Fourier[apod*PadRight[Drop[fid,ls],si]] Exp[I p0]],Regions->32];
	qnew[spectrum]=sf;
	qnew[SpectSize]=si;

	FID[qnew]
]




StatesFFT2[FID[q_],OptionsPattern[{SI1->1024,SI2->1024,Phase1->0,Phase2->0,LeftShift->67,T1Dir->1,T1Shift->False}]] := Module[
	{qnew=q,
		sf2,sfa,sfb,si2=OptionValue[SI2],si1=OptionValue[SI1],
		p2=\[Pi] OptionValue[Phase2]/180,p1=\[Pi] OptionValue[Phase1]/180,
		ls=OptionValue[LeftShift],ser=q[data],apod2,apod1,n,m},

	{n,m}=Dimensions[ser];
	ser[[;;,1]] *= 1;
	apod2=PadRight[Table[0.5+0.5 Cos[\[Pi] k / m],{k,1,m}],si2]; 
    sf2=Table[Reverse@BaseLineCorrect[FourierShift@Re[Fourier[apod2*PadRight[RotateLeft[fid,ls],si2]] Exp[I p2]],Regions->32],{fid,ser}];
	(* sf2=Table[Reverse@FourierShift@Re[Fourier[apod2*PadRight[Drop[fid,ls],si2]] Exp[I p2]],{fid,ser}]; *)
	sfa = Transpose[sf2[[1;; ;;2]] - OptionValue[T1Dir] I sf2[[2;; ;;2]]] ;
	
	sfa[[;;,1]]*=0.5;  
	
	apod1= PadRight[Table[0.5+0.5 Cos[\[Pi] k / n],{k,1,n}],si1]; 
	sfb = If[OptionValue[T1Shift]==True,
				Table[Reverse@FourierShift@Re[Fourier[apod1*PadRight[fid,si1]] Exp[I p1]],{fid,sfa}],
				Table[Reverse@Re[Fourier[apod1*PadRight[fid,si1]] Exp[I p1]],{fid,sfa}]
			] ;

	qnew[spectrum]=Transpose[sfb];
	qnew[SpectSize]={OptionValue[SI2],OptionValue[SI1]};

	FID[qnew]
	
]


Covariance2D[FID[q_],OptionsPattern[{SI2->1024,Phase2->0,LeftShift->67}]] :=
	Module[{qnew=q,
		sf2,sfa,covm,si2=OptionValue[SI2],
		p2=OptionValue[Phase2],
		ls=OptionValue[LeftShift],ser=q[data],apod2,apod1,n,m},

	(* FT in the acquired domain *)
	
	ser[[;;,1]] *= 0.5;
	apod2=Table[Cos[\[Pi]/2 k / si2],{k,1,si2}]; 
	sf2=Table[Reverse@BaseLineCorrect[FourierShift@Re[Fourier[apod2*PadRight[Drop[fid,ls],si2]] Exp[I p2]],Regions->32],{fid,ser}];
	
	(* sfa will contain \[Omega]2 traces in its rows *)
	sfa = sf2 ;

	(* Covariance Matrix *)
	covm = Transpose[sfa].sfa -  Transpose[{Total[sfa,{1}]}]. {Total[sfa,{1}]};

	qnew[spectrum]=MatrixPower[covm,1/2];
	qnew[SpectSize]={OptionValue[SI2],OptionValue[SI2]};

	FID[qnew]

]
	


CovHSQCTOCSY[FID[q_]] :=
	Module[{qnew=q,sfa},

		(* sfa will contain \[Omega]1 traces in its rows *)
		sfa=Transpose[q[spectrum]];

		(* Covariance Matrix *)
		covm = Transpose[sfa].sfa - 0. Transpose[{Total[sfa,{1}]}]. {Total[sfa,{1}]};

		qnew[spectrum]=MatrixPower[covm,1/2];
		qnew[SpectSize]=Dimensions[qnew[spectrum]];
		qnew[SpectralWidth]=q[SpectralWidth][[2]]{1,1};	
		qnew[Offset] =	q[Offset][[2]]{1,1};

	FID[qnew]
]


LinPred[x_,p_,n_]:= 
	Module[{l=Length[x],a,R,r,xnew=x,k},
		r=Take[ListCorrelate[x,Conjugate[x],{1,1},0],p+1]/l;
		R=ToeplitzMatrix[Drop[r,-1]]; 
		a=Reverse[LinearSolve[R,Drop[r,1]]];
		Do[xnew=Append[xnew, a.Take[xnew,-p]],{k,1,n}];
	xnew
];



LinearPredict[FID[q_],p_Integer,OptionsPattern[{Points->Automatic}]]:=
	Module[{qnew=q,sfa,dims,LPF,directlevel,np},
	  sfa=q[data] ;
	  dims=Dimensions[q[data]];		
	  directlevel=Length[dims]-1;

	  If[OptionValue[Points]==Automatic,
			np= dims[[-1]],
			np= OptionValue[Points]
	  ];
	 Print[np];
	  LPF=LinPred[#1,p,np]& ;

	  qnew[data] = Map[LPF,q[data],{directlevel}] ;	
	  qnew[Points]=Reverse[Dimensions[qnew[data]]] ;  

	FID[qnew]
] ;



Transpose2D[FID[q_]]:= 
	Module[{qnew=q},
		If[q[Dim]!=2, Throw["ExtractRow::Not 2D data"]];
		qnew[data]=Transpose[q[data]];
		qnew[Points]=Reverse@Dimensions[qnew[data]] ;

	FID[qnew]
];



(* frq is a List of coordinates. First dimension is that of the data set (1D,2D,3D, etc).
   inner dimensions can be of any size; whole lists of coordinates can be processed at once
   in this way.
*)

Indx[q_,frq_]:=
	Module[{},
		If[Length[frq]!= q[Dim], Throw["Indx::Dimension mismatch"] ];
		
		Floor[(0.5-(frq-q[Offset])/q[SpectralWidth])q[SpectSize]]
];

Frq[q_,indx_]:=
	Module[{},
		If[Length[indx]!=q[Dim], Throw["Frq::Dimension mismatch"] ];

		(0.5-indx/q[SpectSize])q[SpectralWidth]+q[Offset]
];



ExtractRow[FID[q_],s_Real]:= 
	Module[{qnew=q,spt,indx,a},
		qnew[Dim]=1;    (* This is always a 1D spectrum ! *)
		
		(* For now, we are assuming FID is a 2D spectrum. We'll deal with exceptions later. *)
		If[q[Dim]!=2, Throw["ExtractRow::Not a 2D spectrum"]];

		(* Compute row index closest to target value s
		   spt is the distance from the centre of the spectrum in points *)

		spt = q[SpectSize][[2]]*(s-q[Offset][[2]])/q[SpectralWidth][[2]] ;

		If[Abs[spt]>=q[SpectSize][[2]]/2, Throw["ExtractRow::Out of range."]];
		
		indx=Floor[q[SpectSize][[2]]/2]-Floor[spt]; 
		a=spt-Floor[spt];	
			
		qnew[spectrum] =  (1-a)q[spectrum][[indx-1]] + a  q[spectrum][[indx]] ;

		qnew[SpectralWidth]=q[SpectralWidth][[1]];
		qnew[Offset] = q[Offset][[1]];
		qnew[SpectSize] = q[SpectSize][[1]];

		FID[qnew]
] ;

SetAttributes[ExtractRow,{Listable}] ;

ExtractColumn[FID[q_],s_Real]:= 
	Module[{qnew=q,spt,indx,a},
		qnew[Dim]=1;    (* This is always a 1D spectrum ! *)
		
		(* For now, we are assuming FID is a 2D spectrum. We'll deal with exceptions later. *)
		If[q[Dim]!=2, Throw["ExtractColumn::Not a 2D spectrum"]];
		
		(* Compute row index closest to target value s
		   spt is the distance from the centre of the spectrum in points *)

		spt = q[SpectSize][[1]]*(s-q[Offset][[1]])/q[SpectralWidth][[1]] ;

		If[Abs[spt]>q[SpectSize][[1]]/2, Throw["ExtractColumn::Out of range."]];
		
		indx=Floor[q[SpectSize][[1]]/2]-Floor[spt]; 
		a=spt-Floor[spt];	
			
		qnew[spectrum] =  (1-a)q[spectrum][[;;,indx-1]] + a  q[spectrum][[;;,indx]] ;

		qnew[SpectralWidth]=q[SpectralWidth][[2]];
		qnew[Offset] = q[Offset][[2]];
		qnew[SpectSize] = q[SpectSize][[2]];

		FID[qnew]
]; 

SetAttributes[ExtractColumn,{Listable}] ;


Crop[FID[q_],r_] := 
	Module[{qnew=q,indx,spn,lims,a,b},
	
	If[q[Dim] != Length[r], Throw["Crop::Dimension mismatch"]];

	(* Translate range into indices *)
			
	indx = Indx[q,r]; 

	(* Select corresponding part of spectral data *)
	
	spn=Reverse[ indx /. {a_Integer,b_Integer}->Span[a,b] ] /. List->Sequence ; 
	qnew[spectrum] = q[spectrum][[spn]] ; 

	(* Adjust SpectralWidth, Offset, and SpectSize *)
	qnew[SpectSize] = Reverse[Dimensions[qnew[spectrum]]] ;
	
	lims= Frq[q,indx] ; 

	qnew[SpectralWidth] = lims /. {a_Real,b_Real}->a-b;
	qnew[Offset] = lims /. {a_Real,b_Real}->(b+a)/2;

	(* 1D spectra are a bit special *)

	If[q[Dim]==1,
		qnew[SpectralWidth] = First@qnew[SpectralWidth] ;
		qnew[SpectSize] = First@qnew[SpectSize] ;
		qnew[Offset] = First@qnew[Offset] ;
	];

	(* Done *)

	FID[qnew]
]
	


TrimTimeDomain[FID[q_],TDeff_List] :=
	Module[{qnew=q,droplist},

	If[q[Dim] != Length[TDeff], Throw["TrimTimeDomain::Dimension mismatch"]];

	qnew[data]=Take[q[data],Reverse[TDeff]/.List->Sequence];
	FID[qnew]
];
	


PlotNMR1D[FID[q_],opt:OptionsPattern[Options[ListLinePlot]]]:=
	Module[{d,max,min},

		If[q[Dim]!=1,Throw["PlotNMR1D::Not a 1D spectrum"] ];

		max=q[SpectralWidth]/2+q[Offset];
		min=-q[SpectralWidth]/2+q[Offset];
		ListLinePlot[q[spectrum],DataRange->{-max,-min},
						Ticks->{Charting`ScaledTicks[{-#1&,-#1&}],Automatic},
						Evaluate@FilterRules[{opt},Options[ListLinePlot]],
						Axes->{True,False}]
      
];

SetAttributes[PlotNMR1D,{Listable}] ;


NMRContourPlot[FID[q_],opt:OptionsPattern[Join[Options[ListContourPlot],{Gain->1}]] ]:= 
	Module[{},

		If[q[Dim]!= 2,Throw["NMRContourPlot::Not a 2D spectrum"]];

		ListContourPlot[q[spectrum],
			DataRange->-q[SpectralWidth] {{-1/2,1/2},{-1/2,1/2}} - q[Offset] ,
			Evaluate@FilterRules[{opt},Options[ListContourPlot]],
			PlotRange -> Join[-q[SpectralWidth] {{-1/2,1/2},{-1/2,1/2}} - q[Offset],{All}] ,
			Contours-> 1./OptionValue[Gain] Max[q[spectrum]] Exp[Range[-2,0,0.2]],
			ContourShading->None,
			MaxPlotPoints->Automatic,
			PerformanceGoal->"Precision",
			FrameTicks->{{Charting`ScaledFrameTicks[{-#1&,-#1&}],Charting`ScaledTicks[{-#1&,-#1&}]},
				{Charting`ScaledTicks[{-#1&,-#1&}],Charting`ScaledFrameTicks[{-#1&,-#1&}]}}]

]


Project[FID[q_],{n_Integer},OptionsPattern[{Method->Total}]] :=
	Module[{qnew=q, clean1D := {xx_}->xx,
			projection=OptionValue[Method][#1,#2]&},

		If[n>q[Dim], Throw["Project::Dimension mismatch"]];
		If[q[Dim]==1,Return[Total[q[spectrum]]]];
		
		qnew[spectrum] = projection[q[spectrum],{n}];
		qnew[SpectSize] = Reverse[Dimensions[qnew[spectrum]]];
		qnew[Offset] = Drop[q[Offset],{-n}] /. clean1D ; (* minus sign: order convention *)
		qnew[SpectralWidth] = Drop[q[SpectralWidth],{-n}] /. clean1D;
		qnew[Dim]=q[Dim]-1;	
	
	FID[qnew]
]


NMRContourProjectionPlot[FID[q_],opt:OptionsPattern[Join[Options[ListContourPlot],
			{ProjectionStyle->{AbsoluteThickness[0.5],Gray},Gain->1}]] ]:= 
	Module[{padl=10,padr=50,padb=50,padt=2,contours,proj1,proj2},
	
	If[q[Dim]!=2,Throw["NMRContourProjectionPlot::Dimension mismatch"]];

	contours = NMRContourPlot[FID[q],
			ImagePadding->{{padl,padr},{padb,padt}},
			ImageSize->200+padl+padr, Evaluate@FilterRules[{opt},Join[Options[ListContourPlot],{Gain}]]] ;

	proj1 = PlotNMR1D[Project[FID[q],{1}],
			PlotRange->All,
			PlotStyle->OptionValue[ProjectionStyle],
			PlotRangePadding->Scaled[0.01],
			Axes->False,
			AspectRatio->1/4,
			ImagePadding->{{padl,padr},{2,0}},
			ImageSize->200+padl+padr ] ;
	
	proj2 = Show[PlotNMR1D[Project[FID[q],{2}],
					PlotRange->All,
					PlotStyle->OptionValue[ProjectionStyle],
					Axes->False,AspectRatio->4]  /. {a_Real,b_Real} -> {-b,a} ,
			PlotRange->All,
			PlotRangePadding->Scaled[0.01],
			ImagePadding->{{0,0},{padb,padt}},
			ImageSize->(200)/4] ;

	Graphics[{
		{Directive[White],Rectangle[{-1,-1},{1,1}]},
		Inset[proj1,{0,1}],
		Inset[proj2,{-1,0}],
		Inset[contours,{0,0}]
	}]
]


EndPackage[]
