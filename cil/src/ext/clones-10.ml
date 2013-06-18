(* Analysis to determine security holes in device drivers including: 
 * Priority inversion
 * DMA
 * Buffer overflow
 * Format string
 * Wear out of system (read/write/mem alloc)
 * Livelocks (waiting in a loop, timer/sleep functions)
 * Memory corruption (array, pointer) 
 *
 * transfer_buffer/schedule are tainted variables
 * 
 * The focus is primarily on drivers of devices that can be connect
 * to a standalone PC or mobile device including ports
 * USB, firewire, serial, parallel, video, dvi etc.  
 *
 * Taint is propogated via return values and procedure arguments (one level of depth)
 *
 *
 * 
*)
open Cil
open Str
open Pretty
open Ptranal
open Callgraph
  

let zero64 = (Int64.of_int 0);;
let zero64Uexp = Const(CInt64(zero64,IUInt,None));;

let gen_line_nos: int = 1;;
let gen_call_info: int = 1;;
let gen_graph_info: int = 0;;

let color: string list =
  [ "red";
    "blue";
    "yellow";
    "green";
    "orange";

  ];;


(* Auxilary helper functions  *)
 (* Printing the name of an lval *)
 let lval_tostring (lv: lval) : string = (Pretty.sprint 100 (d_lval() lv))




(* Converts a typ to a string *)
 let typ_to_string (t: typ) : string =
   begin
     (Pretty.sprint 100 (d_type() t));
   end

(* Converts an instr to a string *)
 let instr_to_string (i: instr) : string =
   begin
     (Pretty.sprint 100 (d_instr() i));
   end

(* Converts an lval to a string *)
 let lval_to_string (lv: lval) : string =
   begin
     (Pretty.sprint 100 (d_lval() lv))
   end

(* Create an expression from an Lval *)
 let expify_lval (l: lval) : exp = Lval(l)

(* Create an expression from a fundec using the variable name *)
 let expify_fundec (g: fundec) : exp = Lval(Var(g.svar),NoOffset)



(* Converts an exp to a string *)
 let exp_to_string (e: exp) : string =
   begin
     (Pretty.sprint 100 (d_exp() e))
   end

(* Converts an offset to a string. *)
let offset_to_string (o: offset) : string =
 begin
        match o with
        | Index(exp,_) -> (exp_to_string exp);
        | NoOffset -> "NoOffset";
        | Field(_,_) -> "Field Offset";
 end


   
(* Converts a statement to a string. *)
 let stmt_to_string (stmt: stmt) : string =
   Pretty.sprint 100 (d_stmt () stmt);;

(* Converts a stmt list to a string.  *)
 let stmt_list_to_string (stmt_list : stmt list) : string =
   let combiner (string : string) (stmt : stmt) =
     match string with
       | "" -> stmt_to_string stmt
       | _ -> string ^ "\n" ^ (stmt_to_string stmt)
   in
     List.fold_left combiner "" stmt_list;;

 (* Converts an exp list to a string.  *)
  let exp_list_to_string (exp_list : exp list) : string =
    let combiner (string : string) (exp : exp) =
      match string with
        | "" -> exp_to_string exp
        | _ -> string ^ "\n" ^ (exp_to_string exp)
      in
        List.fold_left combiner "" exp_list;;

 

(* list_append: Append an element to a list *)
  let list_append (lst : 'a list) (elt: 'a) : 'a list =
  begin
    (List.append lst [elt]);
  end

(* list_rev_append: Append an element to start of a list *)
  let list_rev_append (fst : 'a list) (elt: 'a) : 'a list =
   begin
     (List.rev_append fst [elt]);
   end
                        

let fn_start_end : (string, int) Hashtbl.t = (Hashtbl.create 200);;

let stmt_cluster : (int, int) Hashtbl.t = (Hashtbl.create 100);;

(* Convert varinfo to lval *)
let lvalify_varinfo (v: varinfo) : lval = (Var(v),NoOffset)   

(*********Auxilary helper functions end ***********)
(* The initial visitor for preprocessing. Fills the dirrty and contaminated hash
 * table in this pre-scan step. *)
class initialVisitor = object (self) 
    inherit nopCilVisitor

 val mutable curr_func : fundec = emptyFunction "temp"; 
 val mutable block_count = ref 0;
(* Temporary list on a per-function basis to check variables that point to bad
 * functions.
 *)
 (* Finds all the call lvals (variables) in a CIL instruction. *)
   method find_lvals_instr (i: instr) : lval list =
   begin
    match i with
        | Call(lval_option,exp, exp_list,  _) ->
          begin
            match lval_option with
            | Some (lval) -> lval :: [];
            | _   -> [];
          end
        | Set (lval, exp, _) ->
                lval::[];
        | _ -> [];
   end

   method find_lvals_exp (e: exp) : lval list =
   begin
    (match e with
        | Const(c) ->
                []; (* Constant *)
        | Lval(l) -> (* Lvalue *)
                l::[];
        | SizeOf(s) ->
            []; (* SizeOf(type) *)
        | SizeOfE(e) ->
            (* (self#analyze_exp e);  (* SizeOf(expression) *) *)
             [];
        | SizeOfStr(s) ->
            []; (* SizeOfStr, as in sizeof ("strlit") *)
        | AlignOf(t) ->
            []; (* Corresponds to the GCC __alignof__ *)
        | AlignOfE(e) ->
            (* (self#analyze_exp e);*)
             [];
        | UnOp(op, e, t) ->          
                (self#find_lvals_exp e); (* Unary operator, includes type of
                result *)
        | BinOp(b, e1, e2, t) ->
            (* Binary operator, includes type of result *)
            (List.append (self#find_lvals_exp e1) (self#find_lvals_exp e2));
        | CastE(t, e) ->
            (self#find_lvals_exp e); (* Cast *)
        | AddrOf(l) ->
            l::[]; (* Address of (lval) *)
         | StartOf(l) ->
            l::[]; (* Conversion from array to a pointer to the beginning of the
            array *)
        );
   end        

  (* Visits every "instruction" *)
  method vinst (i: instr) : instr list visitAction =
    begin
      DoChildren;
    end

  (* Visits every "statement" *)
  method vstmt (s: stmt) : stmt visitAction =
    begin
      DoChildren;
    end

  method vblock (b: block) : block visitAction =
    begin
      block_count := !block_count + 1;
      DoChildren;
    end

     (* Visits every function *)
     method vfunc (f: fundec) : fundec visitAction =
     begin
        (* curr_func <- f; Store the value of current func before getting into
                        deeper visitor analysis. *)

        DoChildren;
     end

     method top_level (f:file) :unit =
     begin
     (* Start the visiting *)
     visitCilFileSameGlobals (self :> cilVisitor) f;
     end
end


(* The second pass of the driver security code pass *)
class driverVisitor = object (self) (* self is equivalent to this in Java/C++ *)
    inherit nopCilVisitor  
    val mutable last_fun_stmt = ref 0;
    val mutable first_fun_stmt = ref 0;
    val mutable fn_data = ref "";
    val mutable x_data = ref "";
    val mutable graph_data = ref "";    
    val mutable graph_fndata = ref "";     
    val mutable file_hdr = ref "";             
    val mutable y_data = ref "";   
    val mutable cnt = ref 0;                      
  val mutable curr_func : fundec = emptyFunction "temp";                      
 (* Finds all the call lvals (variables) in a CIL instruction. *)
   method find_lvals_instr (i: instr) : lval list =
   begin
    match i with
        | Call(lval_option,exp, exp_list,  _) ->
          begin
            match lval_option with
            | Some (lval) -> lval :: [];
            | _   -> [];
          end
        | Set (lval, exp, _) ->
                lval::[];
        | _ -> [];
   end

   (* Finds all the lvals (string) in the a CIL expression (hopefully). 
   *  Do we need to add Const here ?? FIXME 
   *  *)
   method find_lvals_exp (e:exp ) : string list = 
   begin
     match e with 
       | Lval(lh,_)  ->  
               (match lh with
               | Var (vinfo) ->
                       vinfo.vname ::[];
               | Mem(ex) -> self#find_lvals_exp ex;
               );
       | AddrOf(lv_inner) ->
               let (lh, _) = lv_inner in
               (match lh with
               | Var (vinfo)-> 
                    vinfo.vname :: [];
               | Mem(ex) -> self#find_lvals_exp ex;              
               );
        | BinOp (b, e1, e2, typ) ->
                (self#find_lvals_exp e1)@(self#find_lvals_exp e2);
        | UnOp (op, e, typ) ->
                (self#find_lvals_exp e);
        | CastE (typ, e) ->
                (self#find_lvals_exp e);
        | SizeOfE (e) ->
                (self#find_lvals_exp e); 
        | AlignOfE(e) ->
                (self#find_lvals_exp e);
   
       | _ -> [];
   end
     

 (* Finds all the lvals (string) in a CIL expression (hopefully). 
   * Also return lvals found in offset of lval in expression.
   *  *)
   method find_lvals_exp_with_offset (e:exp ) : string list =
   begin
     match e with
       | Lval(lh,o)  ->
               (match lh with
               | Var (vinfo) ->
                       vinfo.vname ::(self#find_lvals_offset o);
               | Mem(ex) -> (self#find_lvals_offset o);
               );
       | AddrOf(lv_inner) -> 
               let (lh, o) = lv_inner in
               (match lh with
               | Var (vinfo)->
                    vinfo.vname :: (self#find_lvals_offset o);
               | Mem(ex) -> (self#find_lvals_offset o);
               );
        | BinOp (b, e1, e2, typ) -> (
                 let str_list = ref [] in
                 str_list := (self#find_lvals_exp e1)@(self#find_lvals_exp e2);  
		!str_list;	
		);
        | UnOp (op, e, typ) ->
                (self#find_lvals_exp e);
        | CastE (typ, e) ->
                (self#find_lvals_exp e);
        | SizeOfE (e) ->
                (self#find_lvals_exp e);
        | AlignOfE(e) ->
                (self#find_lvals_exp e);
	| StartOf(lv_inner) ->
               let (lh, o) = lv_inner in
               (match lh with
               | Var (vinfo)->
                    vinfo.vname :: (self#find_lvals_offset o);
               | Mem(ex) -> (self#find_lvals_offset o);
               );
        | _ -> [];
   end

  (* Finds all lvals (string) in an offset. *)
  method find_lvals_offset (o: offset) : string list =
  begin
      match o with
      | Index(e,o2) -> (self#find_lvals_exp_with_offset e) @ (self#find_lvals_offset o2);
      | _ -> [];
  end
 

  method printfndata (b: int) (c:int):unit = 
    begin
      if (b > 0) then
        fn_data := !fn_data^Printf.sprintf "%d %d " b c; 
    end

  method genxdata (b: int) (c:int):unit = 
    begin
      if (b > 0) then
        x_data := !x_data^Printf.sprintf " %d," b; 
    end

  method genydata (b: int) (c:int):unit = 
    begin
      if (b > 0) then
        y_data := !y_data^Printf.sprintf " %d," c; 
    end

  method gengraphdata (b:int) (c:int) :unit =
    begin
      if (b >0) then
      graph_data := !graph_data^Printf.sprintf "(%d, %d) \n" b c;
    end
      

      
   (*Visits every instruction -> Second pass *)
   method vinst (ins: instr) : instr list visitAction =
   begin
     DoChildren;
   end

   (* Visits every "statement" ( Last Pass) *)
   method vstmt (s: stmt) : stmt visitAction =
   begin
     let cur_l = ref 0 in
     cur_l := !currentLoc.line;
     match s.skind with 
       | Instr(ilist) -> ( (* Hashtbl.add stmt_cluster !cur_l 1; *)
                           for j = 0 to (List.length ilist) - 1 do
                             let cur_instr = (List.nth ilist j) in
                               match cur_instr with   
                                    | Call(lvalue_option,e,el,loc) -> (Hashtbl.add stmt_cluster loc.line 10;);
                                    | Set (lv, ex, loc) ->(Hashtbl.add stmt_cluster loc.line 1;);
                                    |_ -> ();
                                                                      
                           done; 

                       DoChildren;);
       | Return(_, loc) -> (Hashtbl.add stmt_cluster !cur_l 60; Hashtbl.add stmt_cluster !cur_l 60; Hashtbl.add stmt_cluster !cur_l 60;   DoChildren;);
       | Goto (_, loc) -> Hashtbl.add stmt_cluster !cur_l 50; DoChildren;
       | Break (loc) -> Hashtbl.add stmt_cluster !cur_l 40; DoChildren;
       | Continue (loc) -> Hashtbl.add stmt_cluster !cur_l 70; DoChildren;
       | If (_, _, _, loc) -> Hashtbl.add stmt_cluster !cur_l 80; DoChildren;
       | Switch (_, _, _, loc) -> Hashtbl.add stmt_cluster !cur_l 100 ; DoChildren;
       | Loop (_,loc, _, _) -> Hashtbl.add stmt_cluster !cur_l 40; DoChildren;
       | Block (_) -> (Hashtbl.add stmt_cluster !cur_l 5; Hashtbl.add stmt_cluster !cur_l 5;   DoChildren;);
       | TryFinally (_, _, loc) -> Hashtbl.add stmt_cluster !cur_l 110; DoChildren;
       | TryExcept (_, _, _, loc) -> Hashtbl.add stmt_cluster  !cur_l 120; DoChildren;                   
       | _ ->DoChildren; 

   end

   (* Visits every block  Pass 2*)
   method vblock (b: block) : block visitAction =
   begin
      DoChildren;
   end


     

   method genfunc  : unit =
   begin

     Hashtbl.iter self#printfndata stmt_cluster;

     Hashtbl.iter self#genxdata stmt_cluster;
     Hashtbl.iter self#genydata stmt_cluster;
     Hashtbl.iter self#gengraphdata stmt_cluster;

     (* Printf.fprintf stderr "x_len is %d.\n" (String.length !x_data) ; *)


     (* Remove trailing commas *)
     
     let x_len = (String.length !x_data) in
       if (x_len  > 0) then 
                !x_data. [x_len - 1] <- ' ';


     let y_len = (String.length !y_data) in
       if (y_len  > 0) then 
                !y_data. [y_len - 1] <- ' ';

       
     
     Printf.fprintf stderr "fn %s %s \n"curr_func.svar.vname !fn_data;

     Printf.fprintf stderr "%s = [%s ; %s]; \n"curr_func.svar.vname !x_data !y_data;


     let match_regexp = regexp (".*"^"xmit"^".*") in
     (*  if (Str.string_match match_regexp curr_func.svar.vname 0) = true then
      *  *)
     
     if (String.length !x_data > 50) then  
     Printf.printf "%s = [%s ; %s]; \n"curr_func.svar.vname !x_data !y_data;

      if (gen_graph_info = 1) then (
        let match_regexp = regexp (".*"^"xmit"^".*") in
        if (Str.string_match match_regexp curr_func.svar.vname 0) = true then ( 
        (* if (String.compare !graph_data "" != 0)&& (String.length !graph_data
         * > 500)  then (          *) 

          Printf.fprintf stderr "\n %s }; \n" !graph_data;
          Printf.printf "\n %s };\n"  !graph_data;
          graph_fndata := !graph_fndata^Printf.sprintf"$%s$," curr_func.svar.vname;
        );
     );
     Hashtbl.clear stmt_cluster;

     fn_data := "";
     x_data := "";
     y_data := "";
     graph_data := Printf.sprintf "\\addplot[const plot, fill=%s,opacity=0.8,mark=square*,thick] coordinates {\n" (List.nth color (!cnt mod 5));
        
     
   end


  (* Visits every function  Pass 2*)
  method vfunc (f: fundec) : fundec visitAction =
    begin
      (* Build CFG for every function.*)
      (Cil.prepareCFG f);
      (Cil.computeCFGInfo f false);  (* false = per-function stmt numbering,
                                      true = global stmt numbering *)


      self#genfunc; 
      cnt := !cnt + 1;
      curr_func <- f;
      DoChildren;
    end
    
    method top_level (f:file) :unit =
      begin

        (* Do some points-to analysis  No idea wat this does*)
        Ptranal.no_sub := false;
        Ptranal.analyze_mono := true;
        Ptranal.smart_aliases := false;
        Ptranal.analyze_file f; (* Performs actual points-to analysis *)
        Ptranal.compute_results false; (* Just prints the  points-to-graph to screen *)
       
        
        (* Start the visiting *)
        visitCilFileSameGlobals (self :> cilVisitor) f; 

          self#genfunc;
        if (gen_graph_info = 1) then (      
          let gf_len = (String.length !graph_fndata) in
            if (gf_len  > 0) then
              !graph_fndata. [gf_len - 1] <- ' ';

            Printf.printf "\n \\legend {%s} \n \\end{axis}  \\end{tikzpicture} \n" !graph_fndata; 
            Printf.fprintf stderr "\n \\legend {%s} \n \\end{axis} \\end{tikzpicture}\n" !graph_fndata;
        );

    end 
end    
    

(*******************************
* Init
********************************)

(*Toplevel function for our Beefy Analysis *)
let docloneanalysis (f:file)  : unit = 	
  begin
      (* Printf.printf "#### Execution time: %f\n" (Sys.time()));
      *)
    
     if (gen_graph_info = 1) then ( 
        Printf.printf "\n \\begin{tikzpicture} \\begin{axis}[width=450pt, height=350pt, ylabel={Code Type},xlabel={Line numbers}, legend columns=2] \n \pgfplotsset{every axis legend/.append style={ \n at={(0,1)}, pos=outer, font=\\small}} ";
        Printf.fprintf stderr "\n \\begin{tikzpicture} \\begin{axis}[width=450pt, height=300pt, ylabel={Code Type},xlabel={Line numbers}, legend columns=2] \n \pgfplotsset{every axis legend/.append style={ \n at={(0,1)}, pos=outer, font=\\small}} ";
        );
        
      let initVisitor : initialVisitor = new initialVisitor in
      initVisitor#top_level f;
     
     
      let driVisitor : driverVisitor = new driverVisitor in
      driVisitor#top_level f;
    
  end

(* The feature description for the drivers module *)  
let feature : featureDescr = 
  { fd_name = "clones";              
    fd_enabled = ref false;
    fd_description = "Device Driver Clone Analysis";
    fd_extraopt = [];
    fd_doit = docloneanalysis;
    fd_post_check = true      (*What does this do?? *) 
  } 

  
