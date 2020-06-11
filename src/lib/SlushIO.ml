open CoolBasis
open Bwd

module CS = ConcreteSyntax
module S = Syntax
module D = Domain

module M = Monad.Notation (Incremental)
open M
module MU = Monad.Util (Incremental)
module J = Ezjsonm

exception Todo

module BasicJSON =
struct

  let ret = Incremental.ret (* todo this can't be right ... can it? *)

  let json_of_int (i : int) : [> `String of string ] =
    `String (string_of_int i)

  let int_of_json : [> `String of string ] -> int =
    function
    | `String s -> int_of_string s
    | j -> J.parse_error j "int_of_json"

  let json_of_string = `String (* todo/iev this may need to be η-expanded for ocaml reasons *)

  let string_of_json =
    function
    | `String s -> s
    | j -> J.parse_error j "string_of_json"

  let json_of_ostring =
    function
    | None -> `Null
    | Some str -> `String str

  let ostring_of_json =
    function
    | `Null -> None
    | `String str -> Some str
    | j -> J.parse_error j "ostring_of_json"

  let json_of_list json_of_item l =
     MU.traverse json_of_item l <<@> fun l -> `A l

  let list_of_json item_of_json =
    function
    | `A l -> MU.traverse item_of_json l
    | j -> J.parse_error j "list_of_json"

  (* pure version *)
  let json_of_list_ json_of_item l =
    `A (List.map json_of_item l)

  (* pure version *)
  let list_of_json_ item_of_json =
    function
    | `A l -> List.map item_of_json l
    | j -> J.parse_error j "list_of_json_"

  let json_of_ostring_bwd nms =
    json_of_list_ json_of_ostring @@ Bwd.to_list nms

  let ostring_bwd_of_json l =
    Bwd.from_list @@ list_of_json_ ostring_of_json l

  let json_of_pair (json_of_a, json_of_b) (a, b) =
    json_of_a a >>= fun a ->
    json_of_b b >>= fun b ->
    ret @@ `A [a; b]

  let pair_of_json (a_of_json, b_of_json) =
    function
    | `A [a; b] ->
      a_of_json a >>= fun a ->
      b_of_json b >>= fun b ->
      ret @@ (a, b)
    | j -> J.parse_error j "pair_of_json"

  let json_of_labeled (json_of_a, json_of_b) (a, b) =
    json_of_b b >>= fun b ->
    ret @@ `A [json_of_a a; b]

  let labeled_of_json (a_of_json, b_of_json) =
    function
    | `A [a; b] ->
      b_of_json b >>= fun b ->
      ret @@ (a_of_json a, b)
    | j -> J.parse_error j "labeled_of_json"

  (* labeled in reverse *)
  let json_of_delebal (json_of_a, json_of_b) (a, b) =
    json_of_a a >>= fun a ->
    ret @@ `A [a; json_of_b b]

  (* labeled in reverse *)
  let delebal_of_json (a_of_json, b_of_json) =
    function
    | `A [a; b] ->
      a_of_json a >>= fun a ->
      ret @@ (a, b_of_json b)
    | j -> J.parse_error j "delebal_of_json"

end

module TmJSON =
struct
  open BasicJSON

  open SyntaxData

  let rec json_of_tm : t -> J.value m =
    function
    | Var x -> ret @@ `A [`String "Var";  json_of_int x]

    | Global sym ->
      json_of_sym sym >>= fun sym ->
      ret @@ `A [`String "Global"; sym]

    | Let (t1 , nm , t2) ->
      json_of_tm t1 >>= fun t1 ->
      json_of_name nm >>= fun nm ->
      json_of_tm t2 >>= fun t2 ->
      ret @@ `A [`String "Let"; t1; nm; t2]

    | Ann (tm, tp) ->
      json_of_tm tm >>= fun tm ->
      json_of_tp tp >>= fun tp ->
      ret @@ `A [`String "Ann"; tm; tp]

    | Zero -> ret @@ `A [`String "Zero"]
    | Suc n ->
      json_of_tm n >>= fun n ->
      ret @@ `A [`String "Suc"; n]

    | NatElim (tm1, tm2, tm3, tm4) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      json_of_tm tm3 >>= fun tm3 ->
      json_of_tm tm4 >>= fun tm4 ->
      ret @@ `A [`String "NatElim"; tm1; tm2; tm3; tm4]

    | Base -> ret @@ `A [`String "Base"]

    | Loop tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "Loop"; tm]

    | CircleElim (tm1, tm2, tm3, tm4) -> (* todo: code quality, this is a near copy of natelim *)
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      json_of_tm tm3 >>= fun tm3 ->
      json_of_tm tm4 >>= fun tm4 ->
      ret @@ `A [`String "CircleElim"; tm1; tm2; tm3; tm4]

    | Lam (nm, tm) ->
      json_of_name nm >>= fun nm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "Lam"; nm; tm]

    | Ap (tm1, tm2) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      ret @@ `A [`String "Ap"; tm1; tm2]

    | Pair (tm1, tm2) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      ret @@ `A [`String "Pair"; tm1; tm2]

    | Fst tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "Fst"; tm]

    | Snd tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "Snd"; tm]

    | GoalRet tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "GoalRet"; tm]

    | GoalProj tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "GoalProj"; tm]

    | Coe (tm1, tm2, tm3, tm4) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      json_of_tm tm3 >>= fun tm3 ->
      json_of_tm tm4 >>= fun tm4 ->
      ret @@ `A [`String "Coe"; tm1; tm2; tm3; tm4]

    | HCom (tm1, tm2, tm3, tm4, tm5) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      json_of_tm tm3 >>= fun tm3 ->
      json_of_tm tm4 >>= fun tm4 ->
      json_of_tm tm5 >>= fun tm5 ->
      ret @@ `A [`String "HCom"; tm1; tm2; tm3; tm4; tm5]

    | Com (tm1, tm2, tm3, tm4, tm5) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      json_of_tm tm3 >>= fun tm3 ->
      json_of_tm tm4 >>= fun tm4 ->
      json_of_tm tm5 >>= fun tm5 ->
      ret @@ `A [`String "Com"; tm1; tm2; tm3; tm4; tm5]

    | SubIn tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "SubIn"; tm]

    | SubOut tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "SubOut"; tm]

    | Dim0 -> raise Todo
    | Dim1 -> raise Todo
    | Cof c ->
      json_of_cof c >>= fun tm ->
      ret @@ `A [`String "Cof"; tm]

    | ForallCof tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "ForallCof"; tm]

    | CofSplit cs ->
      json_of_cof cs >>= fun cs -> (* todo: i don't understand why this type checks; it probably won't  once i write cof *)
      ret @@ `A [`String "CofSplit"; cs]

    | Prf -> ret @@ `A [`String "Prf"]

    | ElIn tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "ElIn"; tm]

    | ElOut tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "ElOut"; tm]

    | Box (tm1, tm2, tm3, tm4, tm5) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      json_of_tm tm3 >>= fun tm3 ->
      json_of_tm tm4 >>= fun tm4 ->
      json_of_tm tm5 >>= fun tm5 ->
      ret @@ `A [`String "Box"; tm1; tm2; tm3; tm4; tm5]

    | Cap (tm1, tm2, tm3, tm4, tm5) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      json_of_tm tm3 >>= fun tm3 ->
      json_of_tm tm4 >>= fun tm4 ->
      json_of_tm tm5 >>= fun tm5 ->
      ret @@ `A [`String "Cap"; tm1; tm2; tm3; tm4; tm5]

    | VIn (tm1, tm2, tm3, tm4) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      json_of_tm tm3 >>= fun tm3 ->
      json_of_tm tm4 >>= fun tm4 ->
      ret @@ `A [`String "VIn"; tm1; tm2; tm3; tm4]

    | VProj (tm1, tm2, tm3, tm4, tm5) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      json_of_tm tm3 >>= fun tm3 ->
      json_of_tm tm4 >>= fun tm4 ->
      json_of_tm tm5 >>= fun tm5 ->
      ret @@ `A [`String "VProj"; tm1; tm2; tm3; tm4; tm5]

    | CodeExt (i, tm1, glo, tm2) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_global glo >>= fun glo ->
      json_of_tm tm2 >>= fun tm2 ->
      ret @@ `A [`String "CodeExt"; json_of_int i; tm1; glo; tm2] (* todo: interesting that json of int breaks the pattern; it's out of the monad *)

    | CodePi (tm1, tm2) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      ret @@ `A [`String "CodePi"; tm1; tm2]

    | CodeSg (tm1, tm2) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      ret @@ `A [`String "CodeSg"; tm1; tm2]

    | CodeNat -> ret @@ `A [`String "CodeNat"]

    | CodeUniv -> ret @@ `A [`String "CodeUniv"]

    | CodeV (tm1, tm2, tm3, tm4) ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      json_of_tm tm3 >>= fun tm3 ->
      json_of_tm tm4 >>= fun tm4 ->
      ret @@ `A [`String "CodeV"; tm1; tm2; tm3; tm4]

    | CodeCircle -> ret @@ `A [`String "CodeCircle"]

    | ESub(s,tm) ->
      json_of_sub s >>= fun s ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "ESub"; s; tm]

  and json_of_tp : tp -> J.value m = (* todo: i am not sure if the constructor names are disjoint or if it matters *)
    function
    | Univ -> ret @@ `A [`String "Univ"]
    | El tm ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "El"; tm]

    | TpVar i -> ret @@ `A [`String "TpVar";  json_of_int i]

    | GoalTp (nm, tp) ->
      json_of_tp tp >>= fun tp ->
      ret @@ `A [`String "GoalTp"; json_of_ostring nm; tp] (* todo: ditto comment about int *)

    | TpDim -> ret @@ `A [`String "TpDim"]

    | TpCof -> ret @@ `A [`String "TpCof"]

    | TpPrf tm ->
      json_of_tm tm >>= fun tp ->
      ret @@ `A [`String "TpPrf"; tp]

    | TpCofSplit l -> raise Todo
      (* json_of_tm l >>= fun l ->
       * ret @@ `A [`String "TpCofSplit"; l] *)

    | Sub (tp, tm1, tm2) ->
      json_of_tp tp >>= fun tp ->
      json_of_tm tm1 >>= fun tm1 ->
      json_of_tm tm2 >>= fun tm2 ->
      ret @@ `A [`String "Sub"; tp; tm1; tm2]

    | Pi (tp1, nm, tp2) ->
      json_of_tp tp1 >>= fun tp1 ->
      json_of_name nm >>= fun nm ->
      json_of_tp tp2 >>= fun tp2 ->
      ret @@ `A [`String "Pi"; tp1; nm; tp2]

    | Sg (tp1, nm, tp2) ->
      json_of_tp tp1 >>= fun tp1 ->
      json_of_name nm >>= fun nm ->
      json_of_tp tp2 >>= fun tp2 ->
      ret @@ `A [`String "Sg"; tp1; nm; tp2]

    | Nat -> ret @@ `A [`String "Nat"]
    | Circle -> ret @@ `A [`String "Cicle"]
    | TpESub (sub, tp) -> raise Todo

  and json_of_sub : sub -> J.value m =
    function
    | Sb0 -> ret @@ `A [`String "Sb0"]

    | SbI -> ret @@ `A [`String "SbI"]

    | SbE (s, tm) ->
      json_of_sub s >>= fun s ->
      json_of_tm tm >>= fun tm ->
      ret @@ `A [`String "SbE"; s; tm]

    | SbP -> ret @@ `A [`String "SbP"]

    | SbC (s1, s2) ->
      json_of_sub s1 >>= fun s1 ->
      json_of_sub s2 >>= fun s2 ->
      ret @@ `A [`String "SbC"; s1; s2]


  and json_of_env : env -> J.value = fun _ -> raise Todo
  and json_of_sym = fun _ -> raise Todo
  and json_of_name = fun _ -> raise Todo
  and json_of_cof = fun _ -> raise Todo
  and json_of_global = fun _ -> raise Todo
end
