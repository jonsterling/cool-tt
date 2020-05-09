module D := Domain
module S := Syntax
module St := ElabState
module Splice := Splice

exception NbeFailed of string

open Monads

val quote_con : D.tp -> D.con -> S.t quote
val quote_tp : D.tp -> S.tp quote
val quote_cut : D.cut -> S.t quote
val quote_cof : D.cof -> S.t quote

val equal_con : D.tp -> D.con -> D.con -> bool quote
val equal_tp : D.tp -> D.tp -> bool quote

val equate_con : D.tp -> D.con -> D.con -> unit quote
val equate_tp : D.tp -> D.tp -> unit quote