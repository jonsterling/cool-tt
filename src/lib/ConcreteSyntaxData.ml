type location = (Lexing.position * Lexing.position) option

let pp_location fmt =
  function
  | None -> Format.fprintf fmt "Unknown location"
  | Some (start_pos, end_pos) ->
    let open Lexing in
    Format.fprintf fmt "%a:%i.%i-%i.%i"
      Uuseg_string.pp_utf_8 start_pos.pos_fname
      start_pos.pos_lnum
      (start_pos.pos_cnum - start_pos.pos_bol)
      end_pos.pos_lnum
      (end_pos.pos_cnum - end_pos.pos_bol)


type 'a node =
  {node : 'a;
   info : location}

[@@deriving show]


type ident = string [@@deriving show]

type binder = B of {name : ident; body : con}
and bindern = BN of {names : ident list; body : con}

and cell = Cell of {name : ident; tp : con}
and con = con_ node
and con_ =
  | Var of [`User of ident | `Level of int]
  | Let of con * binder
  | Ann of {term : con; tp : con}
  | Nat
  | Suc of con
  | Lit of int
  | Pi of cell list * con
  | Lam of bindern
  | Ap of con * con list
  | Sg of cell list * con
  | Sub of con * con * con
  | Pair of con * con
  | Fst of con
  | Snd of con
  | Univ
  | Hole of ident option
  | Underscore
  | Unfold of ident list * con
  | Elim of {mot : bindern; cases : case list; scrut : con}
  | LamElim of case list
  | Dim
  | Cof
  | CofEq of con * con
  | Join of con * con
  | Meet of con * con
  | CofBoundary of con
  | Prf of con
  | CofSplit of (con * con) list
  | Path of con * con * con
  | Coe of con * con * con * con
  | TopC
  | BotC
  | HCom of con * con * con * con * con
  | AutoHCom of con * con * con * con
  | Com of con * con * con * con * con
[@@deriving show]

and case = pat * con
[@@deriving show]

and pat = Pat of {lbl : ident; args : pat_arg list}
[@@deriving show]

and pat_arg = [`Simple of ident option | `Inductive of ident option * ident option]
[@@deriving show]

type decl =
  | Def of {name : ident; def : con; tp : con}
  | NormalizeTerm of con
  | Quit

type signature = decl list
