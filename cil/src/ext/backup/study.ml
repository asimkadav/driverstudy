(* Analysis to perform device driver study: 
 *
 * 
*)
open Cil
open Str
open Pretty
open Ptranal
open Callgraph
open Device 

module IH = Inthash


let zero64 = (Int64.of_int 0);;
let zero64Uexp = Const(CInt64(zero64,IUInt,None));;

let gen_line_nos: int = 1;;
let gen_call_info: int = 1;;

let bfactor: int ref =ref 0;;
let cfactor: int ref =ref 0;;
let modparams: int ref = ref 0;;

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
(* ioctl function name and parent name *)
let ioctl_fns : (string,string) Hashtbl.t = (Hashtbl.create 15);;

let process_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* init function names and parent name *)
let init_fns : (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Error recovery functions *)
let err_fns : (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Proc related functions *)
let proc_fns : (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* module parameters *)
let modpm_fns : (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* List of cleanup functions *)
let cleanup_fns:(string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Power management functions *)
let pm_fns:(string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Talks to device functions *)
let ttd_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

let ttd_calls: (string, int) Hashtbl.t = (Hashtbl.create 15);;
let dma_calls: (string, int) Hashtbl.t = (Hashtbl.create 15);;
let port_calls: (string, int) Hashtbl.t = (Hashtbl.create 15);;
let mmio_calls: (string, int) Hashtbl.t = (Hashtbl.create 15);;


let ttk_calls: (string, int) Hashtbl.t = (Hashtbl.create 15);;

let sync_calls: (string, int) Hashtbl.t = (Hashtbl.create 15);;

let alloc_calls: (string, int) Hashtbl.t = (Hashtbl.create 15);;

(* Functions which call DMA I/O *) 
let dma_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;
let port_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;
let mmio_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;


(* Talks to kernel functions *)
let ttk_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Allocates memory in some form *)
let allocator_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Configuration functions *)
let config_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* sys/devctl function name and parent name *)
let devctl_fns : (string,string) Hashtbl.t = (Hashtbl.create 15);;

(* Provides core device functionality *)
let core_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;
let intr_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;


(* synch functions *)
let sync_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* event functions *)
let event_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* bus functions *)
let bus_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* thread functions *)
let thread_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* caller callee pairs *)
let cloc : (string, int) Hashtbl.t = (Hashtbl.create 200);;

(* Seen cnids *)
let seencnids : (int, int) Hashtbl.t = (Hashtbl.create 50);;

(* Seen cnids *)
let seencnidsprod : (int*int, int) Hashtbl.t = (Hashtbl.create 50);;
(* Seen cnids  -- global *)
let gseencnids : (int, int) Hashtbl.t = (Hashtbl.create 50);;

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

  method find_lvals_exp_str (e:exp ) : string list =
    begin
      match e with
        | Lval(lh,_)  ->
            (match lh with
               | Var (vinfo) ->
                   vinfo.vname ::[];
               | Mem(ex) -> [];
            );
        | AddrOf(lv_inner) ->
            let (lh, _) = lv_inner in
              (match lh with
                 | Var (vinfo)->
                     vinfo.vname :: [];
                 | Mem(ex) -> [];
              );
        | BinOp (b, e1, e2, typ) ->
            (self#find_lvals_exp_str e1)@(self#find_lvals_exp_str e2);
        | UnOp (op, e, typ) ->
            (self#find_lvals_exp_str e);
        | CastE (typ, e) ->
            (self#find_lvals_exp_str e);
        | SizeOfE (e) ->
            (self#find_lvals_exp_str e);
        | AlignOfE(e) ->
            (self#find_lvals_exp_str e);

        | _ -> [];
    end

  method locatefuncass (i:instr) : unit =
    begin
      match i with 
        | Set (_,e,_) -> let lval_list = self#find_lvals_exp e in
                          for j = 0 to (List.length lval_list) - 1 do
                            let cur_lval = (List.nth lval_list j) in
                               match(cur_lval) with
                                 | (Var(v),_) -> (
                                    match (v.vtype) with
                                       TPtr(TFun(_,_,_,_),_) -> Hashtbl.add event_fns curr_func.svar.vname ""; 
                                      |_ -> (); 
                                      
                                   ); 
                                |_->();
                          done;
        | _ ->();   
      
    end

      
  (* Visits every "instruction" *)
  method vinst (i: instr) : instr list visitAction =
    begin
      self#locatefuncass i;
      DoChildren;
    end

  method computebranch (s:stmt) : unit = 
    begin
      match s.skind with
        | Instr(ilist) -> ( 
            for j = 0 to (List.length ilist) - 1 do
              let cur_instr = (List.nth ilist j) in
                match cur_instr with
                  | Call(lvalue_option,e,el,loc) -> bfactor:= !bfactor + 1;
                  | Set (lv, ex, loc) -> bfactor:= !bfactor + 1;
                  |_ -> ();

            done;

          );
        | Return(_, loc) -> bfactor:= !bfactor + 1;
        | Goto (_, loc) -> bfactor:= !bfactor + 5;
        | Break (loc) -> bfactor:= !bfactor + 2; 
        | Continue (loc) -> bfactor:= !bfactor + 2; 
        | If (_, _, _, loc) -> bfactor:= !bfactor + 7; 
        | Switch (_, _, _, loc) -> bfactor:= !bfactor + 7 ;
        | Loop (_,loc, _, _) -> bfactor:= !bfactor + 5; 
        | Block (_) -> bfactor:= !bfactor + 1; 
        | TryFinally (_, _, loc) ->bfactor:= !bfactor + 4; 
        | TryExcept (_, _, _, loc) -> bfactor:= !bfactor + 4; 
        | _ ->();

      end     

  method locate_wait_in_exp (e:exp): int =
  begin
    let rc = ref 0 in
    let str_list = self#find_lvals_exp_str e in
      for strctr = 0 to (List.length str_list) -1 do
        let cur_str = (List.nth str_list  strctr) in
          if ((String.compare (cur_str) "time_after_eq" == 0) ||
              (String.compare (cur_str) "time_before" == 0) ||
              (String.compare (cur_str) "time_before_eq" == 0) ||
              (String.compare (cur_str) "time_after" == 0) ||
              (String.compare (cur_str) "wake_up_interruptible" == 0) ||
              (String.compare (cur_str) "msleep_interruptible" == 0) ||
              (String.compare (cur_str) "msleep_interruptible" == 0) ||
              (String.compare (cur_str) "udelay" == 0) ||
              (String.compare (cur_str) "prepare_to_wait" == 0) ||
              (String.compare (cur_str) "finish_wait" == 0)
          ) then
            (rc := 1;);
      done;
        !rc;
  end
    


      
  method locate_wait_in_block (b: block) : int =
    begin
      let rc = ref 0 in
        for i = 0 to (List.length b.bstmts) - 1 do
          let cur_stmt = (List.nth b.bstmts i) in
            match cur_stmt.skind with
                Instr(ilist) ->
                  begin
                  (*  Printf.fprintf stderr "Instr: stmt %d %s.\n" i (stmt_to_string
                                                                     cur_stmt); *)
                    for j = 0 to (List.length ilist) - 1 do
                      let cur_instr = (List.nth ilist j) in

                        match cur_instr with
                          | Call (l,e, el, loc) ->
                              begin
                                rc := !rc + self#locate_wait_in_exp e;
                                for elctr = 0 to (List.length el) - 1 do
                                  rc := !rc + self#locate_wait_in_exp e;                                        
                                done;
                              end
                          | Set(l,e,loc)  -> rc := !rc + self#locate_wait_in_exp e;
                          | _ -> (); 
                    done;       
                  end
              |If(e,b1,b2,loc) -> rc := !rc + self#locate_wait_in_exp e + self#locate_wait_in_block b1 + self#locate_wait_in_block b2  ;
              | Block (b) -> rc := !rc + self#locate_wait_in_block b;
              | Loop(b, _, _,_)  -> rc := !rc + self#locate_wait_in_block b;
              |_ -> ();                                 
        done;
        !rc;
  end

      
  (* Visits every "statement" *)
  method vstmt (s: stmt) : stmt visitAction =
    begin
      self#computebranch s;
(*       match s.skind with
          Loop(b,_,_,_) -> (if ((self#locate_wait_in_block b) == 0) then ( 
                              Hashtbl.add process_fns curr_func.svar.vname ""; 
                              Printf.fprintf stderr "ADDED PROCESS %s.\n" curr_func.svar.vname;
          );
 )                          
                            DoChildren;);
        |_ -> ();
 *)
     
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
        curr_func <- f; (*Store the value of current func before getting into
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
  val mutable curr_func : fundec = emptyFunction "temp"; 
  val mutable last_fun_stmt = ref 0;
  val mutable first_fun_stmt = ref 0;
  val mutable pci_chipsets = ref 1;
  val mutable fn_len_data = ref "";
  val mutable tot_len = ref 0;
  val mutable fn_dev_calls = ref 0;
  val mutable fn_kern_calls = ref 0;
  val mutable fn_sync_calls = ref 0;
  val mutable fn_alloc_calls = ref 0;
  val mutable call_info_data = ref "";                             
  val mutable ioctl_fns_string = ref "";
  val mutable driver_type = ref "empty_type";
  val mutable driver_ops = ref "empty_ops";
  val mutable bus_type = ref "empty_bus_type";
  (*     val mutable call_depth = ref 0;                                   *)

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
  
  method varprocess(v :varinfo)(iinfo:initinfo) :unit = 
  begin
    match v.vtype with
    | TArray(TComp(c,_), Some(Const(CInt64(i,_,_))),_) ->
				if (String.compare c.cname "pci_device_id" == 0)  || (String.compare c.cname "hid_device_id" == 0) || 
                                (String.compare c.cname "ieee1394_device_id" == 0) || (String.compare c.cname "ccw_device_id" == 0) ||
                                (String.compare c.cname "ap_device_id" == 0) || (String.compare c.cname "css_device_id" == 0) ||
                                (String.compare c.cname "memstick_device_id" == 0) || (String.compare c.cname "ipmi_device_id" == 0) ||
                                (String.compare c.cname "tc_device_id" == 0) || (String.compare c.cname "rio_device_id" == 0) ||
                                (String.compare c.cname "acpi_device_id" == 0) || (String.compare c.cname "pnp_device_id" == 0) ||
                                (String.compare c.cname "vlynq_device_id" == 0) || (String.compare c.cname "zorro_device_id" == 0) ||
                                (String.compare c.cname "usb_device_id" == 0) || (String.compare c.cname "zorro_device_id" == 0) ||
                                (String.compare c.cname "pnp_card_device_id" == 0) || (String.compare c.cname "serio_device_id" == 0) ||
                                (String.compare c.cname "isapnp_device_id" == 0) || (String.compare c.cname "superhyway_device_id" == 0) ||
                                (String.compare c.cname "of_device_id" == 0) || (String.compare c.cname "vio_device_id" == 0) ||
                                (String.compare c.cname "pcmcia_device_id" == 0) || (String.compare c.cname "input_device_id" == 0) ||
                                (String.compare c.cname "eisa_device_id" == 0) || (String.compare c.cname "parisc_device_id" == 0) ||
                                (String.compare c.cname "sdio_device_id" == 0) || (String.compare c.cname "ssb_device_id" == 0) ||
                                (String.compare c.cname "i2c_device_id" == 0) || (String.compare c.cname "spi_device_id" == 0) ||
                                (String.compare c.cname "platform_device_id" == 0) || (String.compare c.cname "dmi_system_id" == 0)
                                then 
                                  if (!pci_chipsets <= (Int64.to_int i)) then   (      
                                    pci_chipsets :=  (Int64.to_int i); 
                                    Printf.fprintf stderr "CHIPSET %s %d \n" c.cname (Int64.to_int i);
                                    bus_type:= c.cname;
                                  );

    (*
    if (String.compare c.cname "usb_device_id" = 0) then 	
				   pci_chipsets := (Int64.to_int i);
                                   bus_type:= c.cname; 
				   Printf.fprintf stderr "%s %d \n" c.cname (Int64.to_int i);
   *)
       
      | TComp(c,_)-> (
          Printf.fprintf stderr "\n\n|----------\n%s\n------------|\n" c.cname;
          if (String.compare c.cname "pci_device_id" = 0) then (
            Printf.fprintf stderr "pdi: %s.\n" v.vname;
            match v.vtype with
              | TArray(_,Some(Const(CInt64(i,_,_))),_) -> Printf.fprintf stderr "size:%d \n" (Int64.to_int i);
              | _ -> ();

          );

          (* Search in init*) 
          let match_driver = regexp (".*"^"_driver") in
          if (String.compare c.cname "pci_driver" == 0) || (String.compare c.cname "usb_driver" == 0) || (String.compare c.cname "mtd_chip_driver" == 0) ||
            (String.compare c.cname "scsi_driver" == 0) || (String.compare c.cname "acpi_driver" == 0) ||
            (String.compare c.cname "platform_driver" == 0) || (String.compare c.cname "rio" == 0) ||
            (String.compare c.cname "umc_driver" == 0) || (String.compare c.cname "uart_driver" == 0) ||
            (String.compare c.cname "amba_driver" == 0) || (String.compare c.cname "isa_driver" == 0) ||
            (String.compare c.cname "sysdev_driver" == 0) || (String.compare c.cname "ps3_system_bus_driver" == 0) ||
            (String.compare c.cname "of_platform_driver" == 0) || (String.compare c.cname "xenbus_driver" == 0) ||
            (String.compare c.cname "sdio_driver" == 0)  || (String.compare c.cname "pcmcia_driver" == 0) ||
            (String.compare c.cname  "agp_bridge_driver" == 0) || (String.compare c.cname "tty_driver" == 0) || 
            (String.compare c.cname "vio_driver" == 0) || (String.compare c.cname "pnp_driver" == 0) ||  
            (String.compare c.cname "cx_drv" == 0) || (String.compare c.cname "console" == 0) || (Str.string_match match_driver c.cname 0) == true ||  
            (String.compare c.cname "device_driver" == 0) || (String.compare c.cname "fw_driver" == 0) || 
            (String.compare c.cname "i2c_driver" == 0) || (String.compare c.cname "spi_driver" == 0)  ||
            (String.compare c.cname "hid_driver" == 0) || (String.compare c.cname "ide_driver" == 0) || 
            (String.compare c.cname "hpsb_protocol_driver" == 0) || (String.compare c.cname "parisc_driver" == 0) ||
            (String.compare c.cname "locomo_driver" == 0) || (String.compare c.cname "maple_driver" == 0) ||
            (String.compare c.cname "adb_driver" == 0) || (String.compare c.cname "cx8802_driver" == 0) || 
            (String.compare c.cname "saa7146_extension" == 0) || (String.compare c.cname "mca_driver" == 0) ||  
            (String.compare c.cname "zorro_driver" == 0) || (String.compare c.cname "ecard_driver" == 0) || 
            (String.compare c.cname "usb_configuration" == 0) || (String.compare c.cname "saa7146_extension" == 0) ||
            (String.compare c.cname "acpi_pci_driver" == 0) || (String.compare c.cname "ap_driver" == 0) ||
            (String.compare c.cname "audio_driver" == 0) || (String.compare c.cname "ccw_driver" == 0) ||
            (String.compare c.cname "ccwgroup_driver" == 0) || (String.compare c.cname "comedi_driver" == 0) ||
            (String.compare c.cname "cpufreq_driver" == 0) || (String.compare c.cname "cpuidle_driver" == 0) ||
            (String.compare c.cname "css_driver" == 0) || (String.compare c.cname "cx8802_driver" == 0) ||
            (String.compare c.cname "dio_driver" == 0) || (String.compare c.cname "drm_driver" == 0) ||
            (String.compare c.cname "drm_i2c_encoder_driver" == 0) || (String.compare c.cname "dsa_switch_driver" == 0) ||
            (String.compare c.cname "eisa_driver" == 0) || (String.compare c.cname "hc_driver" == 0) || (String.compare c.cname "rtl818x_rf_ops" == 0) || 
            (String.compare c.cname "hid_ll_driver" == 0) || (String.compare c.cname "hpsb_host_driver" == 0) ||
            (String.compare c.cname "i2o_driver" == 0) || (String.compare c.cname "lm_driver" == 0) || (String.compare c.cname "macio_driver" == 0) ||
            (String.compare c.cname "mcp_driver" == 0) || (String.compare c.cname "memstick_driver" == 0) || (String.compare c.cname "mmc_driver" == 0) ||
            (String.compare c.cname "mpt_pci_driver" == 0) || (String.compare c.cname "omap_dss_driver" == 0) || (String.compare c.cname "parport_driver" == 0) ||
            (String.compare c.cname "pcie_port_service_driver" == 0) || (String.compare c.cname "phy_driver" == 0) || (String.compare c.cname "platform_device_driver" == 0) ||
            (String.compare c.cname "pnp_card_driver" == 0) || (String.compare c.cname "ps3_vuart_port_driver" == 0) 
            || (String.compare c.cname "real_driver" == 0) || (String.compare c.cname "sa1111_driver" == 0) ||
            (String.compare c.cname "soundbus_driver" == 0) || (String.compare c.cname "ssb_driver" == 0) || (String.compare c.cname "tc_driver" == 0) ||
            (String.compare c.cname "tifm_driver" == 0) || (String.compare c.cname "ttm_bo_driver" == 0) || (String.compare c.cname "ucb1x00_driver" == 0) || (String.compare c.cname "usbatm_driver" == 0) ||
            (String.compare c.cname "usb_composite_driver" == 0) || (String.compare c.cname "usb_gadget_driver" == 0) || (String.compare c.cname "usb_serial_driver" == 0) ||
            (String.compare c.cname "usbvideo_cb qcm_driver" == 0) || (String.compare c.cname "virtio_driver" == 0) || (String.compare c.cname "vme_driver" == 0) 
               
             
            then (
            driver_type := c.cname;
            match iinfo.init with Some (CompoundInit(t,oilist)) -> (
              for i = 0 to (List.length oilist) -1 do 
                let (curr_o,curr_i) =  (List.nth oilist i) in 
                  match curr_o with (Field(finfo,o)) ->(

                    let match_regexp = regexp (".*"^"shutdown"^".*") in
                    let match_regexp2 = regexp (".*"^"remove"^".*") in
                    let match_regexp3 = regexp(".*"^"disconnect"^".*") in
                      if (Str.string_match match_regexp finfo.fname 0) == true || (Str.string_match match_regexp2 finfo.fname 0) == true 
                       || (Str.string_match match_regexp3 finfo.fname 0) == true then (
                        Printf.fprintf stderr ">>>>>>>>>cleanup fn is (%s)" finfo.fname;
                        match curr_i with (SingleInit(init_exp)) -> (
                          (* Printf.fprintf stderr "%s.\n" (exp_to_string
                           * init_exp); *)
                          match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                            Hashtbl.add cleanup_fns vinfo.vname c.cname;
                            Printf.fprintf stderr "%s" vinfo.vname
                          );
                            |_ -> ();
                        );
                          |_ -> ();
                      );


                      let match_regexp = regexp (".*"^"probe"^".*") in
                        if (Str.string_match match_regexp finfo.fname 0) == true  then (
                          Printf.fprintf stderr ">>>>>>>>>init fn is %s" finfo.fname;
                          match curr_i with (SingleInit(init_exp)) -> (
                            (* Printf.fprintf stderr "%s.\n" (exp_to_string
                             * init_exp); *)
                            match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                              Hashtbl.add init_fns vinfo.vname c.cname;
                              Printf.fprintf stderr "%s" vinfo.vname
                            );
                              |_ -> ();
                          );
                            |_ -> ();
                        ); 


                     
                        let match_regexp = regexp (".*"^"suspend"^".*") in
                        let match_regexp2 = regexp (".*"^"resume"^".*") in
                          if (Str.string_match match_regexp finfo.fname 0) == true 
                            || (Str.string_match match_regexp2 finfo.fname 0) == true then (
                               Printf.fprintf stderr ">>>>>>>>>pm fn is %s" finfo.fname;
                               match curr_i with (SingleInit(init_exp)) -> (
                                 (* Printf.fprintf stderr "%s.\n" (exp_to_string
                                  * init_exp); *)
                                 match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                   Hashtbl.add pm_fns vinfo.vname c.cname;
                                   Printf.fprintf stderr "%s\n" vinfo.vname
                                 );
                                   |_ -> ();
                               );
                                 |_ ->();
                             );


                          let match_regexp = regexp (".*"^"err_handler"^".*") in
                            if (Str.string_match match_regexp finfo.fname 0) == true 
                              then (
                                 Printf.fprintf stderr ">>>>>>>>>err fn is %s:" finfo.fname;
                                 match curr_i with (SingleInit(init_exp)) -> (
                                   (* Printf.fprintf stderr "%s.\n" (exp_to_string
                                    * init_exp); *)
                                   match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                     Hashtbl.add err_fns vinfo.vname c.cname;
                                     Printf.fprintf stderr "%s\n" vinfo.vname;
                                   );
                                     |_ -> ();
                                 );
                                   |_ ->();
                               );




                  );
                    |_ -> ();
              done;
            );
              |_ -> ();
          );                    


          (* Search for error handler fn *) 
          if (String.compare c.cname "pci_error_handlers" = 0) then (
            Printf.fprintf stderr "pci_error_handler  %s\n" v.vname;
            Hashtbl.add err_fns v.vname c.cname;
            match iinfo.init with Some (CompoundInit(t,oilist)) -> (
              for i = 0 to (List.length oilist) -1 do 
                let (curr_o,curr_i) =  (List.nth oilist i) in 
                  match curr_o with (Field(finfo,o)) ->(

                    Printf.fprintf stderr ">>>>>>>>>err fn is (%s)" finfo.fname;
                    match curr_i with (SingleInit(init_exp)) -> (
                      match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                        Hashtbl.add err_fns vinfo.vname c.cname;
                        Printf.fprintf stderr "%s" vinfo.vname
                      );
                        |_ -> ();
                    );
                      |_ -> ();

                  );
                    |_ -> ();
              done;
            );
             |_ -> ();                                              
          );



          (* Search for power management fn *) 
          if (String.compare c.cname "dev_pm_ops" == 0) then (
            Printf.fprintf stderr "dev_pm_ops  %s\n" v.vname;
            Hashtbl.add err_fns v.vname c.cname;
            match iinfo.init with Some (CompoundInit(t,oilist)) -> (
              for i = 0 to (List.length oilist) -1 do 
                let (curr_o,curr_i) =  (List.nth oilist i) in 
                  match curr_o with (Field(finfo,o)) ->(

                    Printf.fprintf stderr ">>>>>>>>>pm fn is (%s)" finfo.fname;
                    match curr_i with (SingleInit(init_exp)) -> (
                      match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                        Hashtbl.add pm_fns vinfo.vname c.cname;
                        Printf.fprintf stderr "%s" vinfo.vname
                      );
                        |_ -> ();
                    );
                      |_ -> ();

                  );
                    |_ -> ();
              done;
            );
            |_ -> ();                                                                    
          );

          (* Search for ioctl ops *)
          let match_ops = regexp (".*"^"_ops") in 
          if (String.compare c.cname "block_device_operations" == 0) || (String.compare c.cname "net_device_ops" == 0)
            || (String.compare c.cname "ethtool_ops" == 0) ||  (Str.string_match match_ops c.cname 0) == true  
            || (String.compare c.cname "fb_ops" == 0) || (String.compare c.cname "file_operations" == 0)  ||
             (String.compare c.cname "tty_operations" == 0) || (String.compare c.cname "snd_pcm_ops" == 0) ||
             (String.compare c.cname "cdrom_device_ops" == 0) || (String.compare c.cname "ide_disk_ops" == 0) ||  
             (String.compare c.cname "loop_func_table" == 0) || ( String.compare c.cname "pccard_resource_ops" == 0) ||
             (String.compare c.cname "atmdev_ops" == 0)  || (String.compare c.cname "snd_emux_operators" == 0) ||
             (String.compare c.cname "proto_ops" == 0) || (String.compare c.cname "scsi_host_template" == 0) ||
             (String.compare c.cname "pccard_operations" == 0) || (String.compare c.cname "ata_port_operations" == 0) ||
             (String.compare c.cname "thermal_zone_device_ops" == 0) || (String.compare c.cname "atmphy_ops" == 0) ||
             (String.compare c.cname "atm_tcp_ops" == 0 ) ||  (String.compare c.cname "backlight_ops" == 0)   || 
             (String.compare c.cname "c2port_ops" == 0) || (String.compare c.cname "dca_ops" == 0) || 
             (String.compare c.cname "dma_map_ops" == 0) || (String.compare c.cname "fb_ops" == 0) ||
             (String.compare c.cname "fb_tile_ops" == 0) || (String.compare c.cname "mpc8xx_pcmcia_ops" == 0) ||
             (String.compare c.cname "hdlcdrv_ops" == 0) || (String.compare c.cname "ide_port_ops" == 0) ||
             (String.compare c.cname "ide_dma_ops" == 0) || (String.compare c.cname "ide_tp_ops" == 0) ||
             (String.compare c.cname "iommu_ops" == 0 ) || (String.compare c.cname "lcd_ops" == 0) ||
             (String.compare c.cname "mdiobb_ops" == 0) || (String.compare c.cname "proto_ops" == 0) ||
             (String.compare c.cname "nsc_gpio_ops" == 0) || (String.compare c.cname "pci_ops" == 0) ||
             (String.compare c.cname "hotplug_slot_ops" == 0) || (String.compare c.cname "ppp_channel_ops" == 0) ||
             (String.compare c.cname "rio_ops" == 0) || (String.compare c.cname "rio_route_ops" == 0) ||
             (String.compare c.cname "rtc_class_ops" == 0) || (String.compare c.cname "uart_ops" == 0) ||
             (String.compare c.cname "thermal_cooling_device_ops" == 0) || (String.compare c.cname "tty_ldisc_ops" == 0) ||
             (String.compare c.cname "virtqueue_ops" == 0) || (String.compare c.cname "virtio_config_ops" == 0) || 
             (String.compare c.cname "plat_vlynq_ops" == 0) || (String.compare c.cname " wm97xx_mach_ops" == 0) || 
              (String.compare c.cname "radeon_asic" == 0) || (String.compare c.cname "b43_phy_operations" ==0) ||
             (String.compare c.cname "oxygen_model" == 0) || (String.compare c.cname "mii_phy_ops" == 0)  ||
             (String.compare c.cname "vio_driver_ops" == 0) then (
               driver_ops := c.cname;
               Printf.fprintf stderr "bd variable is: %s.\n" v.vname;
               match iinfo.init with Some (CompoundInit(t,oilist)) -> (
                 for i = 0 to (List.length oilist) -1 do
                   let (curr_o,curr_i) =  (List.nth oilist i) in
                     match curr_o with (Field(finfo,o)) ->(

                       let match_regexp = regexp (".*"^"ioctl"^".*") in
                         if (Str.string_match match_regexp finfo.fname 0) = true  then (
                           Printf.fprintf stderr "assign fname is %s" finfo.fname;
                           match curr_i with (SingleInit(init_exp)) -> (
                             (* Printf.fprintf stderr "%s.\n" (exp_to_string
                              * init_exp); *)
                             match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                               Hashtbl.add ioctl_fns vinfo.vname c.cname;
                               Printf.fprintf stderr "%s" vinfo.vname
                           );
                             |_ -> ();
                           );
                             |_ -> ();
                         );


                       let match_regexp = regexp (".*"^"open"^".*") in 
                       let match_regexp2 = regexp (".*"^"detect"^".*") in
                       let match_regexp3 = regexp (".*"^"init"^".*") in
                       let match_regexp4 = regexp (".*"^"install"^".*") in
                       let match_regexp5 = regexp (".*"^"detect"^".*") in
                       let match_regexp6 = regexp (".*"^"alloc"^".*") in
                         if (Str.string_match match_regexp finfo.fname 0) == true ||
                          (Str.string_match match_regexp2 finfo.fname 0) == true ||
                         (Str.string_match match_regexp3 finfo.fname 0) == true ||
                          (Str.string_match match_regexp4 finfo.fname 0) == true ||
                          (Str.string_match match_regexp5 finfo.fname 0) == true ||
                           (Str.string_match match_regexp6 finfo.fname 0) == true    then (
                           Printf.fprintf stderr "open fname is %s" finfo.fname;
                           match curr_i with (SingleInit(init_exp)) -> (
                             (* Printf.fprintf stderr "%s.\n" (exp_to_string
                              * init_exp); *)
                             match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                               Hashtbl.add init_fns vinfo.vname c.cname;
                               Printf.fprintf stderr "%s" vinfo.vname
                           );
                             |_ -> ();
                           );
                             |_ -> ();
                         );


                       let match_regexp = regexp (".*"^"close"^".*") in
                       let match_regexp2 = regexp (".*"^"stop"^".*") in
                       let match_regexp3 = regexp (".*"^"release"^".*") in
                       let match_regexp4 = regexp (".*"^"uninit"^".*") in
                       let match_regexp5 = regexp (".*"^"cleanup"^".*") in
                       let match_regexp6 = regexp (".*"^"free"^".*") in
                       let match_regexp7 = regexp (".*"^"destroy"^".*") in
                       let match_regexp8 = regexp (".*"^"suspend"^".*") in
                         if (Str.string_match match_regexp finfo.fname 0) == true ||
                        (Str.string_match match_regexp2 finfo.fname 0) == true  ||
                        (Str.string_match match_regexp3 finfo.fname 0) == true ||
                        (Str.string_match match_regexp4 finfo.fname 0) == true ||
                        (Str.string_match match_regexp5 finfo.fname 0) == true ||
                        (Str.string_match match_regexp6 finfo.fname 0) == true ||
                        (Str.string_match match_regexp7 finfo.fname 0) == true ||
                        (Str.string_match match_regexp8 finfo.fname 0) == true then (
                           Printf.fprintf stderr "close fname is %s" finfo.fname;
                           match curr_i with (SingleInit(init_exp)) -> (
                             (* Printf.fprintf stderr "%s.\n" (exp_to_string
                              * init_exp); *)
                             match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                               Hashtbl.add cleanup_fns vinfo.vname c.cname;
                               Printf.fprintf stderr "%s" vinfo.vname
                           );
                             |_ -> ();
                           );
                             |_ -> ();
                         );

                         

                       let match_regexp = regexp (".*"^"select"^".*") in
                       let match_regexp2 = regexp (".*"^"check"^".*") in
                       let match_regexp3 = regexp (".*"^"change"^".*") in (* was change_mtu *)
                       let match_regexp4 = regexp (".*"^"status"^".*") in
                       let match_regexp5 = regexp (".*"^"params"^".*") in (* was set_rx_mode *)
                       let match_regexp6 = regexp (".*"^"enable"^".*") in
                       let match_regexp7 = regexp (".*"^"disable"^".*") in
                       let match_regexp8 = regexp (".*"^"config"^".*") in
                       let match_regexp9 = regexp (".*"^"get"^".*") in
                       let match_regexp10 = regexp (".*"^"set"^".*") in (* implicitly includes reset *)
                       let match_regexp11 = regexp (".*"^"configure"^".*") in
                       let match_regexp12 = regexp (".*"^"info"^".*") in
                       let match_regexp13= regexp (".*"^"show"^".*") in
                       let match_regexp14 = regexp (".*"^"check"^".*") in
                       let match_regexp15 = regexp (".*"^"supported"^".*") in
                       let match_regexp16 = regexp (".*"^"hw_ctrl"^".*") in
                       let match_regexp17 = regexp (".*"^"on"^".*") in
                       let match_regexp18 = regexp (".*"^"off"^".*") in
                 
                         if (Str.string_match match_regexp finfo.fname 0) == true || (Str.string_match match_regexp2 finfo.fname 0) == true ||
                        (Str.string_match match_regexp3 finfo.fname 0) == true || (Str.string_match match_regexp4 finfo.fname 0) == true ||
                        (Str.string_match match_regexp5 finfo.fname 0) == true || (Str.string_match match_regexp6 finfo.fname 0) == true ||
                      (Str.string_match match_regexp7 finfo.fname 0) == true || (Str.string_match match_regexp8 finfo.fname 0) == true ||
                          (Str.string_match match_regexp9 finfo.fname 0) == true || (String.compare c.cname "ethtool_ops" == 0) ||
                         (Str.string_match match_regexp10 finfo.fname 0) == true || (Str.string_match match_regexp11 finfo.fname 0) == true ||
                         (Str.string_match match_regexp12 finfo.fname 0) == true ||  (Str.string_match match_regexp13 finfo.fname 0) == true ||
                         (Str.string_match match_regexp14 finfo.fname 0) == true || (Str.string_match match_regexp15 finfo.fname 0) == true   || 
                         (Str.string_match match_regexp16 finfo.fname 0) == true || (Str.string_match match_regexp17 finfo.fname 0) == true   ||  
                         (Str.string_match match_regexp18 finfo.fname 0) == true || (Str.string_match match_regexp18 finfo.fname 0) == true   then  (
                           Printf.fprintf stderr "\n++++++config fname is %s" finfo.fname;
                           match curr_i with (SingleInit(init_exp)) -> (
                             match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                               Hashtbl.add config_fns vinfo.vname c.cname;
                               Printf.fprintf stderr "%s" vinfo.vname
                           );
                             |_ -> ();
                           );
                             |_ -> ();
                         );


                               let match_regexp = regexp (".*"^"proc"^".*") in
                                 if (Str.string_match match_regexp finfo.fname 0) = true  then (

                                   Printf.fprintf stderr "proc fname is %s" finfo.fname;
                                   match curr_i with (SingleInit(init_exp)) -> (
                                     match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                       Hashtbl.add proc_fns vinfo.vname c.cname;
                                       Printf.fprintf stderr "%s" vinfo.vname
                                     );
                                       |_ -> ();
                                   );
                                     |_ -> ();                                            
                                 ); 




                               (* Generate devctl information *)  
                               let match_regexp = regexp (".*"^"devctl"^".*") in
                               let match_regexp2 = regexp (".*"^"sysctl"^".*") in
                                 if (Str.string_match match_regexp finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp2 finfo.fname 0) = true then (

                                   Printf.fprintf stderr "devctl fname is %s" finfo.fname;
                                   match curr_i with (SingleInit(init_exp)) -> (
                                     match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                       Hashtbl.add devctl_fns vinfo.vname c.cname;
                                       Printf.fprintf stderr "%s" vinfo.vname
                                     );
                                       |_ -> ();
                                   );
                                     |_ -> ();                                             
                                 );



                                 

                               let match_regexp = regexp (".*"^"read"^".*") in
                               let match_regexp2 = regexp (".*"^"write"^".*") in
                               let match_regexp3 = regexp (".*"^"xmit"^".*") in
                               let match_regexp4 = regexp (".*"^"changed"^".*") in
                               let match_regexp5 = regexp (".*"^"timeout"^".*") in
                               let match_regexp6 = regexp (".*"^"flush"^".*") in
                               let match_regexp7 = regexp (".*"^"start"^".*") in
                               let match_regexp8 = regexp (".*"^"throttle"^".*") in
                               let match_regexp9 = regexp (".*"^"prepare"^".*") in
                               let match_regexp10 = regexp (".*"^"trigger"^".*") in
                               let match_regexp11 = regexp (".*"^"ack"^".*") in
                               let match_regexp21 = regexp (".*"^"reset"^".*") in
                               let match_regexp31 = regexp (".*"^"update"^".*") in
                               let match_regexp41 = regexp (".*"^"load"^".*") in
                               let match_regexp12 = regexp (".*"^"rx"^".*") in
                               let match_regexp32 = regexp (".*"^"kick"^".*") in
                               let match_regexp42 = regexp (".*"^"valid"^".*") in
                               let match_regexp22 = regexp (".*"^"tx"^".*") in
                               let match_regexp13 = regexp (".*"^"mem"^".*") in
                               let match_regexp23 = regexp (".*"^"qc"^".*") in
                               let match_regexp33 = regexp (".*"^"freeze"^".*") in
                               let match_regexp43 = regexp (".*"^"thaw"^".*") in
                               let match_regexp14 = regexp (".*"^"load"^".*") in
                               let match_regexp24 = regexp (".*"^"notify"^".*") in
                               let match_regexp34 = regexp (".*"^"bind"^".*") in
                               let match_regexp44 = regexp (".*"^"interrupt"^".*") in
                               let match_regexp15 = regexp (".*"^"access"^".*") in
                               let match_regexp25 = regexp (".*"^"sync"^".*") in
                               let match_regexp35 = regexp (".*"^"exec"^".*") in
                               let match_regexp45 = regexp (".*"^"data"^".*") in
                               let match_regexp16 = regexp (".*"^"io"^".*") in
                               let match_regexp26 = regexp (".*"^"map"^".*") in
                               let match_regexp36 = regexp (".*"^"silence"^".*") in
                               let match_regexp46 = regexp (".*"^"copy"^".*") in
                               let match_regexp17 = regexp (".*"^"fb_cursor"^".*") in
                               let match_regexp27 = regexp (".*"^"fb_image"^".*") in
                               let match_regexp37 = regexp (".*"^"fb_tile"^".*") in
                               let match_regexp47 = regexp (".*"^"filter"^".*") in
                               let match_regexp18 = regexp (".*"^"connect"^".*") in
                               let match_regexp28 = regexp (".*"^"socket"^".*") in
                               let match_regexp38 = regexp (".*"^"send"^".*") in
                               let match_regexp48 = regexp (".*"^"rec"^".*") in
                               let match_regexp19 = regexp (".*"^"fb_blank"^".*") in
                               let match_regexp29 = regexp (".*"^"fb_pan"^".*") in
                               let match_regexp39 = regexp (".*"^"fb_fill"^".*") in
                               let match_regexp49 = regexp (".*"^"fb_copy"^".*") in
                               let match_regexp20 = regexp (".*"^"sysex"^".*") in
                               let match_regexp30 = regexp (".*"^"reset"^".*") in
                               let match_regexp40 = regexp (".*"^"command"^".*") in
                               let match_regexp50 = regexp (".*"^"scan"^".*") in
                                 if (Str.string_match match_regexp finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp2 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp3 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp4 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp5 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp6 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp7 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp8 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp9 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp10 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp11 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp21 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp31 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp41 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp22 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp32 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp42 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp12 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp13 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp23 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp33 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp43 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp24 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp14 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp34 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp34 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp15 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp25 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp35 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp45 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp16 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp26 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp36 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp46 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp17 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp27 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp37 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp47 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp18 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp28 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp38 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp48 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp19 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp29 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp39 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp49 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp20 finfo.fname 0) == true  || 
                                  (Str.string_match match_regexp30 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp40 finfo.fname 0) == true  ||
                                  (Str.string_match match_regexp50 finfo.fname 0) == true    
                                 then (

                                   Printf.fprintf stderr "core fname is %s" finfo.fname;
                                   match curr_i with (SingleInit(init_exp)) -> (
                                     match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                       Hashtbl.add core_fns vinfo.vname c.cname;
                                       Printf.fprintf stderr "%s" vinfo.vname
                                     );
                                       |_ -> ();
                                   );
                                     |_ -> ();                                            
                                  ); 



                               (* Generate error handline information *)  
                               let match_regexp = regexp (".*"^"eh"^".*"^"handler"^".*") in
                               let match_regexp2 = regexp (".*"^"error"^".*") in
                                 if (Str.string_match match_regexp finfo.fname 0) = true ||
                                  (Str.string_match match_regexp2 finfo.fname 0) = true  then (

                                   Printf.fprintf stderr "errr fname is %s" finfo.fname;
                                   match curr_i with (SingleInit(init_exp)) -> (
                                     match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                       Hashtbl.add err_fns vinfo.vname c.cname;
                                       Printf.fprintf stderr "%s" vinfo.vname
                                     );
                                       |_ -> ();
                                   );
                                     |_ -> ();                                             
                                  );
                                 
                                 
                             );
                               |_ -> ();
                         done;           
                       ); 
                         | _ -> ();
                                (* Hashtbl.add ioctl_fns finfo.fname
                                 * "block_device_operations"; *)
                     );

		     if (String.compare c.cname "pci_driver" == 0) then	(
			Printf.fprintf stderr "%s.\n" v.vname;
		     for i = 0 to (List.length c.cfields) - 1 do
          		let curr_cf = (List.nth c.cfields i) in
          		Printf.fprintf stderr "f:%s\n" curr_cf.fname;
			if (String.compare curr_cf.fname "id_table" == 0) then	(
			 Printf.fprintf stderr "id_table found \n";
			match curr_cf.ftype with
              		   | TArray(_,Some(Const(CInt64(i,_,_))),_) -> Printf.fprintf stderr "%d \n" (Int64.to_int i);
              		   | _ -> ();   
			);
		     done;

		     );
		);
    | _ -> (); 
  end
  
  (* Process globals *)
   method initial_filter (glob: global) : unit =
   begin
     let varinitinfo : initinfo = { init = None; } in
     match glob with
       | GType(t, _) ->  (); (* t.tname;  *)
       | GCompTag(c, _) -> (); (* c.cname; *)
       | GCompTagDecl(c, _) -> (); (* c.cname;*)
       | GEnumTag(e, _) -> (); (* Printf.fprintf stderr "en:%s.\n" e.ename;  *)
       | GEnumTagDecl(e, _) -> (); (* Printf.fprintf stderr "en:%s.\n" e.ename; *)
       | GVarDecl(v, _) ->  self#varprocess v varinitinfo; (* v.vname;   *)
       | GVar(v, i, _) -> self#varprocess v i; self#locatemodparam v.vname; Printf.fprintf stderr "vname:%s.\n" v.vname;
       | GFun(f, _) -> (); (* f.svar.vname; *)
       | GAsm(s, _) ->  (); (*s; *)
       | GPragma(a, _) -> (); (* "attribute";*)
       | GText (t) -> (); (* t; *)
   end
  
  method locate_dev_call (e:exp) (el: exp list): unit =
  begin
    let str_list = self#find_lvals_exp e in
      for strctr = 0 to (List.length str_list) -1 do
        let cur_str = (List.nth str_list  strctr) in
          if (self#ttd (cur_str) == 1) 
           then
            (fn_dev_calls := !fn_dev_calls + 1;);


          if (self#ttk (cur_str) == 1) 
           then
            (fn_kern_calls := !fn_kern_calls + 1;    );

          if (self#has_sync (cur_str) == 1) 
           then
            (fn_sync_calls := !fn_sync_calls + 1;);

          if (String.compare "kmalloc"  (cur_str) == 0) || (String.compare "kzalloc" (cur_str) == 0) || (String.compare "vmalloc" (cur_str) == 0) 
            || (String.compare "kmalloc_large"  (cur_str) == 0) || (String.compare "vmalloc32" (cur_str) == 0) || (String.compare "vmalloc_size" (cur_str) == 0)                                                                                             
           then
            ( fn_alloc_calls := !fn_alloc_calls +1; (*^"+"^(exp_to_string (List.nth
             * el 0));  *)
             Printf.fprintf stderr "ALLOCATED %s.\n\\n\n" (exp_to_string (List.nth el 0));    


            ); 
           
           
      done;
  end

  method locatemodparam (cur_str:string) : unit =
    begin
      let match_regexp = regexp(".*"^"__param_str"^".*") in 
        if  (Str.string_match match_regexp cur_str 0) = true then (
           modparams := !modparams + 1; 
          Printf.fprintf stderr "MODPARAM.\n\\n\n";
        )
    end

          
   method finddeviceint (i: instr) : unit =
   begin
       match i with 
         | Call(_,exp, el,  _) -> (self#locate_dev_call exp el;
                                );
         | _ -> ();
   end

   (*Visits every instruction -> Second pass *)
   method vinst (ins: instr) : instr list visitAction =
   begin
     self#finddeviceint ins;
     DoChildren;
   end

  method locate_wait_in_exp (e:exp): int =
  begin
    let rc = ref 0 in
    let str_list = self#find_lvals_exp e in
      for strctr = 0 to (List.length str_list) -1 do
        let cur_str = (List.nth str_list  strctr) in
          if ((String.compare (cur_str) "time_after_eq" == 0) ||
              (String.compare (cur_str) "time_before" == 0) ||
              (String.compare (cur_str) "time_before_eq" == 0) ||
              (String.compare (cur_str) "time_after" == 0) ||
              (String.compare (cur_str) "wake_up_interruptible" == 0) ||
              (String.compare (cur_str) "msleep_interruptible" == 0) ||
              (String.compare (cur_str) "msleep"== 0) ||
              (String.compare (cur_str) "prepare_to_wait" == 0) ||
              (String.compare (cur_str) "finish_wait" == 0)
          ) then
            (rc := 1;);
      done;
        !rc;
  end
    


      
  method locate_wait_in_block (b: block) : int =
    begin
      let rc = ref 0 in
        for i = 0 to (List.length b.bstmts) - 1 do
          let cur_stmt = (List.nth b.bstmts i) in
            match cur_stmt.skind with
                Instr(ilist) ->
                  begin
                   (* Printf.fprintf stderr "Instr: stmt %d %s.\n" i (stmt_to_string
                                                                      cur_stmt); *)
                    for j = 0 to (List.length ilist) - 1 do
                      let cur_instr = (List.nth ilist j) in

                        match cur_instr with
                          | Call (l,e, el, loc) ->
                              begin
                                rc := !rc + self#locate_wait_in_exp e;
                                for elctr = 0 to (List.length el) - 1 do
                                  rc := !rc + self#locate_wait_in_exp e;                                        
                                done;
                              end
                          | Set(l,e,loc)  -> rc := !rc + self#locate_wait_in_exp e;
                          | _ -> (); 
                    done;       
                  end
              |If(e,b1,b2,loc) -> rc := !rc + self#locate_wait_in_exp e + self#locate_wait_in_block b1 + self#locate_wait_in_block b2  ;
              | Block (b) -> rc := !rc + self#locate_wait_in_block b;
              | Loop(b, _, _,_)  -> rc := !rc + self#locate_wait_in_block b;
              |_ -> ();                                 
        done;
        !rc;

    end



   (* Visits every "statement" ( Last Pass) *)
   method vstmt (s: stmt) : stmt visitAction =
   begin

     match s.skind with
         Loop(b,_,_,_) -> if ((self#locate_wait_in_block b) == 0) then Hashtbl.add process_fns curr_func.svar.vname ""; DoChildren;
       |_ -> ();

        if (!currentLoc.line > 0) then
        last_fun_stmt := !currentLoc.line;
	DoChildren;
   end

   (* Visits every block  Pass 2*)
   method vblock (b: block) : block visitAction =
   begin
      DoChildren;
   end

  method retlength (b:string):int =
    begin
      try
        Hashtbl.find fn_start_end b;
      with Not_found ->  0;
    end
  
  method retcloc (b:string) : int =
    begin
      try
        Hashtbl.find cloc b;
      with Not_found -> 0;
    end
  
  method is_ioctl (b:string) : int =
   begin   
      try
        Hashtbl.find ioctl_fns b;
        1;
      with Not_found -> 0;
   end

  method is_process (b:string) : int =
    begin
      try
        Hashtbl.find process_fns b;
        1;
      with Not_found -> 0;
    end
     
  method is_init (b:string) : int =
   begin   
      try
        Hashtbl.find init_fns b;
        1;
      with Not_found -> 0;
   end
 
  method is_cleanup (b:string) : int =
    begin
      try
        Hashtbl.find cleanup_fns b;
        1;
      with Not_found ->0;
    end
  
  method is_pm (b:string) : int =
   begin
    try
     Hashtbl.find pm_fns b;
     1;
    with Not_found -> 0;
   end
 
  method is_modpm (b:string) : int =
   begin
    try
     Hashtbl.find modpm_fns b;
     1;
    with Not_found -> 0;
   end
 
  method devctl_hash (b:string) : int =
    begin
      try     
        Hashtbl.find devctl_fns b;
        1;
      with Not_found ->  0;

    end
      
     
  method is_devctl (b:string) : int =
    begin
      let ret_val = ref 0 in
      let match_regexp = regexp(".*"^"sysctl"^".*") in
        ret_val := !ret_val + self#devctl_hash b;
        if (Str.string_match match_regexp b 0) == true then
          ret_val:= 1; 
        !ret_val;                     
    end

  method proc_hash (b:string) : int =
   begin
    try
     Hashtbl.find proc_fns b;
     1;
    with Not_found -> 0;
   end
  
  method is_proc (b:string) : int =
    begin
      let ret_val = ref 0 in
      let match_regexp = regexp(".*"^"proc"^".*") in
        ret_val := !ret_val + self#proc_hash b;
        if (Str.string_match match_regexp b 0) == true then
          ret_val:= 1; 
        !ret_val;                     
    end


  method intr_hash (b:string) : int =
   begin
    try
     Hashtbl.find intr_fns b;
     1;
    with Not_found -> 0;
   end

  method core_hash (b:string) : int =
   begin
    try
     Hashtbl.find core_fns b;
     1;
    with Not_found -> 0;
   end
  
  method is_intr (b:string) : int =
    begin
      let ret_val = ref 0 in
       (* let match_regexp =
        * regexp(".*"^"interrupt"^".*"^"|"^".*"^"irq"^".*"^"|"^".*"^"intr"^".*")
        * in *)
      let match_regexp = regexp(".*"^"intr"^".*") in
      let match_regexp2 = regexp(".*"^"irq"^".*") in
      let match_regexp3 = regexp(".*"^"interrupt"^".*") in
        ret_val := !ret_val + self#intr_hash b;
        if (Str.string_match match_regexp b 0) == true
          || (Str.string_match match_regexp b 0) == true
          || (Str.string_match match_regexp b 0) == true 
       
        then (
          ret_val:= 1;
        );
        !ret_val;                     
   end

  method is_core (b:string) : int =
    begin
      let ret_val = ref 0 in
       (* let match_regexp =
        * regexp(".*"^"interrupt"^".*"^"|"^".*"^"irq"^".*"^"|"^".*"^"intr"^".*")
        * in *)
      let match_regexp = regexp(".*"^"intr"^".*") in
      let match_regexp2 = regexp(".*"^"irq"^".*") in
      let match_regexp3 = regexp(".*"^"interrupt"^".*") in
        ret_val := !ret_val + self#core_hash b;
        if (Str.string_match match_regexp b 0) == true
          || (Str.string_match match_regexp2 b 0) == true
          || (Str.string_match match_regexp3 b 0) == true 
       
        then (
          ret_val:= 1;
        );
        !ret_val;                     
   end 

  method ttd (b:string): int =
    begin
      try
        Hashtbl.find ttd_fns b;
        1;
      with Not_found -> 0;
    end
 
  method ttd_count (b:string): int =
    begin
      try
         Hashtbl.find ttd_calls b;
      with Not_found -> 0; 
    end

  method ttk_count (b:string): int =
    begin
      try
         Hashtbl.find ttk_calls b;
      with Not_found -> 0; 
    end

      
  method sync_count (b:string): int =
    begin
      try
         Hashtbl.find sync_calls b;
      with Not_found -> 0; 
    end

  method alloc_count (b:string): int =
    begin
      try
         Hashtbl.find alloc_calls b;
      with Not_found -> 0; 
    end

  method is_dma (b:string): int =
    begin
      try
        Hashtbl.find dma_fns b;
        1;
      with Not_found -> 0;
    end
  
  method is_port (b:string): int =
    begin
      try
        Hashtbl.find port_fns b;
        1;
      with Not_found -> 0;
    end

  method is_mmio (b:string): int =
    begin
      try
        Hashtbl.find mmio_fns b;
        1;
      with Not_found -> 0;
    end

  method has_sync (b:string): int =
    begin
      try
        Hashtbl.find sync_fns b;
        1;
      with Not_found -> 0;
    end

  method has_thread (b:string): int =
    begin
      try
        Hashtbl.find thread_fns b;
        1;
      with Not_found -> 0;
    end

  method event_hash (b:string): int =
    begin
      try
        Hashtbl.find event_fns b;
        1;
      with Not_found -> 0;
    end

  method has_event (b:string) : int =
    begin
      let ret_val = ref 0 in
      let match_regexp = regexp(".*"^"callback"^".*") in
        ret_val := (* !ret_val +*) self#event_hash b;
        if (Str.string_match match_regexp b 0) = true then
          ret_val:= 1;
        !ret_val;
    end


      

  method is_bus (b:string): int =
    begin
      try
        Hashtbl.find bus_fns b;
        1;
      with Not_found -> 0;
    end

      
  method ttk (b:string): int =
    begin
      try
        Hashtbl.find ttk_fns b;
        1;
      with Not_found -> 0;
    end

  method is_allocator (b:string): int =
   begin
    try
     Hashtbl.find allocator_fns b;
    1;
    with Not_found -> 0;
   end 
     
  method is_err (b:string) :int =
   begin
     try
       Hashtbl.find err_fns b;
       1;
     with Not_found -> 0;
   end
 
  method is_config (b:string):int =
   begin
    try
     Hashtbl.find config_fns b;
    1;
    with Not_found -> 0;
   end 
     
  method has_recovery : int =
   begin  
     Hashtbl.length err_fns; 
   end

  method seencnid(a:int): int =
   begin
     try Hashtbl.find seencnids a;
         1;
     with Not_found -> 0;
   end   

  method seencnidprod(a,b:int*int): int =
   begin
     try Hashtbl.find seencnidsprod (a,b);
         1;
     with Not_found -> 0;
   end   
  

     
  method gseencnid(a:int): int =
   begin
     try Hashtbl.find gseencnids a;
         (* Printf.fprintf stderr "seen %d.\n" a;*)
         1;
     with Not_found -> 0;
   end   

  method traversecallers (a:callnode)(call_depth: int) :int = 
    begin
      if (call_depth < 10000) then (
      if (IH.length a.cnCallers > 0) then  (
        (* call_depth <- succ call_depth; *)
        Hashtbl.add seencnids a.cnid 1;
        let node_len = ref 0 in
        let callees =  [] in 
        let recurseCg  _ (cl:callnode):unit =
            if ((self#seencnidprod (a.cnid,cl.cnid)) != 1) then ( (* if  (a.cnid !=
                                                                 cl.cnid) then ( *)
            Hashtbl.add seencnidsprod (a.cnid, cl.cnid) 1;
         (* Propogate tags *)
              let fn_name = (nodeName a.cnInfo) in
              let cl_name = (nodeName cl.cnInfo) in

                (* Propogate tags for ttd and ttk in upward direction *)

                if (self#ttd fn_name == 1) && (self#ttd cl_name !=1) then (
                  Hashtbl.add ttd_fns cl_name fn_name;
                  Hashtbl.replace ttd_calls cl_name (self#ttd_count cl_name + self#ttd_count fn_name);
                );

                if (self#is_dma fn_name == 1) then
                  Hashtbl.add dma_fns cl_name fn_name;


                if (self#is_port fn_name == 1) then
                  Hashtbl.add port_fns cl_name fn_name;

                if (self#is_mmio fn_name == 1) then
                  Hashtbl.add mmio_fns cl_name fn_name;
                
                if (self#ttk fn_name == 1) && (self#ttk cl_name !=1) then (
                  Hashtbl.add ttk_fns cl_name fn_name;
                  Hashtbl.replace ttk_calls cl_name (self#ttk_count cl_name + self#ttk_count fn_name);
                );
                
                if (self#has_sync fn_name == 1) && (self#has_sync cl_name !=1) then  (
                  Hashtbl.add sync_fns cl_name fn_name;
                  Hashtbl.replace sync_calls cl_name (self#sync_count cl_name + self#sync_count fn_name);
                );

                if (self#has_event fn_name == 1) then
                  Hashtbl.add event_fns cl_name fn_name;

                if (self#is_bus fn_name == 1) then
                  Hashtbl.add bus_fns cl_name fn_name;

                if (self#has_thread fn_name == 1) then
                  Hashtbl.add thread_fns cl_name fn_name;
                
                if (self#is_allocator fn_name == 1) && (self#is_allocator cl_name !=1)  then  (
                  Hashtbl.add allocator_fns cl_name fn_name;
                  Hashtbl.replace alloc_calls cl_name (self#alloc_count cl_name + self#alloc_count fn_name);
                );
(*
                if (self#is_process fn_name = 1) then
                  Hashtbl.add process_fns cl_name fn_name;
 *)

           node_len := !node_len + (self#traversecallers cl (call_depth + 1)); 
           );
        in
          IH.iter recurseCg a.cnCallers;
          (* cfactor := !cfactor + List.length(IH.tolist a.cnCallees); *)
          (* Hashtbl.add gseencnids a.cnid 1;  *)
          (* Printf.fprintf stderr "Addding %d + %d.\n" !node_len *)
          (self#retlength(nodeName a.cnInfo));
          !node_len + self#retlength(nodeName a.cnInfo); 
      )
       else 0; 
      )
      else  0;                                   
    end

  method retcumlength (a:callnode)(call_depth: int) :int = 
    begin
      if (call_depth < 10000) then (
      if (IH.length a.cnCallees > 0) then  (
        (* call_depth <- succ call_depth; *)
        Hashtbl.add seencnids a.cnid 1;
        let node_len = ref 0 in
        let callees =  [] in 
        let recurseCg  _ (cl:callnode):unit =
            if ((self#seencnid cl.cnid) != 1) then ( (* if  (a.cnid !=
                                                                 cl.cnid) then ( *)

         (* Propogate tags *)
              let fn_name = (nodeName a.cnInfo) in
              let cl_name = (nodeName cl.cnInfo) in

                if ((self#gseencnid a.cnid) != 1) then  ( 
                  call_info_data := !call_info_data^Printf.sprintf " %s %s"fn_name cl_name;
                );

                                                           
                if (self#is_init fn_name == 1) then
                  Hashtbl.add init_fns cl_name fn_name;

                if (self#is_ioctl fn_name == 1) then
                  Hashtbl.add ioctl_fns cl_name fn_name;             

                if (self#is_cleanup fn_name == 1) then
                  Hashtbl.add cleanup_fns cl_name fn_name;

                if (self#is_pm fn_name == 1) then
                  Hashtbl.add pm_fns cl_name fn_name;

                if (self#is_err fn_name == 1) then
                  Hashtbl.add err_fns cl_name fn_name;

                if (self#is_config fn_name ==1) then
                  Hashtbl.add config_fns cl_name fn_name;
                
                if (self#is_modpm fn_name ==1) then
                  Hashtbl.add modpm_fns cl_name fn_name;
                
                if (self#is_proc fn_name ==1) then
                  Hashtbl.add proc_fns cl_name fn_name;

                if (self#is_devctl fn_name == 1) then
                  Hashtbl.add devctl_fns cl_name fn_name;

                if (self#is_core fn_name == 1) then
                  Hashtbl.add core_fns cl_name fn_name;

                if (self#is_intr fn_name == 1) then
                  Hashtbl.add intr_fns cl_name fn_name;
                (* Propogate tags for ttd and ttk in upward direction *)

         (*       if (self#ttd cl_name = 1) then
                  Hashtbl.add ttd_fns fn_name cl_name;
          
                if (self#is_dma cl_name = 1) then
                  Hashtbl.add dma_fns fn_name cl_name;

                if (self#ttk cl_name = 1) then
                  Hashtbl.add ttk_fns fn_name cl_name;

                if (self#is_allocator cl_name = 1) then
                  Hashtbl.add allocator_fns fn_name cl_name;

                if (self#has_sync cl_name = 1) then
                  Hashtbl.add sync_fns fn_name cl_name;
                
                if (self#has_thread cl_name = 1) then
                  Hashtbl.add thread_fns fn_name cl_name;

                if (self#has_event cl_name = 1) then
                  Hashtbl.add event_fns fn_name cl_name;

                if (self#is_bus cl_name = 1) then
                  Hashtbl.add bus_fns fn_name cl_name;
               *)
                  
           node_len := !node_len + (self#retcumlength cl (call_depth + 1)); 
          (* node_len := self#retlength(nodeName cl.cnInfo); *)
           (* Printf.fprintf stderr ">>(depth %d)seen fn: %s node_len is  %d.\n" call_depth (nodeName
            cl.cnInfo) !node_len;*) 
           );
        in
          IH.iter recurseCg a.cnCallees;
          Hashtbl.add gseencnids a.cnid 1; 
          (* Printf.fprintf stderr "Addding %d + %d.\n" !node_len *)
          (self#retlength(nodeName a.cnInfo));
          !node_len + self#retlength(nodeName a.cnInfo); 
      )
       else (self#retlength(nodeName a.cnInfo)); 
      )
      else  0;                                   
    end

  method printcumlen (b:string)(a:callnode):unit =
    begin
        (* Printf.fprintf stderr ">>>>>>>FN(%s) : \n" b; *)
        let fn_cloc = ref 0 in
           (* call_depth :=0; *)
        fn_cloc := (self#retcumlength a 0); 
        Hashtbl.add cloc b !fn_cloc;
        Hashtbl.clear seencnids;

        
        fn_cloc := (self#retcumlength a 0); 
        Hashtbl.add cloc b !fn_cloc;
        Hashtbl.clear seencnids;
        fn_cloc := (self#retcumlength a 0); 
        Hashtbl.add cloc b !fn_cloc;
        Hashtbl.clear seencnids;
         (* Printf.fprintf stderr "%s length is %d.\n\n" b !fn_cloc; 
          *) 
        
        
        let fn_dloc = ref 0 in
        fn_dloc := (self#traversecallers a 0);
        Hashtbl.clear seencnids;
        Hashtbl.clear seencnidsprod; 
       
        let fn_dloc = ref 0 in
        fn_dloc := (self#traversecallers a 0);
        Hashtbl.clear seencnids;
        Hashtbl.clear seencnidsprod;

        let fn_dloc = ref 0 in
        fn_dloc := (self#traversecallers a 0);
        Hashtbl.clear seencnids;
        Hashtbl.clear seencnidsprod;
        
    end
     
   method printfnlen (b:string)(a:int): unit =
   begin
      let is_devctl = ref 0 in 
      tot_len := !tot_len + a; 
      begin
(*
        try
          let ret_str = Hashtbl.find  devctl_fns (b) in
         begin 
		is_devctl := 1;
                fn_len_data := !fn_len_data^Printf.sprintf "%s %d %d %d " b a !is_ioctl !is_devctl;
		Printf.fprintf stderr "Found %s.\n >>%s\n\n\n" b !fn_len_data;
         end
         with Not_found -> ();

 *)
                           
        fn_len_data := !fn_len_data^Printf.sprintf "%s %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d " b a
         (self#is_ioctl b) (self#is_init b) (self#retcloc b)  (self#is_cleanup b) (self#is_pm b) (self#is_err b) (self#is_config b) (self#is_proc b) (self#is_modpm b) (self#is_devctl b) (self#ttd b) (self#ttk b) (self#is_allocator b) (self#is_core b) (self#has_sync b) (self#is_process b) (self#has_event b) (self#has_thread b) (self#is_dma b) (self#is_bus b) (self#ttd_count b) (self#sync_count b) (self#alloc_count b) (self#ttk_count b) (self#is_port b) (self#is_mmio b) (self#is_intr b);  
     end
   end

  method addtoport (b:string) : unit =
    begin
      Hashtbl.add port_fns b "";
    end

  method addtommio (b:string) : unit =
    begin
      Hashtbl.add mmio_fns b "";
    end

  method addtodma (b:string) : unit =
    begin
      Hashtbl.add dma_fns b "";
    end
      
  method addtottd (b:string) : unit =
    begin
      Hashtbl.add ttd_fns b "";
    end

  method addtosync (b:string): unit =
    begin
      Hashtbl.add sync_fns b "";
    end

  method addtobus (b:string): unit =
    begin
      Hashtbl.add bus_fns b "";
    end
      
  method addtoevent (b:string): unit =
    begin
      Hashtbl.add event_fns b "";
    end
      
  method addtothread (b:string): unit =
    begin
      Hashtbl.add thread_fns b "";
    end

  method addtoalloc (b:string) : unit =
   begin
    Hashtbl.add allocator_fns b "";
   end 

  method addtottk (b:string): unit =
    begin
      Hashtbl.add ttk_fns b "";
    end

     
   (* Visits every function  Pass 2*)
   method vfunc (f: fundec) : fundec visitAction =
   begin
     (* Build CFG for every function.*) 
     (Cil.prepareCFG f);
     (Cil.computeCFGInfo f false);  (* false = per-function stmt numbering,
                                             true = global stmt numbering *)

      (* Printf.fprintf stderr "\n Saw function  %s  Descending  end %d start %d
       \n " curr_func.svar.vname !last_fun_stmt !first_fun_stmt;  *)
     if !last_fun_stmt > 0 then (
        let fn_len = ref 0 in
          (* Printf.fprintf stderr "\n%s:size %d %d =%d:\n"  curr_func.svar.vname !last_fun_stmt !first_fun_stmt (!last_fun_stmt - !first_fun_stmt); *)
          fn_len := (!last_fun_stmt - !first_fun_stmt) + 2;
          Hashtbl.add fn_start_end curr_func.svar.vname !fn_len; 
     );

     Hashtbl.add ttd_calls curr_func.svar.vname !fn_dev_calls;
     Hashtbl.add ttk_calls curr_func.svar.vname !fn_kern_calls;
     Hashtbl.add sync_calls curr_func.svar.vname !fn_sync_calls;
     Hashtbl.add alloc_calls curr_func.svar.vname !fn_alloc_calls;
     fn_dev_calls:=0;
     fn_kern_calls:=0;
     fn_alloc_calls := 0;
     fn_sync_calls :=0;
     curr_func <- f; (*Store the value of current func before getting into
                       deeper visitor analysis. *)
     first_fun_stmt := !currentLoc.line;

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
       
        for i = 0 to (List.length f.globals) - 1 do
          let curr_g = (List.nth f.globals i) in
          self#initial_filter curr_g;
	 done;

        List.iter self#addtottd device_fns;
        List.iter self#addtodma dmaio_fns;
        List.iter self#addtoport portio_fns;
        List.iter self#addtommio mmio_functions;
        List.iter self#addtoalloc alloc_fns;
        List.iter self#addtottk kernel_fns; 
         
        List.iter self#addtosync sync_functions;
        List.iter self#addtosync thread_functions; 
        List.iter self#addtothread thread_functions;
        List.iter self#addtoevent event_functions;
        List.iter self#addtobus bus_functions;
        

       (* 
        let cg = computeGraph f in
          Hashtbl.iter self#printcumlen cg;
        
       *)

                
        (* Start the visiting *)
        visitCilFileSameGlobals (self :> cilVisitor) f; 

        Printf.fprintf stderr "---------------DRIVER STUDY----------------------\n";
        (* Calculate the function length for the last fn *)
        let fn_len = ref 0 in
          fn_len := (!last_fun_stmt - !first_fun_stmt) + 2;
          Hashtbl.add fn_start_end curr_func.svar.vname !fn_len;

          Hashtbl.add ttd_calls curr_func.svar.vname !fn_dev_calls;
          Hashtbl.add ttk_calls curr_func.svar.vname !fn_kern_calls;
          Hashtbl.add sync_calls curr_func.svar.vname !fn_sync_calls;
          Hashtbl.add alloc_calls curr_func.svar.vname !fn_alloc_calls;

          fn_dev_calls:=0;
          fn_kern_calls :=0;
          fn_sync_calls :=0;
          fn_alloc_calls := 0;
          (* At this point all function lengths are calculated *)
 
        Hashtbl.add init_fns "init_module" "module_init";
        Hashtbl.add cleanup_fns "cleanup_module" "module_exit";


        (*
        
        List.iter self#addtottd device_fns;
        List.iter self#addtodma dmaio_fns;
        List.iter self#addtoalloc alloc_fns;          
        List.iter self#addtottk kernel_fns;  
        List.iter self#addtosync sync_functions;
        List.iter self#addtothread thread_functions;
        List.iter self#addtoevent event_functions;
        List.iter self#addtobus bus_functions;

        *)  
        let cg = computeGraph f in  
        Hashtbl.iter self#printcumlen cg; 
        
        Hashtbl.iter self#printfnlen fn_start_end;
	(* Hashtbl.iter self#printioctlfns ioctl_fns;  *)

       
        Printf.printf "len %d ids %d hr %d %s %s %d %d %s fns %s\n" (!tot_len) !pci_chipsets self#has_recovery !driver_type !driver_ops !cfactor !modparams !bus_type !fn_len_data; 
        Printf.fprintf stderr "len:%d ids %d hr %d %s %s c:%d b:%d %s fns %s\n" (!tot_len) !pci_chipsets self#has_recovery !driver_type !driver_ops !cfactor !modparams !bus_type !fn_len_data;
        
      (* 
        if (gen_call_info = 1) then     (
          Printf.fprintf stderr "fns %s\n" !call_info_data;
          Printf.printf "fns %s\n" !call_info_data;
        );
 *)      
        
        (* Print all function name-length pairs   
        Hashtbl.iter self#printfnlen fn_start_end;
        *)
        Printf.printf "\n";

    end 
end    
    

(*******************************
* Init
********************************)

(*Toplevel function for our Beefy Analysis *)
let dobeefyanalysis (f:file)  : unit = 	
  begin
      (* Printf.printf "#### Execution time: %f\n" (Sys.time()));
      *)
    
      let initVisitor : initialVisitor = new initialVisitor in
      initVisitor#top_level f;
  
     
      let driVisitor : driverVisitor = new driverVisitor in
      driVisitor#top_level f;
    
  end

(* The feature description for the drivers module *)  
let feature : featureDescr = 
  { fd_name = "drivers";              
    fd_enabled = ref false;
    fd_description = "Device Driver Security Analysis";
    fd_extraopt = [];
    fd_doit = dobeefyanalysis;
    fd_post_check = true      (*What does this do?? *) 
  } 

  
