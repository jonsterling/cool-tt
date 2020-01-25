type 'a cof = 
  | Eq of 'a * 'a
  | Join of 'a cof * 'a cof
  | Meet of 'a cof * 'a cof

type ('a, 'b) tree =
  | Const of 'a cof * 'b
  | Split of ('a, 'b) tree * ('a, 'b) tree


let eq x y = Eq (x, y)
let join phi psi = Join (phi, psi)
let meet phi psi = Meet (phi, psi)  


let const psi x = Const (psi, x)
let split t0 t1 = Split (t0, t1)


let rec condition : ('a, 'b) tree -> 'a cof =
  function
  | Const (psi, _) -> 
    psi
  | Split (t0, t1) ->
    Meet (condition t0, condition t1)



(* TODO: make the output more beautiful *)
let rec pp_cof pp env fmt =
  function
  | Eq (x, y) -> 
    Format.fprintf fmt "%a = %a"
      (pp env) x
      (pp env) y
  | Join (phi, psi) ->
    Format.fprintf fmt "(%a) \\/ (%a)"
      (pp_cof pp env) phi
      (pp_cof pp env) psi
  | Meet (phi, psi) ->
    Format.fprintf fmt "(%a) /\\ (%a)"
      (pp_cof pp env) phi
      (pp_cof pp env) psi


let pp_tree ppa ppb env fmt = 
  function
  | _ ->
    Format.fprintf fmt "TODO: pp_tree"