(* create context and solver *)
module Z3Raw =
struct
  let context = Z3.mk_context []

  type result = Z3.Solver.status =
      UNSATISFIABLE | UNKNOWN | SATISFIABLE

  let copy_solver solver = Z3.Solver.translate solver context
  let check solver asserts = Z3.Solver.check solver asserts

  type symbol = Z3.Symbol.symbol
  let mk_symbol_s s = Z3.Symbol.mk_string context s
  let mk_symbol_i i = Z3.Symbol.mk_int context i

  type sort = Z3.Sort.sort
  let mk_sort_s s = Z3.Sort.mk_uninterpreted_s context s
  let mk_real () = Z3.Arithmetic.Real.mk_sort context

  type expr = Z3.Expr.expr
  let mk_const sym sort = Z3.Expr.mk_const context sym sort
  let mk_ite e1 e2 e3 = Z3.Boolean.mk_ite context e1 e2 e3
  let mk_le e1 e2 = Z3.Arithmetic.mk_le context e1 e2
  let mk_eq e1 e2 = Z3.Boolean.mk_eq context e1 e2
  let mk_real_numeral_i i = Z3.Arithmetic.Real.mk_numeral_i context i

  type quantifier = Z3.Quantifier.quantifier
  let mk_bound i sort = Z3.Quantifier.mk_bound context i sort
  let expr_of_quantifier = Z3.Quantifier.expr_of_quantifier
  let mk_forall ~sort ~symbol ~body : quantifier =
    Z3.Quantifier.mk_forall context [sort] [symbol] body None [] [] None None

  type func_decl = Z3.FuncDecl.func_decl
  let mk_func_decl ~name ~domain ~range : func_decl =
    Z3.FuncDecl.mk_func_decl context name domain range
  let apply func args = Z3.FuncDecl.apply func args
end

(* wrapper *)
module Z3Maker =
struct
  open Z3Raw

  type sort = I | F | Real [@@deriving show]
  type symbol = S of string | I of int
  type expr =
    | Bound of int * sort (* de Bruijn indexes *)
    | Var of symbol * sort
    | Ite of expr * expr * expr
    | Le of expr * expr
    | Eq of expr * expr
    | RealConst of int
    | ForallI of symbol * expr
    | Apply of symbol * expr list
  type decl =
    { name : symbol
    ; domain : sort list
    ; range : sort
    }
  let sort_store : (sort, Z3Raw.sort) Hashtbl.t = Hashtbl.create 10
  let global_symbol_store : (symbol, Z3Raw.symbol) Hashtbl.t = Hashtbl.create 100
  let expr_store : (expr, Z3Raw.expr) Hashtbl.t = Hashtbl.create 100
  let func_decl_store : (symbol, Z3Raw.func_decl) Hashtbl.t = Hashtbl.create 10

  let memoize store f x =
    match Hashtbl.find_opt store x with
    | Some x -> x
    | None -> let res = f x in Hashtbl.replace store x res; res

  let sort =
    memoize sort_store @@ function
    | I -> mk_sort_s "I"
    | F -> mk_sort_s "F"
    | Real -> mk_real ()

  let symbol =
    function
    | S str -> Z3Raw.mk_symbol_s str
    | I i -> Z3Raw.mk_symbol_i i

  let global_symbol =
    memoize global_symbol_store @@ symbol

  let func_decl {name; domain; range} =
    name |> begin
      memoize func_decl_store @@ fun name ->
      let name = symbol name in
      let domain = List.map sort domain in
      let range = sort range in
      Z3Raw.mk_func_decl ~name ~domain ~range
    end

  let func_decl_by_name sym = Hashtbl.find func_decl_store sym

  let rec expr e =
    e |> memoize expr_store @@ function
    | Bound (i, s) -> Z3Raw.mk_bound i (sort s)
    | Var (sym, s) -> Z3Raw.mk_const (global_symbol sym) (sort s)
    | Ite (e1, e2, e3) -> Z3Raw.mk_ite (expr e1) (expr e2) (expr e3)
    | Le (e1, e2) -> Z3Raw.mk_le (expr e1) (expr e2)
    | Eq (e1, e2) -> Z3Raw.mk_eq (expr e1) (expr e2)
    | RealConst i -> Z3Raw.mk_real_numeral_i i
    | ForallI (sym, body) ->
      let symbol = symbol sym in
      let sort = sort I in
      let body = expr body in
      Z3Raw.expr_of_quantifier @@ Z3Raw.mk_forall ~sort ~symbol ~body
    | Apply (sym, args) ->
      let func = func_decl_by_name sym in
      let args = List.map expr args in
      Z3Raw.apply func args
end
