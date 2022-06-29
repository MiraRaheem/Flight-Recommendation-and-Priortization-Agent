nextDay(sun,mon).
nextDay(mon,tue).
nextDay(tue,wed).
nextDay(wed,thu).
nextDay(thu,fri).
nextDay(fri,sat).
nextDay(sat,sun).

travel(Source, Destination, Range):-
	search([[[Source,Destination,Range],null,0,H,H]],[],0,[Source,Destination,Range]).
	
search([],_,1,_):-
	write(" No Solution "),nl,!.
	
search([],_,0,[Source,Destination,Range]):-
	newRange(Range, NewRange),
	search([[[Source,Destination,NewRange],null,0,H,H]],[],1,[Source,Destination,NewRange]).
	
search([[[Source,Destination,Range],Parent]])
	
newRange([T],[T|X]):-
	nextDay(T,X).

newRange([H|T],[Previous,H|NewT]):-
	nextDay(Previous,H),
	last(T,Last),
	nextDay(Last,Next),
	append(T,Next,NewT).
