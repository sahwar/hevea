(***********************************************************************)
(*                                                                     *)
(*                          HEVEA                                      *)
(*                                                                     *)
(*  Luc Maranget, projet Moscova, INRIA Rocquencourt                   *)
(*                                                                     *)
(*  Copyright 2001 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(*  $Id: util.mli,v 1.4 2001-05-25 17:23:20 maranget Exp $             *)
(***********************************************************************)

val cost : Htmltext.style Tree.t -> int * int
val costs : Htmltext.style Tree.t list -> int * int
val there : Htmltext.t_style -> Htmltext.style -> bool
val inter : Htmltext.style -> Htmltext.style -> Htmltext.style
val sub : Htmltext.style -> Htmltext.style -> Htmltext.style
val neutral : Htmltext.style -> Htmltext.style * Htmltext.style
val is_blank : 'a Tree.t -> bool
val is_blanks : 'a Tree.t list -> bool
val nodes :
  Htmltext.style -> Htmltext.style Tree.t list ->  Htmltext.style Tree.t list
val node :
  Htmltext.style -> Htmltext.style Tree.t list ->  Htmltext.style Tree.t

