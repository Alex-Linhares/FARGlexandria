unit ExternalMemoryUnit;

interface
uses graphics, stdctrls, classes;
                                           
const Queenvalue = 20; KingValue=100;

type
    TPiecetype = (None, Pawn, Knight, Rook, King, Queen, Bishop);

    TPlayerColor = boolean;

    Tsquare = record
                 X: integer;
                 Y: Integer;
              end;

    PTsquare = ^Tsquare;

    TTerrain = record
                 white: boolean;
                 piece: tpiecetype;
                 distance:integer;
                 previous:Tsquare;
                 blockedness:integer;
               end;

    TpieceMobility = array [1..8,1..8] of TTerrain;

    TPiece = class
                 sq: Tsquare;
                 PPosition: ^Tsquare;
                 White: boolean;
                 Pwhite: ^boolean;
                 PieceType: TPieceType;
                 PieceBitmap: TBitmap;
                 Mobility: TPieceMobility;
                 DynamicValue:integer;
                 PieceName, Fullname: string;

                 AbstractRoles: Tlist; {of TPARAMABSTRACTROLE}

                 Safety: integer; {Reachable by enemy? Guarded by friends?} {use scale of 1 to 1000}
                 UnsafeMobility: integer;
                 Jewlery:integer;
                 Reaches: integer; {Value of /link to the pieces reached by this piece}

                 Constructor Create; overload;
                 Constructor create (P: Tsquare; W:Boolean; Tp:TPieceType); overload;
                 Procedure Load_Data; virtual; abstract;
                 Procedure Display (Canvas:Tcanvas);
                 Procedure Display2 (Canvas:Tcanvas);
                 function getnextmoves(P:TSquare):Tlist; virtual; abstract;
                 function GetThreathenedSquares(P:Tsquare):Tlist; virtual; abstract;
                 function GetIndexParamAbstractRoles(square: Tsquare): integer;
                 function isDefending(square:tsquare):boolean;
                 Procedure DeleteRole (square:tsquare);
                 procedure deleteabstractroles(s:tsquare);
                 Function Gettrajectories(Dest1:Tsquare):Tlist;
                 Function Trajectory_Is_safe (Square: Tsquare):boolean;
                 procedure ComputeMobility;
                 Procedure liberate_from_role (destsquare1:Ptsquare; pmemo: tmemo);
                 Function Forbidden_Squares (distance:integer):TList;
                 procedure Forbid_square(squ:tsquare);
                 Procedure minimize_role (destinationsquare:tsquare);
                 Procedure map_Current_Terrain;
                 Procedure Release_Intensity_of_Guarding;
                 function TrajectoryFinder (DestinationSquare:tsquare): Tlist;
                 function Attacks_These_Guys: tlist;
                 function Guards_These_Guys: tlist;
                 function Guardian_Roles:tlist;
                 Function isAttacker: boolean;
                 Function isGuardian: boolean;
                 function numroles:string;
                 function FullId:string;
                 function Are_trajectories_equal(Traj1, Traj2:Tlist):boolean;
                 Procedure Launch_Impulse_Finding_Relation_To (Destination:tsquare; Pmemo:tmemo); overload;
                 Procedure Launch_Impulse_Finding_Relation_To (Destination:tpiece; Pmemo:tmemo); overload;
                 Destructor destroy;  override;
            end;

    PTPiece = ^TPiece;

    TPawn = class (Tpiece)
                  Procedure Load_Data; override;
                  function getnextmoves(P:Tsquare):Tlist; override;
                  function GetThreathenedSquares(P:Tsquare):Tlist; override;
            end;
    TKing = class (Tpiece)
                  Procedure Load_Data; override;
                  function getnextmoves(P:Tsquare):Tlist; override;
                  function GetThreathenedSquares(P:Tsquare):Tlist; override;
            end;
    TKnight = class (Tpiece)
                  Procedure Load_Data; override;
                  function getnextmoves(P:Tsquare):Tlist; override;
                  function GetThreathenedSquares(P:Tsquare):Tlist; override;
            end;

    TBishop = class (Tpiece)
                  Procedure Load_Data; override;
                  function getnextmoves(P:Tsquare):Tlist; override;
                  function GetThreathenedSquares(P:Tsquare):Tlist; override;
            end;

    TRook = class (Tpiece)
                  Procedure Load_Data; override;
                  function getnextmoves(P:Tsquare):Tlist; override;
                  function GetThreathenedSquares(P:Tsquare):Tlist; override;
            end;

    TQueen = class (Tpiece)
                  Procedure Load_Data; override;
                  function getnextmoves(P:Tsquare):Tlist; override;
                  function GetThreathenedSquares(P:Tsquare):Tlist; override;
            end;

   TExternalPiece = class (TPiece)
                       constructor create(P: Tsquare; W:Boolean; Tp:TPieceType);
                       procedure load_data; override;
                   end;


   TExternalMemory = class
                         square:Array[1..8,1..8] of Tpiecetype;
                         white:Array[1..8,1..8] of boolean;
                         found:array[1..8,1..8] of boolean;
                         flood:Array[1..8,1..8]of integer;
                         Constructor create;
                    end;

   TExternalmemorypiece = class (TexternalMemory)
                               Piece: TPiece;
                               constructor create(P: Tsquare; W:Boolean; Tp:TPieceType);
                           end;

function convertsquare(x,y:integer):string;
function squarename(s:tsquare):string;
Function TPieceFactoryMethod(destsquare1:tsquare; white:boolean; Ptype:TpieceType): tpiece;

var     ExternalMemory:  TExternalMemory;


implementation

uses workingmemoryunit, basicImpulse, abstractimpulses;

Function TPiece.Gettrajectories(Dest1:Tsquare):Tlist;
var count:integer; Param:TParamAbstractRole; T:Tlist; dest2:^tsquare;
begin
     T:=Tlist.create;
     for count := 0 to AbstractRoles.count-1 do
     begin
          Param:=AbstractRoles.items[count];
          {Dest2:=GetDest(P);} {you can also look at the last square at the traj if the bugs go on}
          Dest2:= Param.Trajectory.items[Param.Trajectory.count-1];
          if (Dest2^.x=Dest1.x) and (Dest2^.y=Dest1.y) then
             T.Add(Param);
     end;
     result:=t;
end;

Procedure TPiece.Launch_Impulse_Finding_Relation_To (Destination:tsquare; Pmemo:tmemo);
var    traj:tlist; ParamImpAbsRole: ^TParamAbstractRole; impulse: ^Timpulse;
begin
     if (mobility[Destination.x,Destination.y].distance<>10000) then
     begin
          traj:=trajectoryfinder(Destination);
          New (impulse);
          new (ParamImpAbsRole);                           
          ParamImpAbsRole^:=TParamabstractRole.Create;
          ParamImpAbsRole.Trajectory:=traj;
          ParamImpAbsRole.Origin:=self;
          ParamImpAbsRole.DestinationSquare:=Destination;
          ParamImpAbsRole.pmemo:=pmemo;
          paramimpabsrole.impulsepointer:=impulse;
          Impulse^:= TImpulsePromotionRole.create (paramimpabsrole^, 45);
     end;
end;

Procedure TPiece.Launch_Impulse_Finding_Relation_To (Destination:tpiece; Pmemo:tmemo);
var    traj, AllTrajsToMEcca:tlist; ParamImpAbsRole: ^TParamAbstractRole;
       P: TParamAbstractRole; impulse: ^Timpulse;
begin
     if (mobility[Destination.sq.x,Destination.sq.y].distance<>10000) then
     begin
          traj:=trajectoryfinder(Destination.sq);
          New (impulse);
          new (ParamImpAbsRole);
          ParamImpAbsRole^:=TParamabstractRole.Create;
          ParamImpAbsRole.Trajectory:=traj;
          ParamImpAbsRole.Origin:=self;
          ParamImpAbsRole.Destination:=Destination;
          ParamImpAbsRole.DestinationSquare:=Destination.sq;
          ParamImpAbsRole.pmemo:=pmemo;
          paramimpabsrole.impulsepointer:=impulse;
          if (white <> Destination.white) then
             Impulse^:= TImpulseAttackerRole.create (ParamImpAbsRole^, 45)
          else
              Impulse^:= TImpulseGuardianRole.create (ParamImpAbsRole^, 45);
     end;


     {Launch new impulse to check whether there are more than one trajs, consolidate them in high intensity!!!
     Remember grasshopper... some functions have already been programmed!

     first as procedure, later as impulse;
     }

     AllTrajsToMEcca:=Gettrajectories(Destination.sq);
     if AllTrajsToMEcca.count>0 then
     begin
          P:=AllTrajsToMEcca.items[0];
          P.intensity:=110000;
     end;
     {falta deletar as trajetorias}


     {TPiece.Are_trajectories_equal(Traj1, Traj2:Tlist):boolean;}

end;

Procedure Tpiece.Release_Intensity_of_Guarding;
var roles: Tlist; Role_aux:TParamAbstractRole; count:integer;
begin
     Roles:= Guardian_Roles;
     for count:= 0 to roles.count-1 do
     begin
          Role_aux:= roles.items[count];
          role_aux.intensity:=role_aux.intensity div 10;
     end;
end;

Function TPieceFactoryMethod(destsquare1:tsquare; white:boolean; Ptype:TpieceType): tpiece;
var pt: ^tpiece;
begin
     new (pt);
     case PType of
          bishop: PT^:=tbishop.create(destsquare1, White, PType);
          pawn: PT^:=tpawn.create(destsquare1, White, PType);
          king: PT^:=tking.create(destsquare1, White, PType);
          queen: PT^:=tqueen.create(destsquare1, White, PType);
          rook: PT^:=trook.create(destsquare1, White, PType);
          knight: PT^:=tknight.create(destsquare1, White, PType);
     end;
     result:=pt^;
end;


Procedure TexternalPiece.Load_Data;
begin end;

function tpiece.Attacks_These_Guys:tlist;
var x: integer; list_aux:tlist; ABS: TParamabstractRole;
begin
     list_aux:=tlist.Create;
     for x:= 0 to abstractroles.count-1 do
     begin
          ABS:=AbstractRoles.Items[x];
          if abs.Roletype=attacker then
             list_aux.Add(abs.Destination);
     end;
     result:=list_aux;
end;

function tpiece.Guards_These_Guys:tlist;
var x: integer; list_aux:tlist; ABS: TParamabstractRole;
begin
     list_aux:=tlist.Create;
     for x:= 0 to abstractroles.count-1 do
     begin
          ABS:=AbstractRoles.Items[x];
          if abs.Roletype=guardian then
             list_aux.Add(abs.Destination);
     end;
     result:=list_aux;
end;

function tpiece.Guardian_Roles:tlist;
var x: integer; list_aux:tlist; ABS: TParamabstractRole;
begin
     list_aux:=tlist.Create;
     for x:= 0 to abstractroles.count-1 do
     begin
          ABS:=AbstractRoles.Items[x];
          if abs.Roletype=guardian then
             list_aux.Add(abs);
     end;
     result:=list_aux;
end;


function tpiece.IsAttacker:boolean;
var list:Tlist;
begin
     list:=Attacks_These_Guys;
     if list.count>0 then
        result:=true
     else result:= false;
end;

function tpiece.IsGuardian:boolean;
var list:Tlist;
begin
     list:=Guards_These_Guys;
     if list.count>0 then
        result:=true
     else result:= false;
end;


procedure tpiece.forbid_square(squ:tsquare);
begin
     deleteabstractroles(squ);
     mobility[squ.x,squ.Y].distance:=11000;
end;

function tpiece.numroles:string;
var s:string; x:integer;
begin
     x:=abstractroles.Count;
     str(x,S);
     result:= s;
end;

procedure tpiece.deleteabstractroles(s:tsquare);
var x :integer;
begin
     for x:= 1 to abstractroles.count do
         DeleteRole(s);
end;


function TPiece.Are_trajectories_equal(Traj1, Traj2:Tlist):boolean;
var count: integer; sq1, sq2: ^tsquare;
{should compare 2 trajectories exactly}
begin
     result:=true;
     count:= traj1.count-1;
     if count=traj2.count-1 then
     begin
          for count:= 0 to traj1.count-1 do
          begin
               sq1:=traj1.items[count];
               sq2:=traj2.items[count];
               if (sq1^.x<>sq2^.x) or (sq1^.y<>sq2^.y) then
                  result:=false;
          end;
     end;
end;



(*   The thing here is to build a function that creates a trajectory, then checks if
     there is one exactly equal, if so, create another one by selecting a random number,
     then checking if that square can be changed in the trajectory for another square,
     otherwise picks a random number 2 more times, then halts



     TPiece.Try_to_build_yet_another_Traj(Traj1):Tlist if successful
     select random position; get the value of the square of that position,
     change it to 11.000, then try by calling TrajectFinder, then rechange
     to original value

     call method to compare this traj with all others, if successful, halt, otherwise try again
     twice


begin
     count:= traj1.count-1;
     rnd:=random(count)-1; {or just random(count) if it never reaches count?}
     rnd:=rnd+2;
     squ1:=traj1.items[rnd];
     PreviousMobility:= mobility[squ1.x,squ1.y];
     mobility[squ1.x,squ1.y]:=11000;  {maybe has to computemobility here}
     NewTraj:=trajectoryFinder(destination);
     mobility[squ1.x,squ1.y]:=PreviousMobility; {maybe has to computemobility here again}
     if Are_trajectories_equal(Traj1, NewTraj);
end;


*)



function TPiece.trajectoryFinder(Destinationsquare:tsquare): Tlist;
var Traj: Tlist; t1, x, y, x1, y1: integer; squ: ^tsquare;
begin
     {Create trajectory between p1 and destinationsquare}
     Traj:=Tlist.create;
     x:=Destinationsquare.X;
     y:=Destinationsquare.y;
     t1:=mobility[x,y].distance;
     if t1<>11000 then
     begin
          if t1<0 then t1:=0-t1;
          new (squ);
          squ^.x:=x; squ^.y:=y;
          Traj.insert(0,squ);
          t1:=t1-1;
          while (t1>0) do
          begin
               new (squ);
               squ^:=mobility[x,y].Previous;
               x1:= mobility[x,y].Previous.x;
               y1:= mobility[x,y].Previous.y;
               x:=x1; y:=y1;
               Traj.insert(0,squ);
               t1:=t1-1;
          end;
          new (squ);
          squ^:=mobility[x,y].Previous;
          Traj.insert(0,squ);
          {result:=traj;}
     end;
     result:=traj;
end;

Function TPiece.Trajectory_is_safe(Square:Tsquare):boolean;
var x, aux:integer; squarept: ^tsquare; traj:tlist;
begin
     result:=false;
     if mobility[square.x,square.Y].distance<>11000 then
     begin
          result:=true;
          Traj:= TrajectoryFinder (Square);
          for x:= 0 to traj.count-1 do
          begin
               squarept:=traj.items[x];
               aux:=mobility[squarept^.x,squarept^.Y].distance;
               if (aux<0) or (aux=11000) then
                  result:=false;
          end;
     end;
end;


Procedure TPiece.map_Current_Terrain;
var NextMoves, FollowingMoves, NewList:Tlist; t,t1,x,y,expansion:integer;
    psquare, psquare2:^Tsquare; initial:boolean;

begin
      { generate floodfill urges to look at neighboring &
      potentially upcoming squares... with ever decreasing urgency.
      if it finds blocks, create block urges (originpiece, blockpiece/
      blocksquare) and estimate painness (height of blockdness) of that
      blockdness.  (What's the value of the unreachable objects?
      Whats the value of the desired attacks?  Whats the value of the needed
      defenses?) }

      NewList:=Tlist.create; newlist.clear;
      FollowingMoves:=TList.create;

      Expansion:=0;

      initial:=true;
      {generate list with immediate next moves}
      NextMoves:=Tlist.create;
      NextMoves.add(pposition); {epicenter}
      while (Nextmoves.count>0) do  {enquanto houver quadrados restando...}
      begin
           t:=0;
           while (t<NextMoves.count) do {...marque os atuais na Nextmoves...}
           begin
                psquare:=NextMoves.items[t];
                X:= PSQUARE^.x; y:= PSQUARE^.y;
                Mobility[X,Y].distance:=expansion;

                if ((externalmemory.square[x,y]<>none) and (not (initial)) and   {what does this do? it takes out a square occupied with same color piece from the list}
                (externalmemory.white[x,y]=white)) then
                begin
                     NextMoves.delete(t);
                     t:=t-1;
                end
                else if (white) and (WorkingMemory.BlackThreatens[x,y]=1) and (not (initial))then
                begin
                     Mobility[x,y].distance:=0-Mobility[x,y].distance;
                     NextMoves.delete(t);
                     t:=t-1;
                end
                else if (not white) and (WorkingMemory.WhiteThreatens[x,y]=1) and (not (initial)) then
                begin
                     Mobility[x,y].distance:=0-Mobility[x,y].distance;
                     NextMoves.delete(t);
                     t:=t-1;
                end;
                t:=t+1;
           end;
           initial:=false;
           expansion:=expansion+1;
           t:=0;
           while (t<NextMoves.count) do {...e obtenha os proximos a marcar...}
           begin
                psquare:=NextMoves.Items[t];
                FollowingMoves.clear;
                FollowingMoves:=GetNextMoves(psquare^); {captura os proximos quadrados...}
                T1:=0; {e somente insere na newlist aqueles nao preenchidos}
                while (T1<FollowingMoves.count) do
                begin
                     psquare2:= FollowingMoves.items[t1];
                     X:= PSQUARE2^.x; y:= PSQUARE2^.y;
                     if (Mobility[x,y].distance=10000) then
                     begin
                          NewList.add(psquare2);

                          {update in previous!}
                          Mobility[x,y].previous.x:=psquare^.x;
                          Mobility[x,y].previous.y:=psquare^.y;
                     end;
                     T1:=T1+1;
                end;
                t:=t+1;
           end;

           NextMoves.clear; {copy o conteudo de newlist para a nextmoves, para a proxima expansion}
           t1:=0;
           while (NewList.count>t1) do
           begin
                nextmoves.add(newlist.items[t1]);
                t1:=t1+1;
           end;
           NewList.clear;
           NextMoves.pack;
      end;
end;



function squarename(s:tsquare):string;
begin
     result:= convertsquare (s.X,s.Y);
end;

function convertsquare(x,y:integer):string;
var y1:integer; s1,s2,s:string;
begin
     Case x of
          1:s1:='A';
          2:s1:='B';
          3:s1:='C';
          4:s1:='D';
          5:s1:='E';
          6:s1:='F';
          7:s1:='G';
          8:s1:='H';
     end;
     if (x<1) or (x>8) then
     begin
          s:='error';
     end else
     begin
          y1:=9-Y;
          str(y1,s2);
          S:=s1+s2;
     end;
     result:=s;
end;

Procedure Tpiece.DeleteRole (square:tsquare);
var x:integer;
begin
     x:=GetIndexParamAbstractRoles(square);
     if x<>-13 then  {This means that there is such a trajectory}
        abstractroles.Delete(x);
end;

Function TPiece.Forbidden_Squares (distance:integer):TList;
var List: Tlist; x, y, aux:integer; psquare: ^tsquare;
begin
     Map_Current_Terrain;
     list:=tlist.Create;
     for x := 1 to 8 do
         for y:= 1 to 8 do
         if (x<>sq.x) or (y<>sq.y) then
         begin
              new(psquare);
              psquare^.x:=x; psquare^.Y:=y;
              aux:=Mobility[x,y].distance; if aux<0 then aux:=-aux;
              if (aux>=distance)then
                 List.Add(psquare);
         end;
     result:=list;
end;


Procedure TPiece.minimize_role (destinationsquare:tsquare);
var x:integer; R:TParamAbstractRole;
begin
     x:=GetIndexParamAbstractRoles(destinationsquare);
     if x<>-13 then  {This means that there is such a trajectory}
     begin
          R:=abstractroles.items[x];
          R.intensity:=r.intensity div 10;
     end;
{     deleteabstractroles(destinationsquare);}
end;

Procedure tpiece.liberate_from_role (destsquare1:ptsquare; pmemo: tmemo);
var y:integer; TABS:TParamAbstractRole;
begin
     y:=GetIndexParamAbstractRoles(destsquare1^);
     TABS:=AbstractRoles.Items[y];
     TABS.intensity:=1{TABS.intensity div 100};
     AbstractRoles.Delete(y);
     pmemo.lines.add('   -->'+fullid+ ' is free from its job on '+convertsquare(destsquare1^.x, destsquare1^.y));
end;


function TPiece.GetIndexParamAbstractRoles(square: Tsquare): integer;
var t: integer; role: ^TParamAbstractRole; endsquare: ^tsquare; traj:tlist;
begin
     result:=-13;    {we're assuming that THERE is a trajectory... if there is none, bugs follow...}
     new (role);
     role^:= tparamabstractrole.Create;
     for t:= 0 to abstractroles.count-1 do
     begin
          role^:= abstractroles.Items[t];
          traj:=role.Trajectory;
          endsquare:= traj.Items[traj.count-1];
          if (square.x=endsquare^.x) and (square.y=endsquare^.y) then
          begin
               result:=t;
          end;
     end;
end;

function TPiece.IsDefending(square: Tsquare): boolean;
begin
     RESULT:= (GETINDEXPARAMABSTRACTROLES(SQUARE)>=0);
end;

Procedure TPiece.ComputeMobility;
var x,y,count1:integer;
begin
     count1:=0;
     for x:=1 to 8 do
         for y:= 1 to 8 do
         begin
              if (mobility[x,y].distance<>10000) and (mobility[x,y].distance>0) then
              begin
                   count1:=count1+1;
              end;
         end;
     UnsafeMobility:=Count1;
end;


function TPiece.FullId:string;
var s:string;
begin
     if white then
        s:= 'White ' else s:='Black ';
     s:=s+piecename+' at '+convertsquare(sq.x,sq.y);
     Fullname:=s;
     result:=s;
end;


{=========================================================================}
function TQueen.getnextmoves(P:Tsquare):Tlist;
var Moves:Tlist; Move:^tsquare; t:integer;
    x,y,deltax,deltay:integer;
begin
     Moves:=Tlist.create;
     x:= P.x; y:= p.y;

     {down-right}
     deltax:=1; deltay:=1;
     t:=1; {unbounded:=true;}
     while (x+deltax*t<9) and (y+deltay*t<9) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {up-right}
     deltax:=1; deltay:=-1;
     t:=1;
     while (x+deltax*t<9) and (y+deltay*t>0) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {down-left}
     deltax:=-1; deltay:=1;
     t:=1;
     while (x+deltax*t>0) and (y+deltay*t<9) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {up-Left}
     deltax:=-1; deltay:=-1;
     t:=1;
     while (x+deltax*t>0) and (y+deltay*t>0) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {down}
     deltax:=0; deltay:=1;
     t:=1; {unbounded:=true;}
     while (y+deltay*t<9) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {up}
     deltax:=0; deltay:=-1;
     t:=1;
     while (y+deltay*t>0) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {left}
     deltax:=-1; deltay:=0;
     t:=1;
     while (x+deltax*t>0) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {Right}
     deltax:=1; deltay:=0;
     t:=1;
     while (x+deltax*t<9) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     result:=moves;
end;

function TQueen.GetThreathenedSquares(P:Tsquare):Tlist;
begin
     result:=Getnextmoves(p);
end;


{============================================================================}
function Tknight.GetThreathenedSquares(P:Tsquare):Tlist;
begin
     result:=Getnextmoves(p);
end;

function Tknight.getnextmoves(P:Tsquare):Tlist;
var Moves:Tlist; Move:^tsquare; t1, t2, x1, y1:integer;
begin
     Moves:=Tlist.create;

     for t1:=-2 to 2 do
         for t2:= -2 to 2 do
             if ((t1<>0)and(t2<>0) and ((t1*t1)<>(t2*t2))) then
             begin
                  x1:=P.x+t1;
                  y1:=P.y+t2;
                  if (y1>0) and (y1<9) and (x1>0) and (x1<9)then
                  begin
                       new(move);
                       Move^.x:=x1;
                       Move^.y:=y1;
                       Moves.Add(move);
                  end;
         end;
     result:=Moves;
end;


{=========================================================================}
function TPawn.getnextmoves(P:Tsquare):Tlist;
var Moves:Tlist; Move:^tsquare; t,ty:integer;
begin
     Moves:=Tlist.create;
     if (white) then
     begin
          if (P.y>1) then
          begin
               t:=p.x;
               ty:=p.y-1;

               if (externalmemory.square[P.x,ty]=none) then
               begin
                    new(move);
                    Move^.x:=t;
                    MOve^.y:=ty;
                    Moves.add(Move);
               end;
               t:=p.x-1;
               while (t<=p.x+1) do
               begin
                   if (t>0) and (t<9) then
                   begin
                      if (externalmemory.square[t,ty]<>none) and (externalmemory.white[t,ty]=false) then
                      begin
                           new(move);
                           Move^.x:=t;
                           MOve^.y:=ty;
                           Moves.add(Move);
                      end;
                   end;
                   t:=t+2;
               end;
          end;
     end
     else
     begin
          if (P.y<8) then
          begin
               t:=p.x;
               ty:=p.y+1;

               if (externalmemory.square[P.x,ty]=none) then
               begin
                    new(move);
                    Move^.x:=t;
                    MOve^.y:=ty;
                    Moves.add(Move);
               end;

               t:=p.x-1;
               while (t<=p.x+1) do
               begin
                   if (t>0) and (t<9) then
                   begin
                      if (externalmemory.square[t,ty]<>none) and (externalmemory.white[t,ty]=true) then
                      begin
                           new(move);
                           Move^.x:=t;
                           MOve^.y:=ty;
                           Moves.add(Move);
                      end;
                   end;
                   t:=t+2;
               end;
          end;
     end;
     result:=Moves;
end;


{=========================================================================}
function TBishop.getnextmoves(P:Tsquare):Tlist;
var Moves:Tlist; Move:^tsquare; t:integer;
    x,y,deltax,deltay:integer;
begin
     Moves:=Tlist.create;
     x:= P.x; y:= p.y;

     {down-right}
     deltax:=1; deltay:=1;
     t:=1; {unbounded:=true;}
     while (x+deltax*t<9) and (y+deltay*t<9) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {up-right}
     deltax:=1; deltay:=-1;
     t:=1;
     while (x+deltax*t<9) and (y+deltay*t>0) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {down-left}
     deltax:=-1; deltay:=1;
     t:=1;
     while (x+deltax*t>0) and (y+deltay*t<9) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {up-Left}
     deltax:=-1; deltay:=-1;
     t:=1;
     while (x+deltax*t>0) and (y+deltay*t>0) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     result:=moves;
end;

function TBishop.GetThreathenedSquares(P:Tsquare):Tlist;
begin
     result:=Getnextmoves(p);
end;


{===========================================================================}
function TRook.getnextmoves(P:Tsquare):Tlist;
var Moves:Tlist; Move:^tsquare; t:integer;
    x,y,deltax,deltay:integer;
begin
     Moves:=Tlist.create;
     x:= P.x; y:= p.y;

     {down}
     deltax:=0; deltay:=1;
     t:=1; {unbounded:=true;}
     while (y+deltay*t<9) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {up}
     deltax:=0; deltay:=-1;
     t:=1;
     while (y+deltay*t>0) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {left}
     deltax:=-1; deltay:=0;
     t:=1;
     while (x+deltax*t>0) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     {Right}
     deltax:=1; deltay:=0;
     t:=1;
     while (x+deltax*t<9) do
     begin
          new(move);
          Move^.x:=x+deltax*t;
          MOve^.y:=y+deltay*t;
          Moves.add(Move);
          if (externalMemory.square[x+deltax*t,y+deltay*t]<>none) then break;
          t:=t+1;
     end;
     result:=moves;
end;


function TRook.GetThreathenedSquares(P:Tsquare):Tlist;
begin
     result:=Getnextmoves(p);
end;


{===========================================================================}


function TKing.getnextmoves(P:Tsquare):Tlist;
var Moves:Tlist; x1,y1,t1,t2:integer;    Move:^tsquare;
begin
     Moves:=Tlist.create;
     for t1:=-1 to 1 do
         for t2:= -1 to 1 do
             if (not ((t1=0) and (t2=0))) then
             begin
                  x1:=P.x+t1;
                  y1:=P.y+t2;
                  if (y1>0) and (y1<9) and (x1>0) and (x1<9)then
                  begin
                       new(move);
                       Move^.x:=x1;
                       Move^.y:=y1;
                       Moves.Add(move);
                  end;
             end;
     result:=Moves;
end;

function TPawn.GetThreathenedSquares(P:Tsquare):Tlist;
var Moves:Tlist; Move:^tsquare; t,ty:integer;
begin
     Moves:=Tlist.create; {incluir um dia threathens adicionais com movimento de 'capture en passant'}
     if (white) then
     begin
          if (P.y>1) then
          begin
               ty:=p.y-1;

               t:=p.x-1;
               while (t<=p.x+1) do
               begin
                   if (t>0) and (t<9) then
                   begin
                        new(move);
                        Move^.x:=t;
                        MOve^.y:=ty;
                        Moves.add(Move);
                   end;
                   t:=t+2;
               end;
          end;
     end
     else
     begin
          if (P.y<8) then
          begin
               ty:=p.y+1;

               t:=p.x-1;
               while (t<=p.x+1) do
               begin
                   if (t>0) and (t<9) then
                   begin
                        new(move);
                        Move^.x:=t;
                        MOve^.y:=ty;
                        Moves.add(Move);
                   end;
                   t:=t+2;
               end;
          end;
     end;
     result:=Moves;
end;

function TKing.GetThreathenedSquares(P:Tsquare):Tlist;
begin
     result:=GetNextMoves(p);
end;

constructor TExternalMemory.create;
var x,y:integer;
begin
     for x:= 1 to 8 do  {initializes with an empty board}
         for y:= 1 to 8 do
         begin
              square[x,y]:=None;
              found[x,y]:=false;
              flood[x,y]:=-1;
         end;
end;
constructor TExternalmemorypiece.create (P: Tsquare; W:Boolean; Tp:TPieceType);
begin
     tpiece.create (P,W,tp );
     square[P.x,p.y]:=Tp;
end;


Constructor TexternalPiece.create(P: Tsquare; W:Boolean; Tp:TPieceType);
begin
     inherited;

     Externalmemory.square[p.x,p.y]:=tp;
     Externalmemory.white[p.x,p.y]:=W;
end;

Constructor TPiece.create;
begin
end;


procedure tKing.load_data;
begin
     if white then Piecebitmap.LoadFromFile('White_King.bmp')
     else PieceBitmap.LoadFromFile('Black_King.bmp');
     DynamicValue:=KingValue;
     PieceName:= 'King';
end;

Procedure TQueen.Load_data;
begin
     if white then Piecebitmap.LoadFromFile('White_Queen.bmp')
     else PieceBitmap.LoadFromFile('Black_Queen.bmp');
     DynamicValue:=QueenValue;
     PieceName:= 'Queen';
end;

Procedure TKnight.Load_Data;
begin
     if white then Piecebitmap.LoadFromFile('White_Knight.bmp')
     else PieceBitmap.LoadFromFile('Black_Knight.bmp');
     PieceName:= 'Knight';
     DynamicValue:=8;
end;

Procedure TBishop.Load_Data;
begin
     if white then Piecebitmap.LoadFromFile('White_Bishop.bmp')
     else PieceBitmap.LoadFromFile('Black_Bishop.bmp');
     DynamicValue:=12;
     PieceName:= 'Bishop';
end;

Procedure TRook.Load_data;
begin
     if white then Piecebitmap.LoadFromFile('White_Rook.bmp')
     else PieceBitmap.LoadFromFile('Black_Rook.bmp');
     DynamicValue:=12;
     Piecename:='Rook';
end;

Procedure TPawn.Load_Data;
begin
     if white then Piecebitmap.LoadFromFile('White_Pawn.bmp')
     else PieceBitmap.LoadFromFile('Black_Pawn.bmp');
     DynamicValue:=1;
     Piecename:='Pawn';
end;


Constructor TPiece.create (P: Tsquare; W:Boolean; Tp:TPieceType);
var x,y:integer;
begin
     sq:=P;
     new (pposition);
     pposition^:=sq; {Refactor}
     White:=w;
     PieceType:=Tp;
     PieceBitmap:=TBitmap.create;
     Load_data;

     for x:= 1 to 8 do
         for y:= 1 to 8 do
         begin
              Mobility[x,y].distance:=10000;
              Mobility[x,y].Blockedness:=0;
              Mobility[x,y].Previous.x:=10000;
              Mobility[x,y].Previous.y:=10000;
         end;

     AbstractRoles:=Tlist.create;
end;


Procedure TPiece.Display (Canvas:Tcanvas);
var x,y: integer; Color:Tcolor;
begin
     Canvas.Pen.Color:=clblack;

     x:=50*(sq.X-1)+7;
     y:=50*(sq.y-1)+7;

     Canvas.Draw(x,y,PieceBitmap);
     {floodfill here!}
     if ((sq.x+sq.y) mod 2)=1 then Color:= clDkGray else color:= clltGray;
     Canvas.Brush.Color:=color;
     Canvas.FloodFill(x+1,y+1,clwhite,fsSurface);
end;


Procedure TPiece.Display2 (Canvas:Tcanvas);
var x,y: integer; Color:Tcolor;
begin
     Canvas.Pen.Color:=clblack;

     x:=50*(sq.X-1)+7;
     y:=50*(sq.y-1)+7;
     Canvas.Copymode:=cmSrcAnd;
     Canvas.Draw(x,y,PieceBitmap);
     if ((sq.x+sq.y) mod 2)=1 then Color:= clDkGray else color:= clltGray;
     Canvas.Brush.Color:=color;
end;

Destructor TPiece.destroy;
begin
     PieceBitmap.free;
end;


end.


