{
open Misc
open Lexing
open Table
open Lexstate
open Subst

let header = "$Id: tabular.mll,v 1.18 1999-10-01 16:15:34 maranget Exp $"

exception Error of string
;;

type align =
    {hor : string ; mutable vert : string ; wrap : bool ;
      mutable pre : string ; mutable post : string ; width : Length.t}

let make_hor = function
    'c' -> "center"
  | 'l' -> "left"
  | 'r' -> "right"
  | 'p'|'m'|'b' -> "left"
  | _ -> raise (Misc.Fatal "make_hor")

and make_vert = function
  | 'c'|'l'|'r' -> ""
  | 'p' -> "top"
  | 'm' -> "middle"
  | 'b' -> "bottom"
  | _ -> raise (Misc.Fatal "make_vert")

type format =
  Align of align
| Inside of string
| Border of string
;;

let check_vert f =
  try
    for i = 0 to Array.length f-1 do
      match f.(i) with
      | Align {vert=s} when s <> "" -> raise Exit
      | _ -> ()
    done ;
    f
  with Exit -> begin
    for i = 0 to Array.length f-1 do
      match f.(i) with
      | Align ({vert=""} as f) ->
          f.vert <- "top"
      | _ -> ()
    done ;
    f
  end


let border = ref false



let push s e = s := e:: !s
and pop s = match !s with
  [] -> raise (Misc.Fatal "Empty stack in Latexscan")
| e::rs -> s := rs ; e

let out_table = Table.create (Inside "")

let pretty_format = function
  |   Align {vert = v ; hor = h ; pre = pre ; post = post ; wrap = b ; width = w}
      ->
        ">{"^pre^"}"^
        "h="^h^" v="^v^
        "<{"^post^"}"^(if b then " wrap" else "")^
        "w="^Length.pretty w
  | Inside s -> "@{"^s^"}"
  | Border s -> s

let pretty_formats f =
  Array.iter (fun f -> prerr_string (pretty_format f) ; prerr_char ',') f


} 

rule tfone = parse
  '>'
    {let pre = subst_arg lexbuf in
    tfmiddle lexbuf ;
    try
      apply out_table (function
        |  Align a as r -> a.pre <- pre
        | _ -> raise (Error "Bad syntax in array argument (>)"))
    with Failure "Table.apply" ->
      raise (Error "Bad syntax in array argument (>)")}
| "" {tfmiddle lexbuf}

and tfmiddle = parse
  'c'|'l'|'r'
  {let f = Lexing.lexeme_char lexbuf 0 in
  let post = tfpostlude lexbuf in
  emit out_table
    (Align {hor = make_hor f ; vert = make_vert f ; wrap = false ;
        pre = "" ;   post = post ; width = Length.Default})}
| 'p'|'m'|'b'
  {let f = Lexing.lexeme_char lexbuf 0 in
  let width = subst_arg lexbuf in
  let my_width = Length.main (Lexing.from_string width) in
  let post = tfpostlude lexbuf in
  emit out_table
    (Align {hor = make_hor f ; vert = make_vert f ; wrap = true ;
          pre = "" ;   post = post ; width = my_width})}
| '#' ['1'-'9']
    {let lxm = lexeme lexbuf in
    let i = Char.code (lxm.[1]) - Char.code '1' in
    Lexstate.scan_arg (scan_this tfmiddle) i}

| ['a'-'z''A'-'Z']
    {let lxm = lexeme lexbuf in
    let name = column_to_command lxm in
    let pat,body = Latexmacros.find_macro name in
    let args = Lexstate.make_stack name pat lexbuf in
    Lexstate.scan_body
      (function
        | Lexstate.Subst body -> scan_this lexformat body ;            
        | _ -> assert false)
      body args ;
    let post = tfpostlude lexbuf in
    Table.apply out_table
      (function
        | Align f -> f.post <- post
        | _ -> Misc.warning ("``<'' after ``@'' in tabular arg scanning"))}
| eof {()}
| ""
  {let rest =
    String.sub lexbuf.lex_buffer lexbuf.lex_curr_pos
      (lexbuf.lex_buffer_len - lexbuf.lex_curr_pos) in
  raise (Error ("Syntax of array format near: "^rest))}

and tfpostlude = parse
  '<' {subst_arg lexbuf}
| ""  {""}


and lexformat = parse
 '*'
   {let ntimes = save_arg lexbuf in
   let what = save_arg lexbuf in
   let rec do_rec = function
     0 -> lexformat lexbuf
   | i ->
      scan_this_arg lexformat what ; do_rec (i-1) in
   do_rec (Get.get_int ntimes)}
| '|' {border := true ; emit out_table (Border "|") ; lexformat lexbuf}
| '@'|'!'
    {let lxm = Lexing.lexeme_char lexbuf 0 in
    let inside = subst_arg lexbuf in
    if lxm = '!' || inside <> "" then emit out_table (Inside inside) ;
    lexformat lexbuf}
| '#' ['1'-'9']
    {let lxm = lexeme lexbuf in
    let i = Char.code (lxm.[1]) - Char.code '1' in
    Lexstate.scan_arg (scan_this lexformat) i ;
    lexformat lexbuf}
| eof {()}
| "" {tfone lexbuf ; lexformat lexbuf}



{

let main (s,env) =
  if !verbose > 1 then prerr_endline ("Table format: "^s);
  start_normal env ;
  lexformat (Lexing.from_string s) ;
  end_normal () ;
  let r = check_vert (trim out_table) in
  if !verbose > 1 then begin
    prerr_string "Format parsed: " ;
    pretty_formats r ;
    prerr_endline ""
  end ;
  r
}

