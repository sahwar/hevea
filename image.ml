(***********************************************************************)
(*                                                                     *)
(*                          HEVEA                                      *)
(*                                                                     *)
(*  Luc Maranget, projet PARA, INRIA Rocquencourt                      *)
(*                                                                     *)
(*  Copyright 1998 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(***********************************************************************)

let header = "$Id: image.ml,v 1.16 1999-10-08 17:58:01 maranget Exp $" 
open Misc

let base = Parse_opts.base_out
;;

let count = ref 0
;;

let buff = ref (Out.create_null ())
;;

let active = ref false
;;

let start () =
  active := true ;
  buff := Out.create_buff ()
;;

let stop () = active := false
and restart () = active := true

let put s = if !active then Out.put !buff s
and put_char c = if !active then Out.put_char !buff c
;;

let tmp_name = match base with
| "" -> "image.tex.new"
| _ -> base ^ ".image.tex.new"

let open_chan () =
  let chan = open_out tmp_name in
  Out.to_chan chan !buff ;
  buff := Out.create_chan chan


and close_chan () =
  Out.put !buff "\\end{document}\n" ;
  Out.close !buff
;;


let my_string_of_int n =
  let r0 = n mod 10 and q0 = n / 10 in
  let r1 = q0 mod 10 and q1 = q0 / 10 in
  let r2 = q1 mod 10 in
  string_of_int r2^string_of_int r1^string_of_int r0
;;


let page () =
  let n = !count in
  if !verbose > 0 then begin
    Location.print_pos ();
    Printf.fprintf stderr "dump image number %d" (n+1) ;
    prerr_endline ""
  end ;
  if n = 0 then open_chan () ;
  incr count ;
  base^my_string_of_int !count^".gif"
;;

let dump s_open image  lexbuf =
  Out.put !buff s_open ;
  image lexbuf
;;

let finalize () = 
  if !count > 0 then begin
    close_chan() ;
    let true_name = Filename.chop_suffix tmp_name ".new" in
    if Myfiles.changed tmp_name true_name then
      Sys.rename tmp_name true_name
    else
      Sys.remove tmp_name
  end
