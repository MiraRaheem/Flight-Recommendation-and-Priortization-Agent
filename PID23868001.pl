/*PID23868001
 * CS361 / Artificial Intelligence
 * Final Assessment Project
 * Travel Agent (Search Problem Topic 1)
 *
 * Prepared To:
 * Dr. Abeer El-Korany
 * Dr. Khaled Wassif
 *
 * Prebared By:
 * Mira Mohamed Adb-ElRaheem   20170305
 * Nehal Akram Ahmed           20170318
 * Nouran Qassem Mohamed       20170322
 * Nourhan Ihab El-Khodary     20170324
 */

/*The query the user enters Is set as the goal and getting its heuristic then starting the search for the best path by calling the path*/
travel(Source,Destination,Range):-
		Goal = [Source,Destination,Range,0,0,0,0,0,noday],
		getHeuristic([Source,Destination,Range],H),
		path([[[Source,Destination,Range,0,0,0,0,0,noday],null,0,H,H]],[],0,Goal).

/*If no solution was found even after expanding the range*/
path([], _,1, _):-
		write('No solution'),nl,!.

/*If no solution was found the range is expanded and returns to search for a path again*/
path([],_,0,[Source,Destination,Range|T]):-
	newRange(Range, NewRange),
	getHeuristic([Source,Destination,NewRange],H),
	write(" No flights found in this range, so we expand the range "), nl,
	path([[[Source,Destination,NewRange|T],null,0,H,H]],[],1,[Source,Destination,NewRange|T]).

/*If the destination of a flight is thae same as the goals destination the solution is found and printed*/
path(Open, Closed,_,[_,Destination|_]):-
		getBestChild(Open, [[SourceGoal,DestinationGoal,RangeGoal,LH,LM,AH,AM,FN,Days], Parent, PC, H, TC], _),
		Destination == DestinationGoal,
		Parent \== null,
		write('A solution is found'),  nl,
		printsolution([[SourceGoal,DestinationGoal,RangeGoal,LH,LM,AH,AM,FN,Days],Parent, PC, H, TC], Closed),!.

/*Search for the best path by getting the best children to the state */
path(Open, Closed,NumOfRangeInc, Goal):-
		getBestChild(Open, [State, Parent, PC, H, TC], RestOfOpen),
		getchildren(State, Open, Closed, Children, PC, Goal),
		addListToOpen(Children , RestOfOpen, NewOpen),
		path(NewOpen, [[State, Parent, PC, H, TC] | Closed], NumOfRangeInc, Goal),!.

/*the stopping base case to getBestChild*/
getBestChild([Child], Child, []).

/*Gets the best state from the open list and if found remove the state from the open list*/
getBestChild(Open, Best, RestOpen):-
	getBestChild1(Open, Best),
	removeFromList(Best, Open, RestOpen).

/*stop the state is the best child available*/
getBestChild1([State], State).

/*get the best child depending on the total cost*/
getBestChild1([State|Rest], Best):-
	getBestChild1(Rest, Temp),
	getBest(State, Temp, Best).

/*Compare the cost of the state and the next state and get the state with lowest cost*/
getBest([State, Parent, PC, H, TC], [_, _, _, _, TC1], [State, Parent, PC, H, TC]):-
	TC < TC1, !.

/*Stopping base case*/
getBest([_, _, _, _, _], [State1, Parent1, PC1, H1, TC1], [State1, Parent1, PC1, H1, TC1]).

/*When the lists are empty stop and backtrack*/
removeFromList(_, [], []).

/*removes the state from the list when found*/
removeFromList(H, [H|T], V):-
	!, removeFromList(H, T, V).

/*loops on the list to reach the atate that needs to be deleted*/
removeFromList(H, [H1|T], [H1|T1]):-
	removeFromList(H, T, T1).

/*Gets all safe moves for a state*/
getchildren(State, Open ,Closed , Children, PC, Goal):-
		findall(X, moves(State, Open, Closed, X, PC, Goal), Children).

/*Gets a move and check if it is safe or not, if yes add it if it was not in the open list and visited list, the calculate its cost and heuristic cost*/
moves(State, Open, Closed,[Next,State, NPC, H, TC], PC, Goal):-
		move(State,Next,Goal),
		unsafe(State,Next,Goal),
		not(member([Next, _, _, _, _],Open)),
		not(member([Next, _, _, _, _],Closed)),
		waitingTime(State,Next,WaitingTime),
		calculate_pathcost(State,Next,PC,NPC,WaitingTime),
		getHeuristic(Next, H),
		TC is NPC + H.

/*Find if there is a direct flight*/
move([Source,Destination|_],Next,[Source,Destination|_]):-
	flight(Source,Des,time(LH,LM),time(AH,AM),FN,Days),
	Next = [Source,Des,Days,LH,LM,AH,AM,FN,_].

/*if there is not a direct flights search for availble flights with transits*/
move([_,Destination|_],Next,[_,DestinationGoal|_]):- %[mon tues]
	Destination \== DestinationGoal,
	flight(Destination,NextDestination,time(LH,LM),time(AH,AM),FN,Days),
	Next = [Destination,NextDestination,Days,LH,LM,AH,AM,FN,_].

/*Check if the state is safe by checking if it is within the range and the time is right considering the last flight*/
unsafe([_,_,Days,ParentLH,_,ParentAH,ParentAM|_],[_,_,Range,NextLH,NextLM,_,_,_,ChoosenDay],[_,_,[HRangeGoal|T]|_]):-
	parsing([HRangeGoal|T],Range,0,NewCounter,ChoosenDay),
	ChoosenDay\== noday,
	NewCounter > 0,
	checkDay(ChoosenDay,HRangeGoal,ParentLH,ParentAH,ParentAM,NextLH,NextLM),!;
	unsafe([_,_,Days,ParentLH,_,ParentAH,ParentAM|_],[_,_,Range,NextLH,NextLM,_,_,_,_],[_,_,T|_]).

/*if the day chosen was it right find another day*/
unsafe([_,_,Days,_,_,ParentAH,ParentAM|_],[_,_,Range,NextLH,NextLM,_,_,_,ChoosenDay],[_,_,[HRangeGoal|T]|_]):-
	parsing([HRangeGoal|T],Range,0,_,ChoosenDay),
	ChoosenDay == noday,
	unsafe([_,_,Days,_,_,ParentAH,ParentAM|_],[_,_,Range,NextLH,NextLM,_,_,_,_],[_,_,T|_]).

/*Stopping case for the parsing and then backtrack*/
parsing([],_,Counter,Counter,noday).

/*check if the days of flight is within the range that the user required*/
parsing([H|T],Days,Counter,NewCounter,ChoosenDay):-
	member(H,Days) -> NewCounter is Counter + 1, ChoosenDay = H;
						parsing(T,Days,Counter,NewCounter,ChoosenDay).

/*if the 2 flight are on the same day check if he will reach on a day he requested*/
checkDay(Day,Day,ParentLH,ParentAH,_,NextLH,_):-
	NextLH > ParentAH,
	CheckTime = ParentAH - ParentLH,
	CheckTime >= 0,!.

/*if the two flights are on the day make sure that the second flight is after the arrival of the first flight*/
checkDay(Day,Day,ParentLH,ParentAH,ParentAM,NextLH,NextLM):-
	NextLH = ParentAH,
	NextLM > ParentAM,
	CheckTime = ParentAH - ParentLH,
	CheckTime >= 0,!.

/*if the flights are not on the same day make sure that the first flight in in the day before the next flight*/
checkDay(Day,NDay,ParentLH,ParentAH,_,NextLH,_):-
	Day \== NDay,
	nextDay(Day,NDay),
	ParentLH > ParentAH-> NextLH > ParentAH.

/*if the starting city the same as the next flight city that means that the user just started travelling so there is no waiting time*/
waitingTime([Source|_],[Source|_],0):- !.

/*if the flights are not on the same day the waiting time calculation differs*/
waitingTime([_,_,_,_,_,ParentAH,ParentAM,_,ChoosenDay],[_,_,_,NextLH,NextLM,_,_,_,ChoosenDay],WaitingTime):-
			WaitingTime is ((24 - ParentAH + NextLH)*60 + (NextLM-ParentAM)),!.

/*if the flights are on the same day just subtract the leaving of the second with the departure of the first*/
waitingTime([_,_,_,_,_,ParentAH,ParentAM|_],[_,_,_,NextLH,NextLM|_],WaitingTime):-
			WaitingTime is ((NextLH - ParentAH)*60) + (NextLM-ParentAM).

/*if the flight was direct*/
calculate_pathcost([Source|_],[Source,_,_,NextLH,NextLM,NextAH,NextAM,_,_],PC,NPC,_):-
		NextAH >= NextLH-> NPC is PC + ((NextAH-NextLH)*60+(NextAM-NextLM)),!;
							NPC is PC + ((NextLH-NextAH)*60+(NextLM-NextAM)),!.

/*if there is transits and the flights are on the same day*/
calculate_pathcost([_,_,_,_,_,_,_,_,ChoosenDay],[_,_,_,NextLH,NextLM,NextAH,NextAM,_,ChoosenDay],PC,NPC,Waitingtime):-
		NextAH >= NextLH-> NPC is PC + ((NextAH-NextLH)*60+(NextAM-NextLM)) + Waitingtime,!;
							NPC is PC + ((NextLH-NextAH)*60+(NextLM-NextAM)) + Waitingtime,!.

/*if there is transits and the flights are on the different day*/
calculate_pathcost(_,[_,_,_,NextLH,NextLM,NextAH,NextAM,_,_],PC,NPC,Waitingtime):-
		NextAH >= NextLH -> NPC is PC + ((NextAH-NextLH)*60+(NextAM-NextLM)) + Waitingtime;
							NPC is PC + ((NextLH-NextAH)*60+(NextLM-NextAM)) + Waitingtime.

/*get the heuristic cost of the state by getting the distance between the source and destination and dividing it with tha average velocity of the commercial airplane to estimate the time taken for the flight*/
getHeuristic([Source,Destination|_],H):-
	getLat_Long(Source,Destination,Lat1, Lon1, Lat2, Lon2),
	distance(Lat1, Lon1, Lat2, Lon2, Distance),
	Avg_aeroplane is 15,
	Dis is round(Distance),
	H is div(Dis,Avg_aeroplane).

/*Get the latitude and the longtude og the source and destination*/
getLat_Long(Des,FDestination,Lat1, Lon1, Lat2, Lon2):-
	city(Des,Lat1, Lon1),
	city(FDestination,Lat2, Lon2).

/*Get the distance between the source and distination using their longtude ana latitude*/
distance(Lat1, Lon1, Lat2, Lon2, Distance):-
    P is 0.017453292519943295,
    A is (0.5 - cos((Lat2 - Lat1) * P) / 2 + cos(Lat1 * P) * cos(Lat2 * P) * (1 - cos((Lon2 - Lon1) * P)) / 2),
    Distance is (12742 * asin(sqrt(A))).

/*add the child to the open list*/
addListToOpen(Children, [], Children).

addListToOpen(Children, [H|Open], [H|NewOpen]):-
		addListToOpen(Children, Open, NewOpen).

/*Get the day after for the expansion*/
newRange([T],[T|[X]]):-
	nextDay(T,X).

/*Get the previous day for the expansion the the lats day*/
newRange([H|T],[Previous,H|[NewT]]):-
	nextDay(Previous,H),
	last(T,Last),
	nextDay(Last,Next),
	append(T,Next,NewT).

printsolution([_, null, _, _, _],_).

printsolution([[Source,Destination,_,LH,LM,AH,AM,FN,_], [PreSource,PreDestination,R,PreLH,PreLM,PreAH,PreAM,PreFN,PreDay], _, _,_], Closed):-
		member([[PreSource,PreDestination,R,PreLH,PreLM,PreAH,PreAM,PreFN,PreDay], GrandParent, PC1, H1, TC1], Closed),
		printsolution([[PreSource,PreDestination,R,PreLH,PreLM,PreAH,PreAM,PreFN,PreDay], GrandParent, PC1, H1, TC1], Closed),
		write("Flight number: "), write(FN),write(" From "), write(Source),write(" to "),write(Destination),write(". "),
		write(LH),write(":"),write(LM),write(" and arrival time "),write(AH),write(":"),write(AM),write("."),nl.


nextDay(sun,mon).
nextDay(mon,tue).
nextDay(tue,wed).
nextDay(wed,thu).
nextDay(thu,fri).
nextDay(fri,sat).
nextDay(sat,sun).

flight("Alexandria", "Aswan", time(11, 00), time(12, 15), "MS005", [mon, tue, wed]).
flight("Alexandria", "Aswan", time(15, 15), time(16, 30), "MS004", [sat, fri]).
flight("Alexandria", "Cairo", time(9, 15), time(10, 00), "MS003", [mon, tue, wed]).
flight("Alexandria", "Cairo", time(12, 30), time(13, 15), "MS001", [sat, sun]).
flight("Alexandria", "Cairo", time(17, 00), time(17, 45), "MS002", [sat, mon, thu, fri]).
flight("Alexandria", "London", time(19, 30), time(0, 32), "MS006", [sat, sun, thu, fri]).
flight("Alexandria", "New York", time(2, 00), time(15, 14), "MS007", [sun, tue, thu]).
flight("Aswan", "Cairo", time(10, 20), time(11, 40), "MS022", [sat, sun, mon, wed]).
flight("Aswan", "Port Said", time(7, 05), time(8, 18), "MS023", [tue, thu, fri]).
flight("Cairo", "Alexandria", time(13, 00), time(13, 45), "MS008", [sun, mon, wed]).
flight("Cairo", "Alexandria", time(20, 15), time(21, 00), "MS009", [thu, fri]).
flight("Cairo", "Aswan", time(8, 00), time(9, 20), "MS010", [sun, wed]).
flight("Cairo", "Aswan", time(17, 15), time(18, 35), "MS011", [sat, tue, thu]).
flight("Cairo", "London", time(10, 00), time(15, 10), "MS014", [sun, mon, tue]).
flight("Cairo", "London", time(15, 15), time(20, 25), "MS015", [sat, wed, thu]).
flight("Cairo", "New York", time(3, 00), time(15, 05), "MS016", [sat, sun, wed]).
flight("Cairo", "New York", time(19, 30), time(7, 35), "MS017", [mon, tue, fri]).
flight("Cairo", "Paris", time(2, 00), time(6, 55), "MS018", [wed, thu, fri]).
flight("Cairo", "Paris", time(5, 00), time(9, 55), "MS019", [sat, mon]).
flight("Cairo", "Port Said", time(11, 00), time(11, 20), "MS013", [mon]).
flight("Cairo", "Port Said", time(19, 30), time(19, 50), "MS012", [sat, sun, wed, thu]).
flight("Cairo", "Rome", time(6, 00), time(9, 30), "MS021", [sat, sun, tue, thu]).
flight("Cairo", "Shanghai", time(5, 30), time(19, 00), "MS020", [sat, sun, mon, wed]).
flight("Chicago", "London", time(8, 00), time(18, 32), "DL050", [sun, tue, thu, fri]).
flight("Chicago", "London", time(12, 10), time(22, 42), "DL051", [sat, mon, wed]).
flight("Chicago", "Miami", time(10, 00), time(14, 20), "DL046", [sat, sun, mon ,fri]).
flight("Chicago", "Miami", time(17, 20), time(21, 40), "DL047", [sun, tue]).
flight("Chicago", "New York", time(9, 00), time(11, 18), "DL044", [sat, mon, wed, fri]).
flight("Chicago", "New York", time(15, 00), time(17, 18), "DL045", [sun, tue]).
flight("Chicago", "Paris", time(5, 00), time(16, 55), "DL052", [sat, sun, tue, thu]).
flight("Chicago", "San Francisco", time(16, 00), time(22, 10), "DL048", [thu, fri]).
flight("Chicago", "San Francisco", time(20, 00), time(2, 10), "DL049", [sun, mon, tue]).
flight("Edinburgh", "London", time(7, 00), time(8, 15), "BA128", [sat, sun, mon, tue, wed, thu, fri]).
flight("Edinburgh", "London", time(19, 15), time(20, 30), "BA129", [sat, sun, mon, tue, wed, thu, fri]).
flight("Edinburgh", "Paris", time(14, 00), time(15, 50), "BA130", [sat, mon, tue, wed, fri]).
flight("Edinburgh", "San Francisco", time(3, 00), time(15, 10), "BA131", [sat, sun, mon, thu]).
flight("Liverpool", "London", time(4, 30), time(5, 30), "BA125", [wed, thu, fri]).
flight("Liverpool", "London", time(10, 00), time(11, 00), "BA123", [sat, sun, mon, tue, wed, thu, fri]).
flight("Liverpool", "London", time(16, 00), time(17, 00), "BA124", [sat, sun, mon]).
flight("London", "Alexandria", time(6, 00), time(11, 20), "BA149", [sun, mon, wed]).
flight("London", "Cairo", time(10, 00), time(14, 40), "BA143", [sat, sun, tue, fri]).
flight("London", "Cairo", time(20, 00), time(0, 40), "BA144", [tue, thu]).
flight("London", "Chicago", time(4, 00), time(12, 50), "BA147", [sat, sun, mon, tue, wed, thu, fri]).
flight("London", "Edinburgh", time(5, 00), time(6, 15), "BA134", [sat, sun, mon, tue, wed, thu, fri]).
flight("London", "Edinburgh", time(17, 00), time(18, 15), "BA135", [sun, wed, fri]).
flight("London", "Liverpool", time(8, 40), time(9, 40), "BA132", [sat, sun, mon, tue, wed, thu, fri]).
flight("London", "Liverpool", time(21, 00), time(22, 00), "BA133", [sun, mon, thu, fri]).
flight("London", "Lyon", time(15, 00), time(16, 35), "BA150", [tue, wed, thu, fri]).
flight("London", "Manchester", time(10, 00), time(11, 00), "BA136", [sat, sun, mon, tue, wed, thu, fri]).
flight("London", "New York", time(5, 00), time(13, 00), "BA138", [sat, sun, mon, tue, wed, thu, fri]).
flight("London", "New York", time(14, 00), time(22, 00), "BA145", [sat, sun, mon, tue, wed, thu, fri]).
flight("London", "Paris", time(6, 30), time(7, 40), "BA140", [mon, tue, thu, fri]).
flight("London", "Paris", time(16, 00), time(17, 10), "BA139", [sat, sun, mon, tue, wed, thu, fri]).
flight("London", "Rome", time(17, 00), time(19, 20), "BA141", [sat, sun, mon, tue, wed, thu, fri]).
flight("London", "San Francisco", time(15, 30), time(2, 30), "BA146", [sat, sun, mon, tue, wed, thu, fri]).
flight("London", "Shanghai", time(4, 30), time(15, 30), "BA142", [mon, tue, fri]).
flight("London", "Shanghai", time(11, 00), time(22, 00), "BA137", [sat, sun, mon, tue, wed, thu, fri]).
flight("London", "Tokyo", time(14, 00), time(1, 40), "BA148", [sat, sun, wed, thu]).
flight("Lyon", "Nice", time(2, 10), time(3, 00), "AF122", [sat, sun, mon, tue, wed, thu, fri]).
flight("Lyon", "Nice", time(13, 30), time(14, 20), "AF121", [sat, tue, wed, thu, fri]).
flight("Lyon", "Paris", time(9, 00), time(10, 05), "AF119", [sat, sun, mon, tue, wed, thu, fri]).
flight("Lyon", "Paris", time(18, 00), time(19, 05), "AF120", [sat, sun, mon, tue, wed, thu, fri]).
flight("Manchester", "London", time(11, 30), time(12, 30), "BA126", [sat, sun, mon, tue, wed, thu, fri]).
flight("Manchester", "London", time(18, 30), time(19, 30), "BA127", [sat, sun, mon, tue, wed]).
flight("Miami", "Chicago", time(8, 00), time(12, 20), "DL056", [mon, wed, fri]).
flight("Miami", "New York", time(10, 00), time(12, 55), "DL053", [sun, mon ,tue]).
flight("Miami", "New York", time(16, 00), time(18, 55), "DL054", [wed, thu, fri]).
flight("Miami", "San Francisco", time(10, 00), time(16, 25), "DL055", [sat, sun, mon, wed]).
flight("Milan", "London", time(14, 00), time(15, 50), "AZ103", [sat, sun, mon, tue, wed, thu, fri]).
flight("Milan", "Paris", time(10, 00), time(11, 20), "AZ101", [sat, sun, tue, wed]).
flight("Milan", "Paris", time(16, 00), time(17, 20), "AZ102", [mon, fri]).
flight("Milan", "Rome", time(1, 00), time(2, 05), "AZ104", [mon, thu, fri]).
flight("Milan", "Rome", time(7, 00), time(8, 05), "AZ099", [sat, sun, mon, tue, wed, thu, fri]).
flight("Milan", "Rome", time(17, 00), time(18, 05), "AZ100", [sat, sun, mon, tue, wed, thu, fri]).
flight("New York", "Chicago", time(7, 00), time(9, 18), "DL028", [sat, mon, tue]).
flight("New York", "Chicago", time(13, 20), time(15, 38), "DL029", [sat, sun, thu]).
flight("New York", "Edinburgh", time(6, 00), time(15, 05), "DL038", [sun, wed, fri]).
flight("New York", "London", time(4, 00), time(10, 50), "DL037", [sat, mon, tue, thu]).
flight("New York", "Lyon", time(13, 00), time(22, 12), "DL041", [sat, mon, tue]).
flight("New York", "Miami", time(1, 00), time(3, 55), "DL036", [tue]).
flight("New York", "Miami", time(7, 15), time(10, 10), "DL035", [wed, thu, fri]).
flight("New York", "Miami", time(12, 00), time(14, 55), "DL034", [sat, sun, mon]).
flight("New York", "Paris", time(11, 00), time(17, 50), "DL040", [sun, wed, thu, fri]).
flight("New York", "Rome", time(10, 15), time(18, 30), "DL039", [sat, mon, tue, thu]).
flight("New York", "San Francisco", time(8, 00), time(14, 32), "DL030", [sun, mon]).
flight("New York", "San Francisco", time(10, 00), time(16, 32), "DL031", [wed, fri]).
flight("New York", "San Francisco", time(18, 00), time(0, 32), "DL032", [thu]).
flight("New York", "San Francisco", time(23, 30), time(6, 02), "DL033", [sat, tue]).
flight("New York", "Shanghai", time(5, 00), time(19, 50), "DL043", [sat, mon, wed, fri]).
flight("New York", "Tokyo", time(0, 00), time(13, 45), "DL042", [sat, sun, tue, thu]).
flight("Nice", "Lyon", time(20, 00), time(20, 50), "AF118", [sat, sun, mon, tue, wed, thu, fri]).
flight("Nice", "Paris", time(5, 00), time(6, 20), "AF117", [sat, sun, mon, tue, wed, thu, fri]).
flight("Nice", "Paris", time(14, 30), time(15, 50), "AF116", [sat, sun, fri]).
flight("Paris", "London", time(9, 00), time(10, 05), "AF105", [sat, sun, mon, tue, wed, thu, fri]).
flight("Paris", "London", time(22, 00), time(23, 05), "AF106", [sat, sun, mon, tue, wed, thu, fri]).
flight("Paris", "Lyon", time(7, 00), time(8, 10), "AF114", [mon, tue, wed, thu]).
flight("Paris", "Lyon", time(14, 00), time(15, 10), "AF115", [sat, sun, mon, tue, wed, thu, fri]).
flight("Paris", "New York", time(12, 00), time(20, 30), "AF107", [sat, sun, mon, tue, wed, thu, fri]).
flight("Paris", "New York", time(17, 30), time(2, 00), "AF108", [sat, sun, fri]).
flight("Paris", "Nice", time(11, 00), time(12, 20), "AF112", [sat, sun, mon, tue, wed, thu, fri]).
flight("Paris", "Nice", time(16, 00), time(17, 20), "AF113", [sat, sun, mon, tue, wed, thu, fri]).
flight("Paris", "Rome", time(10, 00), time(12, 00), "AF110", [sat, sun, mon, tue, wed, thu, fri]).
flight("Paris", "Rome", time(18, 00), time(20, 00), "AF109", [sun, tue, wed, fri]).
flight("Paris", "Shanghai", time(4, 00), time(15, 55), "AF111", [sat, mon]).
flight("Port Said", "Alexandria", time(12, 00), time(12, 30), "MS026", [sun, mon, wed]).
flight("Port Said", "Alexandria", time(14, 45), time(15, 15), "MS027", [sat, tue, thu]).
flight("Port Said", "Cairo", time(11, 00), time(11, 20), "MS024", [sat, mon]).
flight("Port Said", "Cairo", time(14, 10), time(14, 30), "MS025", [wed, fri]).
flight("Rome", "London", time(1, 00), time(3, 30), "AZ091", [sat, sun, mon, tue, wed, thu, fri]).
flight("Rome", "London", time(11, 30), time(14, 00), "AZ090", [sat, sun, mon, tue, wed, thu, fri]).
flight("Rome", "Milan", time(8, 00), time(9, 05), "AZ094", [sat, sun, mon, tue, wed, thu, fri]).
flight("Rome", "Milan", time(22, 00), time(23, 05), "AZ095", [mon, wed, thu, fri]).
flight("Rome", "New York", time(4, 00), time(13, 48), "AZ088", [sat, sun, mon, tue, wed, thu, fri]).
flight("Rome", "New York", time(17, 00), time(2, 48), "AZ089", [tue, wed, fri]).
flight("Rome", "Paris", time(8, 00), time(10, 00), "AZ086", [sat, sun, mon, tue, wed, thu, fri]).
flight("Rome", "Paris", time(20, 00), time(22, 00), "AZ087", [mon, tue, thu, fri]).
flight("Rome", "Venice", time(11, 00), time(12, 00), "AZ092", [sat, sun, mon, tue, wed, thu, fri]).
flight("Rome", "Venice", time(18, 00), time(19, 00), "AZ093", [sat, mon, wed, fri]).
flight("San Francisco", "Chicago", time(7, 00), time(13, 10), "DL059", [tue, wed, thu]).
flight("San Francisco", "Chicago", time(14, 00), time(20, 10), "DL060", [sat, sun, fri]).
flight("San Francisco", "Miami", time(11, 00), time(17, 25), "DL061", [sun, mon ,wed, thu]).
flight("San Francisco", "New York", time(6, 00), time(12, 32), "DL057", [wed, thu, fri]).
flight("San Francisco", "New York", time(13, 00), time(19, 32), "DL058", [sat, sun, mon]).
flight("Shanghai", "Cairo", time(2, 00), time(16, 30), "CA070", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Cairo", time(7, 00), time(21, 30), "CA068", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Cairo", time(13, 30), time(4, 00), "CA069", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Chicago", time(6, 00), time(19, 45), "CA080", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Chicago", time(15, 00), time(4, 45), "CA081", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "London", time(0, 40), time(13, 20), "CA071", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "London", time(5, 30), time(18, 10), "CA072", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "London", time(14, 00), time(2, 40), "CA073", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "New York", time(1, 00), time(15, 50), "CA079", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "New York", time(10, 00), time(0, 50), "CA078", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Paris", time(2, 00), time(14, 25), "CA076", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Paris", time(8, 00), time(20, 25), "CA077", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Rome", time(6, 00), time(19, 10), "CA074", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Rome", time(17, 00), time(6, 10), "CA075", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Tokyo", time(5, 00), time(7, 50), "CA085", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Tokyo", time(12, 00), time(14, 50), "CA082", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Tokyo", time(16, 00), time(18, 50), "CA083", [sat, sun, mon, tue, wed, thu, fri]).
flight("Shanghai", "Tokyo", time(21, 00), time(23, 50), "CA084", [sat, sun, mon, tue, wed, thu, fri]).
flight("Tokyo", "San Francisco", time(12, 00), time(21, 05), "JL066", [sat, sun, mon, wed, thu]).
flight("Tokyo", "San Francisco", time(22, 00), time(7, 05), "JL067", [sat, mon, tue, thu, fri]).
flight("Tokyo", "Shanghai", time(0, 00), time(2, 50), "JL063", [sun, tue, thu, fri]).
flight("Tokyo", "Shanghai", time(6, 10), time(9, 00), "JL064", [sun, mon, tue, wed]).
flight("Tokyo", "Shanghai", time(9, 00), time(11, 50), "JL065", [sat, thu, fri]).
flight("Tokyo", "Shanghai", time(20, 00), time(22, 50), "JL062", [sat, sun, mon, wed]).
flight("Venice", "Rome", time(5, 00), time(6, 00), "AZ096", [sat, sun, mon, tue, wed, thu, fri]).
flight("Venice", "Rome", time(14, 00), time(15, 00), "AZ097", [sat, sun, mon, tue, wed, thu, fri]).
flight("Venice", "Rome", time(19, 40), time(20, 40), "AZ098", [sat, sun, mon, tue, wed, thu, fri]).

city("Alexandria", 31.2, 29.95).
city("Aswan", 24.0875, 32.8989).
city("Cairo", 30.05, 31.25).
city("Chicago", 41.8373, -87.6862).
city("Edinburgh", 55.9483, -3.2191).
city("Liverpool", 53.416, -2.918).
city("London", 51.5, -0.1167).
city("Lyon", 45.77, 4.83).
city("Manchester", 53.5004, -2.248).
city("Miami", 25.7839, -80.2102).
city("Milan", 45.47, 9.205).
city("New York", 40.6943, -73.9249).
city("Nice", 43.715, 7.265).
city("Paris", 48.8667, 2.3333).
city("Port Said", 31.26, 32.29).
city("Rome", 41.896, 12.4833).
city("San Francisco", 37.7562, -122.443).
city("Shanghai", 31.2165, 121.4365).
city("Tokyo", 35.685, 139.7514).
city("Venice", 45.4387, 12.335).
