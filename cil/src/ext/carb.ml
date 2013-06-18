open Cil
open Str
open Pretty
open Ptranal

let tickval_exp = (integer 200)

(* Used to check for dirtyness that may impede liveness.
 *)
let bad_functions: string list =
    [ "ioread8";
      "ioread16";
      "ioread16be";
      "ioread32";
      "ioread32be";
(*      "iowrite8";
      "iowrite16";
      "iowrite16be";
      "iowrite32";
      "iowrite32be"; *)
      "ioread8_rep";
      "ioread16_rep";
      "ioread32_rep";
 (*     "iowrite8_rep";
      "iowrite16_rep";
      "iowrite32_rep" ;*)
      "ioport_map";
      "ioport_unmap";
      "pci_iomap";
  (*    "pci_iounmap"; *)
      "readl";
      "readw";
      "inb_p";
      "inw_p";
      "inl_p";
      "inb_local";
      "inw_local";
      "inl_local";
      "ioread8_rep";
      "ioread16_rep"; 
      "ioread32_rep";  
   (*   "writel"; *)
      "inb";
   (*   "outb";*)
      "inw";
(*      "outw"; *)
      "inl";
    (*  "outl"; *)
      "readb";
 (*     "writeb"; *)
      "insw";
      "insb";
      "insl";
  (*    "outsw";
      "outsb";
      "outsl"; *)

      "ioremap";
      "ioremap_nocache";
   (*   "dma_map_page";
      "dma_unmap_page";  *)
      "dma_alloc_coherent";
 (*     "dma_free_coherent";
      "pci_free_consistent"; *)
      "pci_map_consistent";
      "mem_request_regions";
      "ioport_map";






      "fi_ioread8";
      "fi_ioread16";
      "fi_ioread16be";
      "fi_ioread32";
      "fi_ioread32be";
(*      "fi_iowrite8";
      "fi_iowrite16";
      "fi_iowrite16be";
      "fi_iowrite32";
      "fi_iowrite32be"; *)
      "fi_ioread8_rep";
      "fi_ioread16_rep";
      "fi_ioread32_rep";
 (*     "fi_iowrite8_rep";
      "fi_iowrite16_rep";
      "fi_iowrite32_rep" ;*)
      "fi_ioport_map";
      "fi_ioport_unmap";
      "fi_pci_iomap";
  (*    "fi_pci_iounmap"; *)
      "fi_readl";
      "fi_readw";
      "fi_inb_p";
      "fi_inw_p";
      "fi_inl_p";
      "fi_inb_local";
      "fi_inw_local";
      "fi_inl_local";
      "fi_ioread8_rep";
      "fi_ioread16_rep"; 
      "fi_ioread32_rep";  
   (*   "fi_writel"; *)
      "fi_inb";
   (*   "fi_outb";*)
      "fi_inw";
(*      "fi_outw"; *)
      "fi_inl";
    (*  "fi_outl"; *)
      "fi_readb";
 (*     "fi_writeb"; *)
      "fi_insw";
      "fi_insb";
      "fi_insl";
  (*    "fi_outsw";
      "fi_outsb";
      "fi_outsl"; *)

      "fi_ioremap";
      "fi_ioremap_nocache";
   (*   "fi_dma_map_page";
      "fi_dma_unmap_page";  *)
      "fi_dma_alloc_coherent";
 (*     "fi_dma_free_coherent";
      "fi_pci_free_consistent"; *)
      "fi_pci_map_consistent";
      "fi_mem_request_regions";
      "fi_ioport_map";

      (************************)
      (* MJR bonus functions: *)
      (************************)

      (* Added b/c it's not inlined like the normal pci_alloc_consistent *)
      "fi_pci_alloc_consistent";
    ];;

(* Used to check registration of interrupt handlers. *)
let iNTR_STRING: string = "request_irq";;

let zero64 = (Int64.of_int 0);;
let zero64Uexp = Const(CInt64(zero64,IUInt,None));;

let gen_line_nos: int = 0;;


(* Used to check presence of system halting functions. *)
let halting_fns: string list = [ "panic"; "BUG"; "BUG_ON"; "assert" ] ;;

(* Used to check for contamination. *)
let bad_memory_ptrs : string list =
    [  "ioremap"; "ioremap_nocache";
    "inb"; "inl"; "inw"; "outw"; "inb"; "outb"; "insw"; "outsw"; "insl";
    "outsl"; "insb"; "outsb"; "readl"; "writel"; "readb"; "writeb";
    ];;

let halt_count: int ref = ref 0;;

let dma_taint: int ref = ref 0;;

let error_line_nos : string list ref = ref [];;

let def_interrupt_fns: string list ref =
    ref [];;
let intr_correct : int ref = ref 0;;
let intr_found : int ref = ref 0;;

let intr_serviced: string list = ["writel"; "schedule_work"; "mod_timer";
"outb";];;

let dummy_stmt_list: stmt list =
    [dummyStmt;
    ];;


let more_bad_functions: string list =
    [   "ioremap";
        "ioremap_nocache";
    ];;

 (* The names of functions with contaminated return values *)
  let funcs_with_cont_return = ref [];;
   

(*To avoid cache coherency problems, right before starting a DMA transfer from
* the RAM to the device, the driver should invoke
* pci_dma_sync_single_for_device() or dma_sync_single_for_device(), which flush,
* if necessary the cache lines corresponding to the DMA buffer. Similarly, a
* device driver should not access a memory buffer right after the end of a DMA
* transfer from the device to the RAM: instead, before reading the buffer, the
* driver should invoke pci_dma_sync_single_for_cpu or dma_sync_single_for_cpu()
* ,which  invalidate, if necessary, the corresponding hardware cache lines. This
* is not relevant in x86 architecture because the coherency of hardware caches
* and DMAs is maintained by the hardware.
*) 
let dma_bad_functions: string list =
    [   "dma_map_page";
	"dma_map_single";
	"pci_map_single";
        "printk";
        "memcpy";
        "memzero";
        "kmalloc";
(*        "dma_unmap_page";
        "dma_map_single";
        "dma_unmap_single";
        "dma_alloc_coherent";
        "dma_free_coherent";
        "pci_free_consistent";
        "pci_map_consistent";
        "pci_map_single";
        "pci_free_single";
*)
    ];;

let mem_mgmt_fns string list =
    [     "kmalloc";
          "kmem_alloc";
          "kfree";
          "kcalloc";  
          "kzalloc"; 
          "kmem_cache_create";
          "kmem_cache_alloc";
          "kmem_cache_shrink";
          "kmem_cache_free";
          "vmalloc";
          "vfree";
    ];; 

let dma_bad_third_argument: string list = 
    [   "dma_alloc_coherent";
        "dma_pool_alloc";
        "dma_pool_free";
    ];;

let dma_bad_second_argument: string list =
    [   "dma_map_single";
        "dma_sync_single_for_cpu"; 
        "dma_sync_single_for_device";
    ];;

let dma_bad_fourth_argument: string list =
    [   "dma_free_coherent";
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
                        

(* Compare input string to check if its a bad function *)
   let isbad (str : string) (sl: string list): int =
   begin

       (* Printf.fprintf stderr "Entered isbad: %s.\n" str; *)
     let rc = ref 0 in
     for i = 0 to (List.length bad_functions) - 1 do
        let bad_string = (List.nth bad_functions i) in
          if (String.compare bad_string str = 0) then
            rc := 1;
     done;

     for i = 0 to (List.length sl) - 1 do
         let bad_string = (List.nth sl i) in
         if (String.compare bad_string str = 0) then
             rc := 1;
     done;

     for i = 0 to (List.length !funcs_with_cont_return) - 1 do
         let bad_string = (List.nth !funcs_with_cont_return i) in
         if (String.compare bad_string str = 0) then
             rc := 1;
     done;

     !rc
   end
  



(* Compare input string to check if its a contaminated function used for array
 * indexing analysis. *)
   let iscontaminated (str : string) (sl: string list): int =
   begin

       Printf.fprintf stderr "Checking isbad: %s.\n" str;
     let rc = ref 0 in
(*     for i = 0 to (List.length bad_memory_ptrs) - 1 do
        let bad_string = (List.nth bad_memory_ptrs i) in
        Changed on 01/07/2009 to since bad_memory_ptrs is 
        a subset of bad_functions.
        *)

        for i = 0 to (List.length bad_functions) - 1 do
         let bad_string = (List.nth bad_functions i) in
          if (String.compare bad_string str = 0) then
            rc := 1;
     done;

     for i = 0 to (List.length sl) - 1 do
         let bad_string = (List.nth sl i) in
         if (String.compare bad_string str = 0) then
             rc := 1;
     done;

     for i = 0 to (List.length !funcs_with_cont_return) - 1 do
         let bad_string = (List.nth !funcs_with_cont_return i) in
         if (String.compare bad_string str = 0) then
             rc := 1;
     done;

     !rc
   end

(* Compare the input string to check if its an interrupt registration. *)
   let isinterruptreg (str:string) : int = 
    begin
        Printf.fprintf stderr "Checking interrupt registration : %s.\n" str;
        let rc = ref 0 in
        if (String.compare iNTR_STRING str = 0) then
            rc := 1;
        
        !rc
    end

 (* Compare input string to check if its a halting function *)
   let ishalting (str : string) : int =
    begin
      Printf.fprintf stderr "Checking ishalt: %s.\n" str;
      let rc = ref 0 in
        for i = 0 to (List.length halting_fns) - 1 do
          let halt_string = (List.nth halting_fns i) in
            if
              (String.compare halt_string str = 0) then
            rc := 1;
        done;
        !rc
    end

  (* Compare input string to check if its a DMA function *)
    let isdmacall (str : string) : int =
     begin
      Printf.fprintf stderr "Checking isdma: %s.\n" str; 
      let rc = ref 0 in
        for i = 0 to (List.length dma_bad_functions) - 1 do 
          let dma_string = (List.nth dma_bad_functions i) in
            if
              (String.compare dma_string str = 0) then
             rc := 1;
        done;
        !rc
     end



(* Convert varinfo to lval *)
   let lvalify_varinfo (v: varinfo) : lval = (Var(v),NoOffset)   

(*********Auxilary helper functions end ***********)


(* Dirty variable hashtable for checking liveness. These variables are marked
 * dirty for the scope of the function. We can also limit them to the scope of a
 * block but dirtyness usually spans across blocks.
 * *)

let dirrrty : (string*string, string) Hashtbl.t = (Hashtbl.create 15);;

let when_dirrrty :(string*string, int) Hashtbl.t = (Hashtbl.create 15);;

(* To check if pointers have already been checked before *)
let hist_dirty : (string*string, string) Hashtbl.t = (Hashtbl.create 15);;

(* To check if arrays have already been checked before *)
let hist_array_dirty : (string*string, string) Hashtbl.t = (Hashtbl.create 15);;

(* To to npd analysis *)
let ptr_seen_before : (string*string, string) Hashtbl.t = (Hashtbl.create 15);;

(* To check if a pointer has already been checked against null *)
let hist_if_ptr_check : (string*string, int) Hashtbl.t = (Hashtbl.create 15);;

(* To check if an infinite loop has untainted a tainted variable. *)
let hist_infinite_dirty : (string*string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Contaminated addresses/variables coming from a device. May not be used for 
 * array indexing etc.
 *)
let contaminated : (string*string, string) Hashtbl.t =(Hashtbl.create 15);;

let locateexplist: (block ref, exp list) Hashtbl.t =(Hashtbl.create 15);; 

(* The initial visitor for preprocessing. Fills the dirrty and contaminated hash
 * table in this pre-scan step. *)
class initialVisitor = object (self) 
    inherit nopCilVisitor

 val mutable curr_func : fundec = emptyFunction "temp";
 val mutable block_count = ref 0;
(* Temporary list on a per-function basis to check variables that point to bad
 * functions.
 *)
 val mutable temp_bad_functions: string list =
     [
     ];

 val mutable temp_cont_functions: string list =
     [
     ];

   
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

   method isbad_exp(e:exp) : int =
    begin
        let lvalue_list = ref [] in
        let ret_val = ref 0 in
        lvalue_list := self#find_lvals_exp e;
            for i = 0 to (List.length !lvalue_list) -1 do
                let lvalue = (List.nth !lvalue_list i) in
                let (host, offset) = lvalue in
                (match host with
                | Var (vi) ->
                        begin
			    Printf.fprintf stderr "\n[Checking  vi.vname %s to add %s.]\n "  vi.vname (exp_to_string e);
                            if (isbad vi.vname temp_bad_functions = 1) then
                              begin
                                (* If tmp=*bad()*, tmp is bad *)  
                                temp_bad_functions <-
                                    vi.vname::temp_bad_functions;
                                 (* If tmp() { *bad()*} tmp is bad *)    
                                temp_bad_functions <-
                                    curr_func.svar.vname::temp_bad_functions;
                                  Hashtbl.add dirrrty
                                  (vi.vname,curr_func.svar.vname) (exp_to_string
                                  e);
                                  ret_val := 1;
                              end
                        end 
                | _ -> ();
                )
            done;
        !ret_val;
    end
        

   method iscont_exp(e:exp) : int =
        begin
            let lvalue_list = ref [] in
            let ret_val = ref 0 in
            lvalue_list :=
                self#find_lvals_exp e;
                for i = 0 to (List.length !lvalue_list) -1 do
                    let lvalue = (List.nth !lvalue_list i) in
                    let (host, offset) = lvalue in
                    (match host with
                | Var (vi) ->
                        begin
                            if (iscontaminated vi.vname temp_cont_functions = 1) then
                              begin
                                  Printf.fprintf stderr "\nADDING to CONT: %s
                              and %s\n" vi.vname curr_func.svar.vname;
                                (* If tmp=*cont()*, tmp is cont *)
                                temp_cont_functions <- vi.vname::temp_cont_functions;
                                (* If * tmp() * { *bad()*} tmp is cont *)
                                temp_cont_functions <- curr_func.svar.vname::temp_cont_functions;
                                 Hashtbl.add contaminated (vi.vname,curr_func.svar.vname)
                                      (exp_to_string e); 
                                 ret_val := 1;
                              end
                        end
                |_ -> ();
                    )
                done;
                !ret_val;
        end

   
   (* Visits every "instruction" *)
   method inst_process (i: instr) : unit =
   begin
       let lvalue_list = ref [] in
        match i with 
         Call(lvalue_option,e,el,loc) -> 
        begin

              lvalue_list := self#find_lvals_instr i;
             (* Printf.fprintf stderr "::Called for %s (%s).\n" (instr_to_string i) 
            (exp_to_string e); *) 
            for i = 0 to (List.length !lvalue_list) - 1 do
                let lvalue = (List.nth !lvalue_list i) in
                let (host, offset) = lvalue in
                (match host with
                | Var  (vi) ->
                        begin
                        (* Printf.fprintf stderr
                        "DIRTY CHECK:Call found with exp %s which is %d with var %s" (exp_to_string e)
                        (isbad (exp_to_string e) temp_bad_functions) vi.vname;
                        *)
                        if (self#isbad_exp e  = 1) then
                            begin
                                temp_bad_functions <-
                                    vi.vname::temp_bad_functions;
                                 Printf.fprintf stderr "Adding TO BAD: %s %d.\n"
                                 vi.vname !block_count;
                                Hashtbl.add dirrrty
                                (vi.vname,curr_func.svar.vname) (exp_to_string e);
				Hashtbl.add when_dirrrty (vi.vname, curr_func.svar.vname) loc.line;
                            end;

                       (*      Printf.fprintf stderr 
                             "CONT CHECK:Call found with exp %s which is %d with var %s" (exp_to_string e)
                             (iscontaminated (exp_to_string e) temp_cont_functions) vi.vname;
			*)
                        
                        if (iscontaminated (exp_to_string e) temp_cont_functions  = 1) then
                            begin
                                temp_cont_functions <-
                                    vi.vname::temp_cont_functions;
                                 Printf.fprintf stderr "Adding TO COTAMINATED: %s %d.\n"
                                 vi.vname !block_count;
                                Hashtbl.add contaminated
                                (vi.vname,curr_func.svar.vname) (exp_to_string e);
                            end;
                        
                        if (isinterruptreg (exp_to_string e) = 1) then
                            begin
                                Printf.fprintf stderr "*** Interrupt Registration found.***";
                                
                                let curr_exp = (List.nth el 1) in
                                let curr_flags = (List.nth el 2) in
                                  Printf.fprintf stderr "Args? %s \n Flags %s.\n"
                                (exp_to_string curr_exp) (exp_to_string curr_flags);
                                def_interrupt_fns := (exp_to_string curr_exp)::!def_interrupt_fns;
                                intr_found := 1;
                            end;
                            
                        end
                | _ -> ();
                )
            done;
        end

        | Set(lvalue_location,e, loc) ->
        begin
            lvalue_list := self#find_lvals_instr i;
            Printf.fprintf stderr "[In Set %d.]\n" (List.length !lvalue_list); 
            for i = 0 to (List.length !lvalue_list) - 1 do
                let lvalue = (List.nth !lvalue_list i) in
                let (host, offset) = lvalue in
                (match host with
                | Var  (vi) ->
                        begin
                             (* Printf.fprintf stderr "Checking %s.\n" vi.vname;
                              * *)
                             if (self#isbad_exp e  = 1) then
                                     begin
                                         Hashtbl.add dirrrty
                                         (vi.vname,curr_func.svar.vname)
                                         (exp_to_string e);
                                         temp_bad_functions <-
                                             vi.vname::temp_bad_functions;
					 Hashtbl.add when_dirrrty (vi.vname, curr_func.svar.vname) loc.line;
                                          (* Printf.fprintf stderr "Adding TO SETT BAD: 
                                             %s %s.\n" vi.vname (exp_to_string e);*) 
                                     end;

                              if (self#iscont_exp e  = 1) then      
                                 begin
                                    Hashtbl.add contaminated
                                    (vi.vname,curr_func.svar.vname)
                                   (exp_to_string e);
                                  temp_cont_functions
                                  <-vi.vname::temp_cont_functions;
                                 Printf.fprintf stderr "Adding TO CONTAMINTED:
                                     %s.\n" vi.vname;
                                 end; 
                        end
		
		 
                | _ -> ();
                )
            done;
            
        end

     | _ -> (); 
       
   end

    (* Visits every "instruction" *)
     method vinst (i: instr) : instr list visitAction =
     begin
        self#inst_process i;
        DoChildren;
     end

     (* Visits every "statement" *)
     method vstmt (s: stmt) : stmt visitAction =
     begin
        match s.skind with
	
        | Return(Some(e),_) ->
          begin
             if (self#isbad_exp e = 1) then
	(               funcs_with_cont_return
                         := (List.append
                         !funcs_with_cont_return
                         [curr_func.svar.vname]);
			Printf.fprintf stderr "Added %s to tainted.\n" curr_func.svar.vname;
	);
                         DoChildren;
          end
          
       |  Instr(ilist) ->
            begin
                let halting_found = ref 0 in
                let shadow_call = ref dummyStmt in  
                for j = 0 to (List.length ilist) - 1 do
                  let cur_instr = (List.nth ilist j) in
                    match cur_instr with
                    | Call(lvalue_option,e,el,loc) -> 
                          if (ishalting (exp_to_string e) = 1) then
                              begin
                                  let shadow_call_fundec = (emptyFunction
                                  "shadow_ioctl_recover" ) in
                                  let args_list = ref [] in
                                  (* let shadow_call =
                                      mkStmtOneInstr(Call(lvalue_option,
                                      (expify_fundec shadow_call_fundec),!args_list, loc)) in
                                  *)
                                  let changed_stmt =  mkStmtOneInstr (Call(lvalue_option,
                                  (expify_fundec shadow_call_fundec),!args_list,
                                  loc)) in
                                  shadow_call := changed_stmt;      
                                  halting_found := 1;   
                                  Printf.fprintf stderr "***Halt the party found.***";
				  halt_count := !halt_count + 1;
                              end
                    |_ -> ();
                done;   
                (* Uncomment this to induce a call to shadow_recovery.  
                if (!halting_found = 1) then 
                    ChangeTo (!shadow_call)
                else    
                *)    
                    DoChildren;    
                
            end 
       | _ -> DoChildren;
     end

     (* Visits every block *)
     method vblock (b: block) : block visitAction =
     begin
         block_count := !block_count + 1;
        DoChildren;
     end

     (* Visits every function *)
     method vfunc (f: fundec) : fundec visitAction =
     begin
        (* Empty the temp bad list *)
         temp_bad_functions <- []; 
        block_count := 0;
        (* Empty the temp cont list *)
        temp_cont_functions <- [];
        
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

(* The starting point Visitor *)
class driverVisitor = object (self) (* self is equivalent to this in Java/C++ *)
    inherit nopCilVisitor  
    val mutable curr_func : fundec = emptyFunction "temp"; 
    val mutable curr_block : block = (mkBlock dummy_stmt_list);
    val mutable glob_ctr : int = 0;
    val mutable mem_deref_bugs : int = 0;
    val mutable per_fun : fundec list = [(emptyFunction "temp") ;]; 
    val mutable per_fun_ctr : stmt list = dummy_stmt_list;
    val mutable num_array_checks_added = 0;
    val mutable num_bad_ptr_lvals = 0;
    val mutable return_on_device_error = 0;
    val mutable locate_ret_call_count = 0;
    val mutable lval_corrupt = ref 0;
    val mutable ret_seen = 0;
    val mutable pk_count = 0;
    val mutable pk_in_rtc = 0;
    val mutable brk_if = ref zero64Uexp;
    val mutable last_instr_loc = 0;
    val mutable ret_pk_count = 0;
    val mutable last_device_call_loc = 0;
    val mutable goto_exp_flip = ref 0;
    val mutable last_array_device_call_loc = 0;
    val mutable report_timeout_counter : int = 0;
    val mutable array_mask_set = ref "";
    val mutable done_gen = ref 0; (* Variable to check if ticks code has already
                                   * been generated in a block *)
    val mutable done_ret_gen = ref 0;
    val mutable block_count = ref 0; (* Variable to maintain block uniqueness of
                                      * badness. Not used *yet*, not sound but
                                      * complete.
                                      *)
    val mutable instrs_of_loop = ref 0; (* Variable to signify we are
                                         *  processing instructions inside a loop. 
                                         *   Used to find counters in loop. *)

    val mutable done_add_ret = ref 0; (*Used to see if report code added or not. *) 

    val mutable temp_bad_functions: string list =
        [
    ];


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

   method isbad_expr (e:exp): int = 
   begin
     let str_list = self#find_lvals_exp e in
     let found = ref 0 in
     for i = 0 to List.length str_list -1  do
     if (!found < 0 ) then (
	let cur_str = List.nth str_list i in
        found := isbad cur_str [];
      );
    done;
     !found;
    end 


   method find_lvals_exp (e:exp ) : string list = 
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
    
   method find_lvals_exp_array (e:exp ) : string list =
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
        | BinOp (b, e1, e2, typ) -> if ((b != LAnd) && (b != BAnd)) then (
                (self#find_lvals_exp e1)@(self#find_lvals_exp e2)) else [];
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
		Printf.fprintf stderr "and op in array.\n";
		let str_list = ref [] in 
		if ((b = LAnd) || (b = BAnd) ) then (Hashtbl.add hist_array_dirty ((exp_to_string e) , curr_func.svar.vname) "yes"; ) 
		else ( 
		(*
		  if ((b= Shiftlt) || (b = Shiftrt)) then (
			try 
	        	let ret_str = (Hashtbl.find hist_array_dirty ((exp_to_string e1) ,curr_func.svar.vname)) in
        	        begin	str_list := self#find_lvals_exp e2; end
        	
        		with Not_found -> [];
		

			try 
		        let ret_str = (Hashtbl.find hist_array_dirty ((exp_to_string e2) ,curr_func.svar.vname)) in
        	         begin       self#find_lvals_exp e1;  end
                
                	with Not_found -> [];
	
		); 
		*)		
               str_list := (self#find_lvals_exp_array e1)@(self#find_lvals_exp_array e2);  
		);
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

 (* Finds all the array lvals in a CIL expression (hopefully). 
   *  Do we need to add Const here ?? FIXME 
   *  *)
   method find_array_lval_list_from_exp (e:exp) : lval list =
   begin
     match e with
     | Lval(lv) -> 
       begin 
	match lv with 
	| (Var(var),_) ->
	 begin
           match var.vtype with
	   | TArray(_,_,_) -> [lv];
	   | _ -> [];
	 end
	| _ -> [];
       end
     | AddrOf(lv) -> 
	begin 
        match lv with 
        | (Var(var),_) ->
         begin   
           match var.vtype with
           | TArray(_,_,_) -> [lv];
           | _ -> [];
         end     
        | _ -> [];
       end
     | BinOp (b, e1, e2, typ) -> (  
                ( (* Printf.fprintf stderr "ERE BINOP.\n";*)
		if ((b = LAnd) || (b = BAnd) ) then ( 
                Printf.fprintf stderr " ADDING %s %s\n\n" (exp_to_string e1) (!array_mask_set);
		let str_list = self#find_lvals_exp e in
		for i = 0 to List.length str_list -1 do
		let cur_e = List.nth str_list i in
			Hashtbl.add hist_array_dirty ((cur_e) , curr_func.svar.vname) "yes";
		done;
		Hashtbl.add hist_array_dirty (!array_mask_set, curr_func.svar.vname) "yes"; 
		);
		self#find_array_lval_list_from_exp e1)@(self#find_array_lval_list_from_exp e2);) 
     | UnOp (op, e, typ) ->
                (self#find_array_lval_list_from_exp e);
     | CastE (typ, e) -> 
                (self#find_array_lval_list_from_exp e);
     | SizeOfE (e) ->
                (self#find_array_lval_list_from_exp e);
     | AlignOfE(e) ->
                (self#find_array_lval_list_from_exp e);
     | StartOf(lv) ->
        begin 
        match lv with 
        | (Var(var),_) ->
         begin   
           match var.vtype with
           | TArray(_,_,_) -> [lv];
           | _ -> [];
         end     
        | _ -> [];
       end  
     | Const(_) -> ( (*Printf.fprintf stderr"const set %s.\n" !array_mask_set;*)  Hashtbl.add hist_array_dirty (!array_mask_set, curr_func.svar.vname) "yes"; [];)              
     | _ -> [];
   end

 (* Finds all the array lvals in an exp list *)
   method find_array_lval_list_from_exp_list (e_list: exp list) : lval list =
   begin   
        match e_list with 
       | hd_e :: tl_e_list -> (self#find_array_lval_list_from_exp hd_e) @
				(self#find_array_lval_list_from_exp_list tl_e_list);
       | _ -> [];
   end
	  
 (* Finds all the array lvals in a CIL instruction *)
   method find_array_lval_list_from_instr (i: instr) : lval list =
   begin
    match i with
        | Call(lval_option,exp,e_list,l) ->
          begin
	     let e1 = (exp_to_string exp) in
	     (* Printf.fprintf stderr "Found a call to %s.\n" e1; *)
	     last_array_device_call_loc <- -1;
             if (isbad e1 [] == 1) then      (
               	
		match lval_option with
		| Some (lv) ->
	         begin
	        	match lv with
			| (Var(var),_) -> Hashtbl.remove hist_array_dirty (var.vname, curr_func.svar.vname);
			| _ -> Hashtbl.clear hist_array_dirty;
		end
		|_ -> Hashtbl.clear hist_array_dirty;

	       last_array_device_call_loc <- l.line;
               Printf.fprintf stderr "Cleared array hash table.\n"; 
            );
            match lval_option with
            | Some (lv) -> 
	     begin
              match lv with
              | (Var(var),_) -> begin
                match var.vtype with
                | TArray(_,_,_) -> (lv :: (self#find_array_lval_list_from_exp exp) @ 
						(self#find_array_lval_list_from_exp_list e_list););
                | _ -> (self#find_array_lval_list_from_exp exp) @ (self#find_array_lval_list_from_exp_list e_list);
               end
              | _ -> (self#find_array_lval_list_from_exp exp) @ (self#find_array_lval_list_from_exp_list e_list);
             end
	    | _ -> (self#find_array_lval_list_from_exp exp) @ (self#find_array_lval_list_from_exp_list e_list);
           end
        | Set (lv, exp, _) ->
	  begin
            match lv with
	      | (Var(var),_) -> begin
		array_mask_set := var.vname;
		Printf.fprintf stderr "set to %s" !array_mask_set;
		match var.vtype with
		| TArray(_,_,_) -> (lv :: (self#find_array_lval_list_from_exp exp); )
                | _ -> (self#find_array_lval_list_from_exp exp);
	      end
	      | _ -> (self#find_array_lval_list_from_exp exp);
          end
	| _ -> [];
   end

  (* Find if an lval is contaminated *)
  method is_lval_cont (name: string) : bool = 
  begin
	try
	  let ret_str = (Hashtbl.find dirrrty (name, curr_func.svar.vname)) in
	    begin
		Printf.fprintf stderr 
			"\nContaminated array index (vname, function, contaminated exp): %s, %s, %s\n"
			name curr_func.svar.vname ret_str;	
		true;
	    end
        with Not_found -> false;
  end

  (* Find if any lval in an lval list is contaminated *)
  method is_lval_list_cont (lval_list: string list) : bool =
  begin
	match lval_list with
	| hd_lval :: tl_lval_list -> 
		if (self#is_lval_cont hd_lval) then true
		else (self#is_lval_list_cont tl_lval_list);
	| _ -> false;
  end

  (* Find if an array offset expression is contaminated *)
   method is_exp_cont (e: exp) : bool =
   begin
	let incoming_exp = (exp_to_string e) in
        if (last_array_device_call_loc = 0) then
	(false;)
        else	(
        try (
        let ret_str = (Hashtbl.find hist_array_dirty (incoming_exp ,curr_func.svar.vname)) in
                Printf.fprintf stderr "Array History Match %s.\n" ret_str; 
                false;
        );
        with Not_found -> (
        Hashtbl.add hist_array_dirty (incoming_exp , curr_func.svar.vname) "yes";
	
        let lval_list = (self#find_lvals_exp_with_offset e) in
		(self#is_lval_list_cont lval_list);
	);
	);
   end

  (* Find if an array offset is contaminated *)
  method is_offset_cont (o: offset) : bool =
  begin
	match o with 
	| Index(e,o2) -> (self#is_exp_cont e) || (self#is_offset_cont o2);
	| _ -> false;
  end

  (* Finds all the arrays using contaminated indices in a list of 
    array lvals *)
   method find_cont_array_lvals (lval_list: lval list) : lval list =
   begin
    match lval_list with
    | hd_lval :: tl_lval_list ->
     begin
      match hd_lval with
      | (Var(vinfo), offset) ->
       begin
	if (self#is_offset_cont offset) 
	  then begin
            Printf.fprintf stderr "Contaminated array index access: ";
	    Printf.fprintf stderr "varname: %s, " vinfo.vname;
	    Printf.fprintf stderr "offset: %s\n" (offset_to_string offset);
            hd_lval :: (self#find_cont_array_lvals tl_lval_list);
	  end
	else (self#find_cont_array_lvals tl_lval_list);
       end
      | _ -> (self#find_cont_array_lvals tl_lval_list);
     end
    | _ -> [];
   end                          


    
   (* Find the length of the array lval *)
   method array_lval_length (l: lval) : int = 
   begin
	match l with
        | (Var(vinfo),_) ->
	   begin
	     match vinfo.vtype with
	      | TArray(_,Some(Const(CInt64(i,_,_))),_) ->
                 (Int64.to_int i);
	      | _ -> 0;
           end
	| _ -> 0;
   end

   (* Find the length of each array in a list *)
   method array_lval_list_lengths (l_list : lval list) : int list =
   begin
	match l_list with
        | hd_l :: tl_l_list ->
         begin
 	    (self#array_lval_length hd_l) :: (self#array_lval_list_lengths tl_l_list);
         end
	| _ -> [];
   end

   (* Return an exp that compares the array index to an array upper bound 
	and checks that index is non-negative *)
   method mkOneIfCond (lval: lval) (length: int) : exp =
   begin
	let (_,offset) = lval in
	 match offset with
	 | Index(e,_) -> 
			BinOp(LOr, 
				BinOp(Lt, e, Const(CInt64((Int64.of_int 0),IInt,None)), intType),
				BinOp(Ge, e, Const(CInt64((Int64.of_int length),IInt,None)), intType),
				intType);
	 | _ -> BinOp(Ne, Const(CInt64((Int64.of_int 0),IInt,None)), 
			Const(CInt64((Int64.of_int 0),IInt,None)), intType);
   end

   (* Return an exp list that compares each array index to its upper bound and checks 
      that index is non-negative *)
   method mkManyIfCond(lval_in_list: lval list) (length_in_list: int list) : exp =
   begin
      let cond_list = ref [] in
      let lval_list : lval list ref = ref [] in
      let dlval_list : lval list ref = ref [] in
      let length_list = ref [] in
	(* Remove any arrays with length == 0; these correspond to dynamic arrays,
		still add checks to ensure index is non-negative *)
	for i = 0 to (List.length lval_in_list) - 1 do
                if((List.nth length_in_list i) > 0) then
		 begin
		   lval_list := (List.nth lval_in_list i) :: !lval_list;
		   length_list := (List.nth length_in_list i) :: !length_list;
		 end
		else
		  dlval_list := (List.nth lval_in_list i) :: !dlval_list;
        done;
	(* Create an expression to compare index to array upper bound for each array*) 
        for i = 0 to (List.length !lval_list) - 1 do
		cond_list := (self#mkOneIfCond (List.nth !lval_list i) (List.nth !length_list i)) :: !cond_list;
	done;
	
	for i = 0 to (List.length !dlval_list) - 1 do
		let exp =  expify_lval (List.nth !dlval_list i) in
		cond_list := (UnOp(LNot, exp , typeOf exp)) :: !cond_list; 
	done;

	if ((List.length !cond_list) == 0) then
		cond_list := [BinOp(Ne, Const(CInt64((Int64.of_int 0),IInt,None)), 
				Const(CInt64((Int64.of_int 0),IInt,None)), intType)];	
	(* Combine all exprs into one && expr *)
	let cond = ref (List.nth !cond_list 0) in
		for i = 1 to (List.length !cond_list) - 1 do
		     cond := BinOp(LOr, !cond, (List.nth !cond_list i), intType);
		done;
	        !cond;
   end


   (*Visits every instruction *)
   method vinst (ins: instr) : instr list visitAction =
   begin
     let lv_list = self#find_lvals_instr ins in
     let cur_l = ref 0 in
	
     if ( 1 = 1) then (
     match ins with	
     | Set (lv,ex,loc) -> (* Printf.fprintf stderr "exp is %s.\n" (exp_to_string ex);*) cur_l := loc.line; 
     | Call (Some lv,ex,el, loc) -> cur_l := loc.line;
     | Call (None, ex, el, loc) -> cur_l := loc.line;
     | _ -> ();

     );

     for i = 0 to (List.length lv_list) - 1 do
	let cur_lv = (List.nth lv_list i ) in
	 begin
           match (cur_lv) with (lhost, offset) -> (
           match lhost with
           | Var(vinfo) ->	(
	       if (isPointerType (typeOfLval cur_lv)) then (
	   try
	     let ret_str = (Hashtbl.find dirrrty (vinfo.vname, curr_func.svar.vname)) in
              begin
               	(* Printf.fprintf stderr "Culprit %s %s.\n" vinfo.vname ret_str; *)
		try 
		   let  ret_str = (Hashtbl.find  ptr_seen_before (vinfo.vname, curr_func.svar.vname)) in
	        	num_bad_ptr_lvals <- num_bad_ptr_lvals + 1;
			error_line_nos := !error_line_nos@[(Printf.sprintf "npa:%d"!cur_l)];
	 	with Not_found -> Hashtbl.add ptr_seen_before (vinfo.vname, curr_func.svar.vname) "yes";	
              end
	      with Not_found -> ();
	   )
	   )
	  |_ -> ();
	)
         end
     done;



     (* 1. Check here if the instruction is a halting instruction. Replace it
      * with a call to the recovery function.
      *)
     (* 2. Check if we are processing the interrupt handler and there is a call
      * to interrupt handler *)
     for i = 0 to (List.length !def_interrupt_fns) - 1 do
         (* Printf.fprintf stderr "Checking for ISR.\n"; *)
         let dci = (List.nth !def_interrupt_fns i) in
         let match_regexp = regexp (".*"^curr_func.svar.vname^".*") in    
         if (Str.string_match match_regexp dci 0) = true  then
           begin
            (* Printf.fprintf stderr "Before Checking for danger %s" (instr_to_string
            ins); *)
            match ins with
                Call(lval_option,exp, exp_list,  _) ->
                  begin
                    for k = 0 to (List.length intr_serviced) - 1 do
                        let cur_intr_ser = (List.nth intr_serviced k) in
                        if (String.compare (exp_to_string exp) cur_intr_ser = 0)
                        then ( 
                            Printf.fprintf stderr "ISR is correct.\n"; 
                            intr_correct := 1;
                        )
                    done;
                        
                        if (!intr_correct = 0) then (
                            if ((isbad (exp_to_string exp) temp_bad_functions) = 1) then (
                                    Printf.fprintf stderr "ISR is dangerous.\n";
                                    (* Printf.printf "ISR is dangerous.\n"; *)
                                )
                        )
                     
                  end
               |_ -> ();
           
         (* Here we check if interrupt is not serviced then we should not be
          * accessing the device 
         Printf.fprintf stderr "Checking for danger 1.\n";
         if (!intr_correct = 0) then ( 
             Printf.fprintf stderr "Checking for danger %s" (instr_to_string ins);
              match ins with 
               Call (lval_option, exp, exp_list, _) ->
                begin
                  if ((isbad (exp_to_string exp) temp_bad_functions) = 1)
                  then  (
                    Printf.fprintf stderr "ISR is dangerous.\n";
                  );
               end
             |_ -> ();
         ); 
         *)
         end
     done;

     DoChildren;
   end

  method iscounter (s: string) (s2: string list) : int =
  begin
      let  rc = ref 0 in 
      for i = 0 to (List.length s2) - 1 do
         begin
           let cur_str = (List.nth s2 i) in
           if ((String.compare s cur_str) = 0) then
               rc := 1;
         end
      done;
      !rc;
  end
             
  method convert_ctrs_alerts (b: block) (s: string list) : int =
  begin
  	if (List.length s > 0) then (
	  let strlist = ref [] in
	  let done_warn = ref 0 in
  	  for i = 0 to (List.length b.bstmts) - 1 do
	  let cur_stmt = (List.nth b.bstmts i) in
	  if (!done_warn = 0) then (
	  match cur_stmt.skind with
	  | If (exp, b1, b2, _) -> (
		strlist := List.append !strlist (self#find_lvals_exp exp);
		for j = 0 to (List.length s) - 1 do
		  let cur_s = (List.nth s j) in
		  for k = 0 to (List.length !strlist) -1 do
		  let cur_str = (List.nth !strlist k) in
		  if ((String.compare cur_s cur_str) = 0) then
			done_warn := 1;
		   done;
		done;
		if (!done_warn = 0) then
			done_warn := (self#convert_ctrs_alerts b1 s);
		if (!done_warn = 0) then	
			done_warn := (self#convert_ctrs_alerts b2 s);

	  );
	  | _ -> ();
	  );
	  done;
	  !done_warn;
	)
	else (1;);
  end 
  
  method locate_dupctrs_in_block (b: block)(s: string list) : string list =
    begin
        let rc_list = ref [] in
        let lvalue_list = ref [] in
        (* Printf.fprintf stderr "Entered locate_dupctrs_in_block.\n"; *)
        for i = 0 to (List.length b.bstmts) - 1 do
            let cur_stmt = (List.nth b.bstmts i) in
            match cur_stmt.skind with
             Instr(ilist) ->
                 begin
                    for j = 0 to (List.length ilist) - 1 do
                        let cur_instr = (List.nth ilist j) in
                         match cur_instr with
			       | Set(lvalue_location,e, loc) ->
  			         begin
			             lvalue_list := self#find_lvals_instr cur_instr;
			             Printf.fprintf stderr "In Set %d.\n" (List.length !lvalue_list);
			             for k = 0 to (List.length !lvalue_list) - 1 do
 		                     let lvalue = (List.nth !lvalue_list k) in
		                     let (host, offset) = lvalue in
		                     (match host with
			                 | Var  (vi) ->
                        			 begin
                        			      Printf.fprintf stderr "Checking %s.\n" vi.vname;
                        			      if (self#iscounter (exp_to_string e) s = 1) then
                        		              begin
                        		                  rc_list := vi.vname::!rc_list;
                        		                 
                        	        	       end;
		                        	  end
                			 | _ -> ();
                			 )
             			 done;
                     end
				 |_ -> ();
			done;
		    end
       | If(e,b1,b2,loc) ->
            begin
              let temp_list = ref [] in
              temp_list := List.append (self#locate_dupctrs_in_block b1 s)
              (self#locate_dupctrs_in_block b2 s);
              rc_list := List.append !temp_list !rc_list;
            end
       | Block (b1) ->
             begin
               rc_list := List.append (self#locate_dupctrs_in_block b1 s)
                 !rc_list;
              end
	   |_->();
        done;
        !rc_list;
    end

   method locate_ctrs_in_block (b: block) : string list =
   begin
       let rc_list = ref [] in
       (* Printf.fprintf stderr "\n[locate_ctrs_in_block called for stats %s.]\n"
       (stmt_list_to_string b.bstmts); *)
       for i = 0 to (List.length b.bstmts) - 1 do
           let cur_stmt = (List.nth b.bstmts i) in
           (* Printf.fprintf stderr "stmt %d.\n" i; *)
           match cur_stmt.skind with
            Instr(ilist) ->
                begin
                    Printf.fprintf stderr "Instr: stmt %d %s.\n" i (stmt_to_string
                   cur_stmt); 
                   for j = 0 to (List.length ilist) - 1 do
                       let cur_instr = (List.nth ilist j) in

                       match cur_instr with
                       | Call (l,e, el, loc) ->
                           begin
                            let str_list = self#find_lvals_exp e in
			     for strctr = 0 to (List.length str_list) -1 do
				let cur_str = (List.nth str_list  strctr) in
                            if ((String.compare (cur_str) "time_after_eq" = 0) || 
				(String.compare (cur_str) "time_before" = 0) ||
				(String.compare (cur_str) "time_before_eq" = 0) ||
				(String.compare (cur_str) "time_after" = 0) ||
				(String.compare (cur_str) "wake_up_interruptible" = 0) ||
				(String.compare (cur_str) "msleep_interruptible" = 0) ||
                                (String.compare (cur_str) "prepare_to_wait" = 0) ||
				(String.compare (cur_str) "finish_wait" = 0)
				) then
                                (rc_list := "__nooks_timer"::!rc_list;);
			    done;
			    for elctr = 0 to (List.length el) - 1 do
			    let  cur_e = (List.nth el elctr) in
			     let str_list = self#find_lvals_exp cur_e in
                               for strctr = 0 to (List.length str_list) -1 do
				let cur_str = (List.nth str_list  strctr) in
				   if (String.compare (cur_str) "jiffies" = 0) 
					then (rc_list := "__nooks_timer"::!rc_list;);
				done;
			    done;	
                          end 
                       | Set (l,e, loc) ->
                         begin
                           match e with
                            BinOp (b, e1, e2, typ) ->
                            begin
                                 match typ with
                                    (* TInt (ik, a) -> *)
                                    |_ ->    
                                    begin    
                                  (* Printf.fprintf stderr "Tint:%s\n"
                                 (instr_to_string cur_instr);
                                   Printf.fprintf stderr "Expressions are %s and
                                   %s ..\n" (exp_to_string e1) (exp_to_string
                                   e2); *) 
                                    Printf.fprintf stderr "\n#NOTE: COUNTER IS %s %s.\n\n"
                                    (exp_to_string e1) (exp_to_string e2);

				   if ((String.compare (exp_to_string e1) "jiffies" = 0) || (String.compare (exp_to_string e2) "jiffies" = 0))
				   then	rc_list := "jiffies" :: !rc_list;
                                   if ( (String.compare (exp_to_string e1) "1" =
                                       0) || (String.compare (exp_to_string e1)
                                       "1U" = 0) || (String.compare (exp_to_string e1) "1L" = 0)  
					|| (String.compare (exp_to_string e1) "1UL" = 0))
                                   then (
                                       rc_list := (exp_to_string e2)::!rc_list;
                                       Printf.fprintf stderr "Added counter smthing";
                                   )
                                   else (
                                       if ((String.compare (exp_to_string e2) "1"
                                       = 0) ||  (String.compare (exp_to_string
                                       e2) "1U" = 0) || (String.compare (exp_to_string e2) "1L" = 0) || (String.compare (exp_to_string e2) "1UL" = 0))
                                       then (
                                           rc_list := (exp_to_string
                                           e1)::!rc_list;
                                            Printf.fprintf stderr "Added counter
                                            smthing %s.\n " (exp_to_string e1);
                                       )
                                        );
                                     end
                                    
                                    (* | _ -> Printf.fprintf stderr "OTHER
                                     * RETURN TYPE"; *)
                            end
                       | CastE (t, ec) -> 
                          begin
                              match ec with 
                                BinOp (b, e1, e2, typ) ->
                                  begin
                                      match typ with
                                          (* TInt (ik, a) -> *)
                                          | _ ->
                                          begin   
					  if ((String.compare (exp_to_string e1) "jiffies" = 0) || (String.compare (exp_to_string e2) "jiffies" = 0))
                                            then rc_list := "jiffies" :: !rc_list;
                                          if ((String.compare (exp_to_string e1) "1" = 0) || (String.compare (exp_to_string e1)
                                       "1U" = 0) || (String.compare (exp_to_string e1) "1L" = 0) || (String.compare (exp_to_string e1) "1UL" = 0))

                                          then (
                                              let clstr = ref "" in
                                              let ipstr = ref "" in
                                              clstr := (exp_to_string e2);
                                              (try 
                                                  ipstr := String.sub !clstr
                                              (String.rindex !clstr ')' + 1)
                                          ((String.length !clstr - 1) -
                                          (String.rindex !clstr ')') );
                                              rc_list := !ipstr::!rc_list;
                                              Printf.fprintf stderr "Added
                                              counter smthing";
                                               with Not_found -> rc_list :=
                                                  (exp_to_string
                                                  e2)::!rc_list; );
                                          )
                                          else (
                                          if ((String.compare (exp_to_string e2) "1" = 0) || (String.compare (exp_to_string e2)
                                       "1U" = 0) || (String.compare (exp_to_string e2) "1L" = 0) || (String.compare (exp_to_string e2) "1UL" = 0))

                                          then (
                                              let clstr = ref "" in
                                              let ipstr = ref "" in
                                              clstr := (exp_to_string e1);
                                              (try 
                                              ipstr := String.sub !clstr
                                              (String.rindex !clstr ')' + 1)
                                           ((String.length !clstr - 1) -
                                           (String.rindex !clstr ')') );
                                              rc_list := !ipstr::!rc_list;
                                              Printf.fprintf stderr "Added counter
                                              smthing %s.\n " (exp_to_string e1);
                                              with Not_found -> rc_list :=
                                                  (exp_to_string
                                                  e1)::!rc_list; );
                                          )
                                          );
                                          end
                                    
                                         (* | _ -> (); *)
                               end
                               | _ -> ();
                          end
                            | _ -> ();
                       end
                       |_ -> ();
                   done;
                end
            | If(e,b1,b2,loc) ->
                    begin
			Printf.fprintf stderr "sae an if\n\n";
			let str_list = self#find_lvals_exp e in
  		          for strctr = 0 to (List.length str_list) -1 do
                           let cur_str = (List.nth str_list  strctr) in
                            if (String.compare (cur_str) "jiffies" = 0)
                                  then (rc_list := "__nooks_timer"::!rc_list;);
   		              if ((String.compare (cur_str) "time_after_eq" = 0) ||
                                (String.compare (cur_str) "time_before" = 0) ||
                                (String.compare (cur_str) "time_before_eq" = 0) ||
                                (String.compare (cur_str) "time_after" = 0) ||
                                (String.compare (cur_str) "wake_up_interruptible" = 0) ||
				(String.compare (cur_str) "msleep_interruptible" = 0) ||
                                (String.compare (cur_str) "prepare_to_wait" = 0) ||
                                (String.compare (cur_str) "finish_wait" = 0)
                                ) then
                                (rc_list := "__nooks_timer"::!rc_list;);

                          done;

                        rc_list := List.append 
                        (self#locate_ctrs_in_block b1) !rc_list;
			rc_list := List.append (self#locate_ctrs_in_block b2) !rc_list;
                    end
            | Block (b1) ->
                    begin
                        rc_list := List.append (self#locate_ctrs_in_block b1)
                        !rc_list;
                    end
(*	    | Return (_,_) -> rc_list := "__nooks_timer"::!rc_list; *)

            |_ -> ();
                done;
       !rc_list;
   end 
   method locatestmt (b : block) (str:string) : exp list ref * string =
   begin
     let goto_label = ref "" in
     let ret_list = ref []  in
     (* let ret_str = ref "" in  *)
     let expr_list = ref[] in
     let e1 = ref zero64Uexp in
     for i = 0 to (List.length b.bstmts) - 1 do
       let cur_stmt  = (List.nth b.bstmts i) in
       match cur_stmt.skind with

         If(exp,block,block2,loc) ->
          begin
          (* match breakstmt with 
           Printf.fprintf stderr "****Expr: %s.\n" (exp_to_string exp);  
          (*expr_list := (list_append !expr_list exp); *)
           Printf.fprintf stderr "Block stmts 1:  %s.\n" (stmt_list_to_string
           block.bstmts);
           Printf.fprintf stderr "Block stmts 2: %s.\n" (stmt_list_to_string block2.bstmts);
          *)
           
           let (f_list, ret_str) =  (self#locatestmt block str) in
           (*  Printf.fprintf stderr "******Comaparing %s %s for %s.******\n" 
                                         str !ret_str (exp_to_string exp);   *)

           if (String.compare str ret_str = 0) then
              begin
		  if (!goto_exp_flip = 1) then (
			e1 := UnOp(LNot, exp , typeOf exp); 
			goto_exp_flip := 0;
		  ) 
		  else e1 := exp;
                  expr_list := (list_append !expr_list !e1);
                  ret_list := !(f_list); 
                  expr_list := (!expr_list@(!ret_list));
                  goto_label := ret_str;
		  brk_if := exp;
              end;
            
 	  let (s_list, ret_str) =  (self#locatestmt block2 str) in 
          (* Printf.fprintf stderr "******Comaparing %s %s for %s.******\n"
                                        str !ret_str (exp_to_string exp);  *)

          if (String.compare str ret_str = 0) then
              begin
	      if (!goto_exp_flip = 1) then (
	        e1 := UnOp(LNot, exp , typeOf exp);
		goto_exp_flip := 0;
		)
	      	else e1 := exp;

                 expr_list := (list_append !expr_list !e1);
                 ret_list := !(s_list);
                 expr_list := (!expr_list@(!ret_list));
                 goto_label := ret_str;
		 brk_if := exp;
              end;
          end
   

       | Goto(stat_ref,location) ->
               begin 
                  (* Printf.fprintf stderr "Statement reference is %s.\n"
                   (stmt_to_string !stat_ref) ; *)
		 Printf.fprintf stderr "Saw a goto.\n";
                 goto_label := String.sub (stmt_to_string !stat_ref) 0
                   (String.index (stmt_to_string !stat_ref) ':');
		  goto_exp_flip := 1;
                  (* Printf.fprintf stderr "Goto label is %s.\n" !goto_label; *)
                 if (String.compare str !goto_label != 0) then
                     begin
                         (*Printf.fprintf stderr "This is where our analysis is sound but
                         not complete."; XXX FIXME *) 
	               goto_label := str;
                        
                     end;
                 (* if goto_label leads to str then make goto_label=str*)
               end 


       | Return(Some e, location) ->
              begin
                  goto_label := str; (*FIXME Treated as a successful goto *)
              end 
           
       | _ -> ();
       done;
      (expr_list , !goto_label);
   end

   method locateprintkstmt (b: stmt list)( ssid :int) : int =
   begin
     let found = ref 0 in
   (*   Printf.fprintf stderr "\n%%%%%%%%%%In locateprintstmt %%%%%% \n";
     Printf.fprintf stderr "Block stmts 1:  %s.\n" (stmt_list_to_string
           b); *)
        
     for i = 0 to (List.length b) - 1 do
     let cur_stmt  = (List.nth b i) in
     let match_regexp = regexp (".*"^"printk"^".*") in 
     if (cur_stmt.sid > ssid) then ( 

     match cur_stmt.skind with  

    | Instr (ilist) ->
         for i = 0 to (List.length ilist) -1 do
         let cur_i = (List.nth ilist i) in
         match cur_i with
              | Call (_,e, el, loc) -> Printf.fprintf stderr "lckpk %s" (exp_to_string e);if (((String.compare (exp_to_string e) "printk") = 0)
                                       ||((Str.string_match match_regexp (exp_to_string e) 0) = true))  then found:= 1;
              | _ -> ();
        done;
     | If(e,b1,b2,l) -> found := (self#locateprintk b1) +  (self#locateprintk b2);
     | Loop (b1,l,_,_) -> found := self#locateprintk b1;
     | Block (b1) -> found := self#locateprintk b1;
     | Switch (e,b1,_,l) -> found := self#locateprintk b1; 
     | TryFinally (b1, b2, l) ->  found := (self#locateprintk b1) +  (self#locateprintk b2);
     | TryExcept (b1, _, b2, _) -> found := (self#locateprintk b1) +  (self#locateprintk b2);
     | _ -> ();
	
     );
      done;
       (* Printf.fprintf stderr "\n+++PRINTK found returns %d+++.\n" !found; *)
    
      !found;
   end

 
   method locateprintk (b: block) : int =
   begin
     let found = ref 0 in
     (* Printf.fprintf stderr "\n%%%%%%%%%%In locateprintstmt %%%%%% \n";
     Printf.fprintf stderr "Block stmts 1:  %s.\n" (stmt_list_to_string
           b.bstmts);
	*)
     for i = 0 to (List.length b.bstmts) - 1 do
     let cur_stmt  = (List.nth b.bstmts i) in
     let match_regexp = regexp (".*"^"printk"^".*") in
     match cur_stmt.skind with
  
    | Instr (ilist) ->
         for i = 0 to (List.length ilist) -1 do
         let cur_i = (List.nth ilist i) in
         match cur_i with
              | Call (_,e, el, loc) -> Printf.fprintf stderr "lckpk %s" (exp_to_string e);if ( ((String.compare (exp_to_string e) "printk") = 0)||((Str.string_match match_regexp (exp_to_string e) 0) = true))  then (Printf.fprintf stderr "PRINTK FOUND.\n"; found:= 1;);
	      | _ -> ();
	done;
     | If(e,b1,b2,l) -> found := !found + (self#locateprintk b1) +  (self#locateprintk b2); 
     | Loop (b1,l,_,_) -> found := !found + self#locateprintk b1;
     | Block (b1) -> found :=  !found + self#locateprintk b1;
     | Switch (e,b1,_,l) -> found := !found + self#locateprintk b1;
     | TryFinally (b1, b2, l) ->  found := !found + (self#locateprintk b1) +  (self#locateprintk b2);
     | TryExcept (b1, _, b2, _) -> found := !found + (self#locateprintk b1) +  (self#locateprintk b2);  
     | _ -> ();
      done;
       Printf.fprintf stderr "\n+++PRINTK found returns %d+++.\n" !found; 
      !found;
   end
   
  method addreportcode (b: block) : unit =
  begin
    let temp_ret = ref (self#locateprintk b) in
    if (!temp_ret = 0) then (
    
    let log_call_fundec = (emptyFunction "printk" ) in
    let const = CStr "shadow ret report.\n" in
    let ex =  Const(const) in
    let args_list = ref [ex] in
    let logg_stmt =  mkStmtOneInstr (Call(None,
             (expify_fundec log_call_fundec),!args_list, locUnknown)) in
    b.bstmts <- [logg_stmt]@b.bstmts  ;
    ); 
    done_add_ret := 1
  end
 
   method locateretstmt (b : block) (str:string) : exp list ref * string =
   begin
     let goto_label = ref "" in
     let ret_list = ref []  in
     (* let ret_str = ref "" in *)
     let expr_list = ref[] in
     (* Printf.fprintf stderr "In locateretstmt. %d\n" locate_ret_call_count; *)
     locate_ret_call_count <- locate_ret_call_count + 1;
      (* Printf.fprintf stderr "Block stmts %s.\n" (stmt_list_to_string
     b.bstmts);  *)
     
    if (locate_ret_call_count > 10000)
	 then Printf.printf  "TIMEOUT COUNTDOWN.\n";
    if (locate_ret_call_count < 10000)
	then	( 
 
     for i = 0 to (List.length b.bstmts) - 1 do
       let cur_stmt  = (List.nth b.bstmts i) in
       match cur_stmt.skind with

      | Block (b1) -> ( let (e_list , g_label) = (self#locateretstmt b1 str) in (expr_list := !e_list; goto_label := g_label;  )  );  
      | Instr (ilist) ->
	  for i = 0 to (List.length ilist) -1 do
	  let cur_i = (List.nth ilist i) in 
	  match cur_i with
	
		|  Set (lv, e, loc) ->
		  begin
                  (* Printf.fprintf stderr "Saw a return with exp %s .\n\n+++++++\n" (exp_to_string e) ; *)
                  if (Cil.isConstant e = true)
                  then (
                        (* Printf.fprintf stderr "This is a constant.\n"; *)
                        let i64 = (Cil.isInteger e) in
                        if (i64 < Some (Int64.of_int 0))
                        then ( (*Printf.fprintf stderr "This is a negative int.\n"; *)goto_label := str; )
                 );
                  match e with
                  | Const (con) -> (
                        (* Printf.fprintf stderr "ZZZZCCC"; *)
                        match con with
                        | CInt64 (i, ik, Some s) -> ( if (i < (Int64.of_int 0)) then ( goto_label := str;  Printf.fprintf stderr "RET1 INCR for %s " (exp_to_string e) ; ret_seen <- ret_seen + 1; pk_count <- pk_count + self#locateprintk b; self#addreportcode b;))
                        | CInt64 (i, ik, None) -> ( if (i < (Int64.of_int 0)) then (goto_label := str;ret_seen <- ret_seen + 1; pk_count <- pk_count + self#locateprintk b;Printf.fprintf stderr "NRET INCR for %s" (exp_to_string e); self#addreportcode b;));
                        | CEnum(_, _, _) -> (Printf.fprintf stderr "ZZZZCCCenum";)
                        | CReal (_, _, _) -> (Printf.fprintf stderr "ZZZZCCfloat";)
                        | CChr (chr) -> (Printf.fprintf stderr "ZZZZCCCchar";)
                        | CWStr (il) -> (Printf.fprintf stderr "ZZZZCCCIL";)
                        | CStr (str) -> (Printf.fprintf stderr "ZZZZCCCSTR";)

                  );
                  | UnOp (u, e1, t) -> (
                        Printf.fprintf stderr "ZZZZ1";
                        match u with
                        | Neg -> (goto_label := str; ret_seen <- ret_seen + 1; pk_count <- pk_count + self#locateprintk b; self#addreportcode b;);
                        | _ -> ();
                  );
                  | _ -> ();
                  (*FIXME Treated as a successful goto *)
                  Printf.fprintf stderr "Return exp is %s.\n" (exp_to_string e);
                end
       		| _ -> ();
	       done;
	

      |    If(exp,block,block2,loc) ->
          begin

	   let (s_list, ret_str) =  (self#locateretstmt block str) in
	
           if (String.compare str ret_str = 0) then
              begin
                  expr_list := (list_append !expr_list exp);
                  ret_list := !s_list;
                  expr_list := (!expr_list@(!ret_list));
                  goto_label := ret_str;
              end;
	  
	  let (s_list, ret_str) =  (self#locateretstmt block2 str) in
          (* Printf.fprintf stderr "******Comaparing %s %s for %s.******\n"
                                        str !ret_str (exp_to_string exp);  *)

          if (String.compare str ret_str = 0) then
              begin
                  expr_list := (list_append !expr_list exp);
                  ret_list := !s_list;
                  expr_list := (!expr_list@(!ret_list));
                  goto_label := ret_str;
              end;
          end
	
	
       | Goto(stat_ref,location) ->
               begin
                  (* Printf.fprintf stderr "Statement reference is %s.\n"
                   (stmt_to_string !stat_ref) ; *)
                 goto_label := String.sub (stmt_to_string !stat_ref) 0
                   (String.index (stmt_to_string !stat_ref) ':');
                  (* Printf.fprintf stderr "Goto label is %s.\n" !goto_label; *)
                 (* if goto_label leads to str then make goto_label=str*)
               end



       | Return(Some e, location) ->
              begin
		  (* Printf.fprintf stderr "Saw a return with exp %s .\n\n+++++++\n" (exp_to_string e) ; *)
		  if (Cil.isConstant e = true)
		  then (
			(* Printf.fprintf stderr "This is a constant.\n"; *)
		  	let i64 = (Cil.isInteger e) in
		  	if (i64 < Some (Int64.of_int 0))
		  	then ( (*Printf.fprintf stderr "This is a negative int.\n"; *)goto_label := str; )
		 );
		  match e with 
		  | Const (con) -> (
			(* Printf.fprintf stderr "ZZZZCCC"; *)
			match con with
			| CInt64 (i, ik, Some s) -> ( if (i < (Int64.of_int 0)) then (goto_label := str;  Printf.fprintf stderr "ZZZZ"; ret_seen <- ret_seen + 1;pk_count <- pk_count + self#locateprintk b; self#addreportcode b;))
			| CInt64 (i, ik, None) -> ( if (i < (Int64.of_int 0)) then ( goto_label := str;ret_seen <- ret_seen + 1; pk_count <- pk_count + self#locateprintk b; self#addreportcode b;));
			| CEnum(_, _, _) -> (Printf.fprintf stderr "ZZZZCCCenum";)
			| CReal (_, _, _) -> (Printf.fprintf stderr "ZZZZCCfloat";)
			| CChr (chr) -> (Printf.fprintf stderr "ZZZZCCCchar";)
			| CWStr (il) -> (Printf.fprintf stderr "ZZZZCCCIL";)
			| CStr (str) -> (Printf.fprintf stderr "ZZZZCCCSTR";)

		  );
		  | UnOp (u, e1, t) -> (
			Printf.fprintf stderr "ZZZZ1"; 
			match u with
			| Neg -> (goto_label := str; ret_seen <- ret_seen + 1; pk_count <- pk_count + self#locateprintk b;self#addreportcode b;);
			| _ -> ();
		  );
		  | _ -> ();
                  (*FIXME Treated as a successful goto *)
		  Printf.fprintf stderr "Return exp is %s.\n" (exp_to_string e);
              end

       | _ -> ();
       done;
      );
       Hashtbl.add locateexplist (ref b) !expr_list ;
      (expr_list , !goto_label);
   end
  
 
   (* Visits every "statement" *)
   method vstmt (s: stmt) : stmt visitAction =
   begin
     (* let brk_if = ref zero64Uexp in *)
     match s.skind with
     Instr(ilist) ->
       begin
         let halting_found = ref 0 in
            let shadow_call = ref dummyStmt in
              for j = 0 to (List.length ilist) - 1 do
              let cur_instr = (List.nth ilist j) in
              match cur_instr with
		(* Check if any calls to DMA/memory functions have tainted arguments *)
                | Call(lvalue_option,e,el,loc) ->
                    if (isdmacall (exp_to_string e) = 1) then
                      begin
                        Printf.fprintf stderr "***DMA the party found.***";
                        for k = 0 to (List.length el) - 1 do
                          let cur_e = (List.nth el k) in
				let str_list_e = (self#find_lvals_exp cur_e) in
				 for l = 0 to (List.length str_list_e) - 1 do  
				  let str_le = (List.nth str_list_e l) in	
                                  Printf.fprintf stderr "Arg: %s.\n" (str_le);
                                  try
                                   let ret_str = (Hashtbl.find dirrrty ((str_le), curr_func.svar.vname)) in
                                   Printf.fprintf stderr "tainted arg .\n";
			           dma_taint := !dma_taint + 1;
                                   with Not_found -> ();
                               done
                           done;
                          end;
                |_ -> ();
                done;
          DoChildren;
        end

     | Loop(b,ln,Some labelstmt,Some breakstmt) ->
        let break_label_list = ref [] in
        let counters_in_loop = ref [] in
        (* Locate the *only* label *)   
        for j = 0 to (List.length breakstmt.labels) - 1 do
          let cur_label  = (List.nth breakstmt.labels j) in    
            match cur_label with
              Label(str,l, boo)  ->
                begin   
                  (* Printf.fprintf stderr "Label is %s.\n" str;  *)
                  break_label_list := (list_append !break_label_list str);
                  (*break_label := str;*)
                end
              | _ -> ();
        done; 

         
        (* b.bstmts <- new_stmts; *)

	     let expr_list = ref[]  in
	   let e1 = ref zero64Uexp in
           Printf.fprintf stderr "Executing for %n labels.\n" (List.length
           !break_label_list) ;
           for j = 0 to (List.length !break_label_list) - 1 do
               let break_label = (List.nth !break_label_list j) in
           for i = 0 to (List.length b.bstmts) - 1 do
           let cur_stmt  = (List.nth b.bstmts i) in
           (* Printf.fprintf stderr "Loop block statement : %s .\n Loop block
            * stmt ends.\n" (stmt_to_string cur_stmt); *)
	   match cur_stmt.skind with
		   If(exp,block,block2,loc) ->
		   begin
		     (*  	match breakstmt with 
			Printf.fprintf stderr "Expr: %s.\n" (exp_to_string exp); 
            Printf.fprintf stderr "Block stmts %s.\n" (stmt_list_to_string
            block2.bstmts);
	               
            ret_str :=  (snd (self#locatestmt block break_label)); *)
	    brk_if := exp;
	    let (f_list, ret_str) =  (self#locatestmt block break_label) in
             (* Printf.fprintf stderr "******Comaparing %s %s for %s.******\n"
            break_label !ret_str (exp_to_string exp);  *)
            if (String.compare break_label ret_str = 0) then
                begin
                  Printf.fprintf stderr "Match \n\n\n";
                 if (!goto_exp_flip = 1) then (
                        e1 := UnOp(LNot, exp , typeOf exp);
                        goto_exp_flip := 0;
                  )
                  else e1 := exp;
			 Printf.fprintf stderr " EXP IS NOW %s" (exp_to_string !e1);
                    expr_list := (list_append !expr_list !e1);
                    expr_list := !expr_list@(!f_list);
                end;

            let (s_list, ret_str) =  (self#locatestmt block2 break_label) in 
            (* Printf.fprintf stderr "******Comaparing %s %s for %s.******\n"
            break_label !ret_str (exp_to_string exp); 
            *)
            if (String.compare break_label ret_str = 0) then
                begin
                    (* Printf.fprintf stderr "Match \n\n\n"; *)
                 if (!goto_exp_flip = 1) then (
                        e1 := UnOp(LNot, exp , typeOf exp);
                        goto_exp_flip := 0;
                  )
                  else e1 := exp;


                    expr_list := (list_append !expr_list !e1);
                    expr_list := !expr_list@(!s_list);
                end;

            Printf.fprintf stderr "|| Expr List follows: %s. End.\n||"
            (exp_list_to_string !expr_list);

            (* There is a BUG here that if there are duplicates in expr_list we
            * may generate fixing code twice for it. So, a FIXME here is to
            * strip expr_list of duplicates.
            *)
            end           
            |_ -> ();
           done;
           done;
	    let ctr_string = ref "1" in	
            let ctr = ref "1" in 
            let strlist = ref [] in
            for k = 0 to (List.length !expr_list) - 1 do
                begin
                  let expr = (List.nth !expr_list k) in
                  strlist := List.append !strlist (self#find_lvals_exp expr);
                end
            done;
            strlist := "__nooks_timer" :: !strlist;
	    strlist := "jiffies" :: !strlist;

             Printf.fprintf stderr "Checking counters";
             counters_in_loop := self#locate_ctrs_in_block b;
             counters_in_loop :=  List.append !counters_in_loop
             (self#locate_dupctrs_in_block b !counters_in_loop);
             (* Match counters in loop with strlist (lvals in exp) to
              * check if there is already a counter. *)
              
             (* Generate fault warning messages for alerting the admin. *)
	   
             Printf.fprintf stderr "Comparing now %d.\n" (List.length
             !counters_in_loop);
             for m = 0 to (List.length !strlist) - 1 do
                let cond_str = (List.nth !strlist m) in
                 for n = 0 to (List.length !counters_in_loop) -1  do
                    let ctr_str = (List.nth !counters_in_loop n) in 
                    (* Printf.fprintf stderr "COMPARING %s %s.\n"
                    ctr_str cond_str; *)
                    
                    if (String.compare cond_str ctr_str = 0) then (
                    Printf.fprintf stderr "There is already a counter. \n";
		    ctr_string := ctr_str;	
		    done_gen := -1;
		    );
                 done;
            done;
                        
            if (!done_gen < 1) then (
                (* TODO: Remove duplicates from strlist here. *)
                for l = 0 to (List.length !strlist) - 1 do
                    let cur_str = (List.nth !strlist l) in
                    if (!done_gen < 1) then                       (* Ensures ticks generated only
                                              * once in a while loop. *)
                    begin
                    (try
                    let ret_str = (Hashtbl.find dirrrty
                    (cur_str,curr_func.svar.vname)) in
                        Printf.fprintf stderr "fn(%s) NOT SAFE DETECTED mapping ->  %s for %s for %d.\n"
                        curr_func.svar.vname ret_str cur_str !block_count;
                        (* At this point we have the while loop, the conditions
                        * and the functions/variables which cause this unsafe
                        * loop problems. Now, we introduce ticks code to
                        * alleviate this.
                        *)


			if (!done_gen = -1) then (
				report_timeout_counter <- report_timeout_counter + 1;
				done_gen := (self#convert_ctrs_alerts b !counters_in_loop);
				done_gen := 1;
			        let ssidstmt = List.nth b.bstmts  (List.length b.bstmts - 1) in 
				let temp_rtc = ref (self#locateprintk b) in
				if (!temp_rtc = 0) then
					temp_rtc := self#locateprintkstmt curr_func.sbody.bstmts ssidstmt.sid;
				pk_in_rtc <- !temp_rtc + pk_in_rtc;
		
				Printf.fprintf stderr "\nPRINT IN REMAINING %d %d.\n" (self#locateprintk curr_func.sbody) pk_in_rtc;
				
				 (* if (pk_in_rtc = 0) then (  *)
				(*rtc_pk = self#locateprintk curr_func.sbody;*)	
				let rtc_line_no = (Printf.sprintf "shadow rtc report line:%d pk %d\n" ln.line pk_in_rtc) in	
				let check_falseblock = (mkBlock [(mkEmptyStmt ())])  in 
				let log_call_fundec = (emptyFunction "printk" ) in
				let const = CStr (*"shadow rtc report.\n"::*) rtc_line_no  in
				let ex =  Const(const) in
				let args_list = ref [ex] in
				let logg_stmt =  mkStmtOneInstr (Call(None,
					 (expify_fundec log_call_fundec),!args_list, locUnknown)) in
				let check_trueblock = (mkBlock [logg_stmt]) in
				brk_if := self#return_the_exp !expr_list !counters_in_loop;
				let check_loop_if = mkStmt(If(!brk_if,check_trueblock, check_falseblock,locUnknown)) in
                                done_add_ret := 0;

				if (String.compare !ctr_string cur_str = 1) then (
					Printf.fprintf stderr "\n++TAINT IS NOT THE COUNTER+++\n";
				
				(* Locates an add on negative return and other condition and adds a printk. *)

			        (* Commented to generate correct stats - Shoudl reamin uncommented. including below else *)	
				self#locateretstmt b (exp_to_string !brk_if);
 				Printf.fprintf stderr "\n++*********** DONE ADD RET IS %d************++\n" !done_add_ret;	
                                if (!done_add_ret = 0) then  (
					let temp_ret = ref (self#locateprintk b) in
					(* Printf.fprintf stderr "\n++***********LOCATEPRINTK IS %d ************++\n" !temp_ret; *)
					if (!temp_ret = 0) then (
					b.bstmts <- [check_loop_if]@b.bstmts ;
					);
					Printf.fprintf stderr "\n++***********ADDING RTC STUFF++\n" ;
				 ) 
				 else ( return_on_device_error <- return_on_device_error - 1; ret_pk_count <- ret_pk_count - 1;); 
				);
				done_gen := 1;
				(* ); *)
			
			);	
		
                        
                        Printf.fprintf stderr "\nFunction: %s\n"
                          curr_func.svar.vname;
                          
                          if (!done_gen = 0) then  (
                          (* Step 1 - Generate the variable and initalize it to
                          * zero.
                          *)
                    
                          let tickvar = makeLocalVar curr_func
                          ("__shadow_tick_"^(!ctr)^(string_of_int glob_ctr)) intType in
                              Printf.fprintf stderr "%s.\n" tickvar.vname;   
                          ctr := !ctr ^ "1";    
                          let snt_reset = Set((lvalify_varinfo tickvar),
                          zero, locUnknown) in
                          let stmt_init_var = (mkStmt (Instr [snt_reset])) in
                            per_fun <- curr_func::per_fun;
                            per_fun_ctr <- stmt_init_var::per_fun_ctr;

                          (* Step 2 - Generate the ticks timeout code. 
                           * true - ticks++
                           * false - goto break stmt
                           * condition - ticks < 200
                           * *)
                          (* FIXME *)
                           (* let false_stmt = (mkStmt(Break(locUnknown))) in *)
			   (*Uncommenting below creates the shadow_recover call  
                           let shadow_call_fundec = (emptyFunction
                                  "__shadow_recover" ) in
                          let args_list = ref [] in
			  let false_stmt =  mkStmtOneInstr (Call(None,
                             (expify_fundec shadow_call_fundec),!args_list,
                               locUnknown)) in
			  *) 
			  let false_stmt = (mkStmt (Return(Some(Const(CInt64((Int64.of_int 72),IInt,None))), locUnknown))) in 
			  let rtc_line_no = (Printf.sprintf "tick failed at line:%d.\n" ln.line) in
			  let log_call_fundec = (emptyFunction "printk" ) in
                          let const = CStr (*"shadow rtc report.\n"::*) rtc_line_no  in
                          let ex =  Const(const) in
                          let args_list = ref [ex] in
                           let logg_stmt =  mkStmtOneInstr (Call(None,
                                        (expify_fundec log_call_fundec),!args_list, locUnknown)) in
                          let true_block =(Set ((lvalify_varinfo tickvar), (BinOp(PlusA, (expify_lval
                          (lvalify_varinfo tickvar)), one, intType)),
                          locUnknown)) in  
                          let ticks_check = (BinOp(Lt, (expify_lval
                          (lvalify_varinfo tickvar)),
                          tickval_exp, intType)) in  
                          let true_stmt_list = ref [] in
                          let false_stmt_list = ref [] in 
                          true_stmt_list := list_append !true_stmt_list (mkStmt(Instr[true_block])); 
			  false_stmt_list := list_append !false_stmt_list logg_stmt;
			  false_stmt_list := list_append !false_stmt_list false_stmt;
			  (* false_stmt_list := list_append !false_stmt_list changed_stmt;*) 
                          let check_trueblock = (mkBlock !true_stmt_list) in
                          let check_falseblock = (mkBlock !false_stmt_list) in  
                          let snt_if = If(ticks_check, check_trueblock,
                          check_falseblock,locUnknown) in
                          let stmt_if = (mkStmt snt_if) in
                          b.bstmts <- list_append b.bstmts stmt_if;
			  error_line_nos := !error_line_nos@[(Printf.sprintf "tck:%d"ln.line)];
                          done_gen := 1;
                          )
                    with Not_found -> ();
                    );
                    end;
                done;
                glob_ctr <- glob_ctr + 1; (* To maintain global uniqueness *)
            );

          Printf.fprintf stderr "Done with WHILE PROCESSING.\n";
          
	    DoChildren; 
	(* Here we look for all conditionals based on device values that return non-zero values. *) 
	| If (exp,block,block2,loc) ->
	       let if_bad = ref 0 in
	       let done_check = ref 0 in	
	       let strlist = ref [] in
               strlist := List.append !strlist (self#find_lvals_exp exp);
              (* TODO: Remove duplicates from strlist here. *)
              for l = 0 to (List.length !strlist) - 1 do
                   let cur_str = (List.nth !strlist l) in
                   if (!done_check = 0) then
                   begin
		    (* Printf.fprintf stderr "CHECKING FOR IF %s %d. \n\n\n" cur_str (isbad cur_str []); *)
		    if (isbad cur_str [] = 1) then
			done_check := 1;
                  (try
		    (* Printf.fprintf stderr "CHECKING FOR DIRRRTY %s %d. \n\n\n" cur_str (isbad cur_str []); *)
                    let ret_str = (Hashtbl.find dirrrty (cur_str,curr_func.svar.vname)) in
                        Printf.fprintf stderr "fn(%s) Return on not safe ->  %s for %s for %d.\n"
                        curr_func.svar.vname cur_str cur_str !block_count;
                        done_check := 1;
			if_bad := 1;
                    with Not_found -> ();
                    );
                    end;
                done;
		
		if (!done_check = 1) then  (
		
		let check_str = ref "yes" in
		let expr_list = ref[]  in
		let expr_list2 = ref [] in
    		try
      		   let rt_exp = (Hashtbl.find locateexplist (ref block)) in
       		   begin
			Printf.fprintf stderr "******Match \n\n\n";
			expr_list := rt_exp;
       		   end	   
        	with Not_found -> (
 
			let (s_list, ret_str) =  (self#locateretstmt block !check_str) in
	                Hashtbl.add locateexplist (ref block) (list_append !s_list exp); 
			(*	
		Printf.fprintf stderr "Block stmts %s.\n" (stmt_list_to_string
                block2.bstmts);

         	 Printf.fprintf stderr "Block stmts %s.\n" (stmt_list_to_string
                 block.bstmts);
		*)

 
                	if (String.compare !check_str ret_str = 0) then
	                begin
        	            Printf.fprintf stderr "Match \n\n\n";
                	    expr_list := (list_append !expr_list exp);
	                    expr_list := !expr_list@(!s_list);
        	        end;

	                let (s_list, ret_str)  =  (self#locateretstmt block2 !check_str) in
		        Hashtbl.add locateexplist (ref block2) (list_append !s_list exp);	
                	if (String.compare !check_str ret_str = 0) then
	                begin
        	            (* Printf.fprintf stderr "Match \n\n\n"; *)
                	    expr_list2 := (list_append !expr_list2 exp);
	                    expr_list2 := !expr_list2@(!s_list);
        	        end;
	       	);

	(*
               Printf.fprintf stderr "|| Expr RET List follows: %s. End.\n||"
               (exp_list_to_string !expr_list);
		
		Printf.fprintf stderr "|| Expr2  RET List follows: %s. End.\n||"
               (exp_list_to_string !expr_list2);

	
               let strlist = ref [] in
               for k = 0 to (List.length !expr_list) - 1 do
               begin
                  let expr = (List.nth !expr_list k) in
                  strlist := List.append !strlist (self#find_lvals_exp expr);
               end
              done;
	
	       let strlist2 = ref [] in
               for k = 0 to (List.length !expr_list2) - 1 do
               begin
                  let expr = (List.nth !expr_list2 k) in
                  strlist2 := List.append !strlist2 (self#find_lvals_exp expr);
               end
              done;
	
		
	      let if_ret_gen = ref 0 in
              if (!done_ret_gen = 0) then (
              (* TODO: Remove duplicates from strlist here. *)
              for l = 0 to (List.length !strlist) - 1 do
                   let cur_str = (List.nth !strlist l) in
                   if (!done_ret_gen = 0) then           
                   begin
                  (try
                    let ret_str = (Hashtbl.find dirrrty (cur_str,curr_func.svar.vname)) in
                        Printf.fprintf stderr "fn(%s) Return on not safe ->  %s for %s for %d.\n"
                        curr_func.svar.vname ret_str cur_str !block_count;
			(* Insert code before return -- now only does in enclosing if *)
	                (*let log_call_fundec = (emptyFunction "printk" ) in
                        let const = CStr "shadow ret report.\n" in
                        let ex =  Const(const) in
                        let args_list = ref [ex] in
                        let logg_stmt =  mkStmtOneInstr (Call(None,
                                         (expify_fundec log_call_fundec),!args_list, locUnknown)) in
                        block.bstmts <- [logg_stmt]@block.bstmts  ;
			*)
                        if_ret_gen := 1;
                    with Not_found -> ();
                    );
                    end;
                done;
		);

              if (!done_ret_gen = 0) then (
              (* TODO: Remove duplicates from strlist here. *)
              for l = 0 to (List.length !strlist2) - 1 do
                   let cur_str = (List.nth !strlist2 l) in
                   if (!done_ret_gen = 0) then
                   begin
                  (try
                    let ret_str = (Hashtbl.find dirrrty (cur_str,curr_func.svar.vname)) in
                        Printf.fprintf stderr "fn(%s) Return on not safe ->  %s for %s for %d.\n"
                        curr_func.svar.vname ret_str cur_str !block_count;

                        (* Insert code before return -- now only does in enclosing if 
                        let log_call_fundec = (emptyFunction "printk" ) in
                        let const = CStr "shadow ret report.\n" in
                        let ex =  Const(const) in
                        let args_list = ref [ex] in
                        let logg_stmt =  mkStmtOneInstr (Call(None,
                                         (expify_fundec log_call_fundec),!args_list, locUnknown)) in
                        block2.bstmts <- [logg_stmt]@block2.bstmts  ;
			*)
                        done_ret_gen := 1;
                    with Not_found -> ();
                    );
                    end;
                done;
                );
		done_ret_gen := !done_ret_gen + !if_ret_gen;
		*)
		return_on_device_error <- return_on_device_error + ret_seen;
		ret_pk_count <- ret_pk_count + pk_count;
	        pk_count <- 0;
		ret_seen <- 0;
	   );	
		DoChildren; 
	
	| _ ->  DoChildren;
            
            
   end

   method return_the_exp (expr_list :exp list) ( counters_in_loop :string list): exp = 
   begin
     	let found = ref 0 in
	let ret_exp = ref zero64Uexp in 
     	    (* Convert each expression to string) *)
	let strlist = ref [] in
	
	for k = 0 to (List.length expr_list) - 1 do
        begin
	    if (!found = 0)  then	(
		let expr = (List.nth expr_list k) in
	        strlist := (self#find_lvals_exp expr);
	      
		for m = 0 to (List.length !strlist) - 1 do
	          let cond_str = (List.nth !strlist m) in
          		for n = 0 to (List.length counters_in_loop) -1  do
                 	let ctr_str = (List.nth counters_in_loop n) in 
	        	if (String.compare cond_str ctr_str = 0) then (
		        Printf.fprintf stderr "Counter exp etected. \n";
		        found := 1;
			ret_exp := expr; 
		        (* ret_exp := (UnOp(LNot, expr , typeOf expr)); *)
	                )
		        done;
		done;
        	 )
	  end
	done; 
          !ret_exp;	
    end

    
  (* Returns a statement that checks if the array bounds in an instruction
     have been violated. Returns the empty statement if no bounds check is needed.
     Also returns whether a bounds check is needed. *)   
   method get_bounds_check_stmt (i: instr) : stmt * bool = 
   begin
     (* Find all array lvals in instruction *)
     let array_lvals = (self#find_array_lval_list_from_instr i) in
         (* Find all array lvals with a contaminated index *)
         let cont_array_lvals = (self#find_cont_array_lvals array_lvals) in
           (* If there are contaminated array accesses in current instruction: *)
           if (List.length cont_array_lvals) > 0 then
            begin
              Printf.fprintf stderr "func: %s, num_cont_array_accesses: %d\n"
                                curr_func.svar.vname (List.length cont_array_lvals);
              (* Find length of each cont_lval *)
              let cont_array_lengths = (self#array_lval_list_lengths cont_array_lvals) in
                (* Form condition for if statement *)
                let cond_exp = (self#mkManyIfCond cont_array_lvals cont_array_lengths) in
                 let new_stmt = (mkStmt (If(cond_exp, 
				(mkBlock [(mkStmt (Return(Some(Const(CInt64((Int64.of_int 75),IInt,None))),
					locUnknown)))]),
                                (mkBlock [(mkEmptyStmt ())]), 
				locUnknown))) in
		 new_stmt.skind <- If(cond_exp, 
                                (mkBlock [(mkStmt (Return(Some(Const(CInt64((Int64.of_int 75),IInt,None))),
                                        locUnknown)))]),
                                (mkBlock [(mkEmptyStmt ())]),
                                locUnknown);
		 (new_stmt,true);
 	   end 
	   else ((mkEmptyStmt ()),false)
   end

   (* Converts an instruction list to a statement list *)
   method get_stmt_list_from_instr_list (i_list: instr list) (labels: label list) : stmt list =
   begin
      let stmt_list = ref [] in
      let curr_instr_list = ref [] in
	for i = 0 to (List.length i_list) - 1 do
	  begin
	    let (new_stmt,need_bounds_check) = (self#get_bounds_check_stmt (List.nth i_list i)) in
		if(need_bounds_check) 
		then begin
			let curr_stmt = mkStmt(Instr(!curr_instr_list)) in
			  curr_stmt.skind <- Instr(!curr_instr_list);
			  stmt_list := (List.append !stmt_list 
					(List.append [curr_stmt] [new_stmt]));
			  num_array_checks_added <- num_array_checks_added + 1;
			  error_line_nos := !error_line_nos@[(Printf.sprintf "arr:%d"last_array_device_call_loc)];
			  curr_instr_list := [(List.nth i_list i)];
		end
		else curr_instr_list := (List.append !curr_instr_list [(List.nth i_list i)])
	  end;
	done;
        let final_stmt = mkStmt(Instr(!curr_instr_list)) in	
		final_stmt.skind <- Instr(!curr_instr_list);
	let final_stmt_list = List.append !stmt_list [final_stmt] in
		(List.hd final_stmt_list).labels <- labels;
		final_stmt_list;
   end

   (* Creates a bounds checking statement for the given cont_array_lvals with the given label list. *)
  method get_stmt_from_if_stmt (cont_array_lvals: lval list) (labels: label list) : stmt =
   begin
	(* Find length of each cont_lval *)
        let cont_array_lengths = (self#array_lval_list_lengths cont_array_lvals) in
                (* Form condition for if statement *)
                let cond_exp = (self#mkManyIfCond cont_array_lvals cont_array_lengths) in
                let new_stmt = (mkStmt (If(cond_exp,
                                (mkBlock [(mkStmt (Return(Some(Const(CInt64((Int64.of_int 75),IInt,None))),
                                        locUnknown)))]),
                                (mkBlock [(mkEmptyStmt ())]),
                                locUnknown))) in
                 new_stmt.skind <- If(cond_exp,
                                (mkBlock [(mkStmt (Return(Some(Const(CInt64((Int64.of_int 75),IInt,None))),
                                        locUnknown)))]),
                                (mkBlock [(mkEmptyStmt ())]),
                                locUnknown);
		 new_stmt.labels <- labels;
                 new_stmt;
   end

   (* Converts a statement to a statement list *)
   method get_stmt_list (s: stmt) : stmt list =
   begin
	match s.skind with
	| Instr(i_list) -> ( self#get_stmt_list_from_instr_list i_list s.labels);
	| If(e,b1,b2,l) -> 
           begin
              let array_lvals = (self#find_array_lval_list_from_exp e) in
                let cont_array_lvals = (self#find_cont_array_lvals array_lvals) in
                        if(List.length cont_array_lvals > 0) then
			begin
				
				Hashtbl.add hist_array_dirty ((exp_to_string e) , curr_func.svar.vname) "yes";
				let new_if_stmt = (mkStmt (If(e,b1,b2,l))) in
                 			new_if_stmt.skind <- If(e,b1,b2,l);
					num_array_checks_added <- num_array_checks_added + 1;
					error_line_nos := !error_line_nos@[(Printf.sprintf "arr:%d"last_array_device_call_loc)];
                              		(self#get_stmt_from_if_stmt cont_array_lvals s.labels) :: [new_if_stmt];
			end
			else [s]
           end
	| Loop (b, l, _, _) ->
		(
(*        let stmt_list = ref [] in
        for i = 0 to (List.length b.bstmts) - 1 do
                stmt_list := !stmt_list @ (self#get_stmt_list (List.nth b.bstmts i));
            done;
        b.bstmts <- !stmt_list ; *)
        [s];



	);

	 
(*	| Block (b) -> ( 
	
        let stmt_list = ref [] in
        for i = 0 to (List.length b.bstmts) - 1 do
                stmt_list := !stmt_list @ (self#get_stmt_list (List.nth b.bstmts i));
            done;
        b.bstmts <- !stmt_list ;
	); 
	[s]; 
*)

	| _ -> [s];
   end  

   (* Mem dereference start. *)

   method find_deref_lval_list_from_exp_list (e_list: exp list) : lval list =
   begin
        match e_list with
       | hd_e :: tl_e_list -> (self#find_deref_lval_list_from_exp hd_e) @
                                (self#find_deref_lval_list_from_exp_list tl_e_list);
       | _ -> [];
   end
 

   method find_deref_lval_list_from_instr (i: instr) : lval list =
   begin
        match i with
        | Set(lv,ex, l)  ->
                begin
		last_instr_loc <- l.line;
		match lv with (lhost, offset) -> (
                  match lhost with
            	  |  Mem(exp) -> lv::self#find_deref_lval_list_from_exp ex ;
            	  |_ ->  self#find_deref_lval_list_from_exp ex; 
                 )
                end
        | Call (lv_option,ex, el, l) ->
                begin
		last_instr_loc <- l.line;
		last_device_call_loc <- 1;
		let e1 = (exp_to_string ex) in
		if (isbad e1 [] == 1) then	(
         	match lv_option with
                | Some (lv) ->
                 begin
                        match lv with
                        | (Var(var),_) -> Hashtbl.remove hist_dirty (var.vname, curr_func.svar.vname);
                        | _ -> Hashtbl.clear hist_dirty;
                end
                |_ -> Hashtbl.clear hist_dirty;
 
		  last_device_call_loc <- l.line;	
                  Printf.fprintf stderr "Cleared hash table at %d.\n" last_device_call_loc; 
		);

                  match lv_option with
 		  | Some (lv) ->
		    begin
			match lv with (lhost, offset) -> (
                  	match lhost with
            	  	|  Mem(exp) -> lv::(self#find_deref_lval_list_from_exp ex)@(self#find_deref_lval_list_from_exp_list el);
            	  	|_ -> (self#find_deref_lval_list_from_exp ex)@(self#find_deref_lval_list_from_exp_list el);
                   )
		    end
            	  |_ -> (self#find_deref_lval_list_from_exp ex)@(self#find_deref_lval_list_from_exp_list el);             
                end
        |_ -> [];

    end

   method get_deref_check_stmt (i: instr) : stmt * bool =
   begin
     last_instr_loc <- 0;
     (* Find all deref lvals in instruction *)
     let deref_lvals = (self#find_deref_lval_list_from_instr i) in
         (* Find all array lvals with a contaminated index *)
         let cont_deref_lvals = (self#find_cont_deref_lvals deref_lvals) in
           (* If there are contaminated deref accesses in current instruction: *)
           if (List.length cont_deref_lvals) > 0 then
            begin
              Printf.fprintf stderr "func: %s, num_cont_deref_accesses: %d\n"
                                curr_func.svar.vname (List.length cont_deref_lvals);
                (* Form condition for if statement *)
                let cond_exp = (self#mkManyIfCond_deref cont_deref_lvals) in
                 let new_stmt = (mkStmt (If(cond_exp,
                                (mkBlock [(mkStmt (Return(Some(Const(CInt64((Int64.of_int 75),IInt,None))),
                                        locUnknown)))]),
                                (mkBlock [(mkEmptyStmt ())]),
                                locUnknown))) in
                 new_stmt.skind <- If(cond_exp,
                                (mkBlock [(mkStmt (Return(Some(Const(CInt64((Int64.of_int 75),IInt,None))),
                                        locUnknown)))]),
                                (mkBlock [(mkEmptyStmt ())]),
                                locUnknown);
                 (new_stmt,true);
           end
           else ((mkEmptyStmt ()),false)
   end
 
  method put_if_info_in_hash (e: exp) : unit = 
  begin
	Printf.fprintf stderr "Saw if while re-construction";
	let cont_str_list = self#find_lvals_exp e in
        for k = 0 to (List.length cont_str_list) - 1 do
          let cur_cont_str = (List.nth cont_str_list k) in
          Hashtbl.add hist_dirty (cur_cont_str , curr_func.svar.vname) "yes";
          Printf.fprintf stderr "added %s\n" cur_cont_str;
        done;
         Hashtbl.add hist_dirty ((exp_to_string e) , curr_func.svar.vname) "yes";
  end 



  (* Converts an instruction list to a statement list *)
   method get_stmt_list_from_instr_list_deref (i_list: instr list) (labels: label list) : stmt list =
   begin
      let stmt_list = ref [] in
      let curr_instr_list = ref [] in
        for i = 0 to (List.length i_list) - 1 do
          begin
            let (new_stmt,need_deref_check) = (self#get_deref_check_stmt (List.nth i_list i)) in
                if(need_deref_check)
                then begin
                        let curr_stmt = mkStmt(Instr(!curr_instr_list)) in
                          curr_stmt.skind <- Instr(!curr_instr_list);
                          stmt_list := (List.append !stmt_list
                                        (List.append [curr_stmt] [new_stmt]));
                          mem_deref_bugs <- mem_deref_bugs + 1;
			  error_line_nos := !error_line_nos@["m"]@[(Printf.sprintf "%d"last_instr_loc)];
                          curr_instr_list := [(List.nth i_list i)];
                end
                else curr_instr_list := (List.append !curr_instr_list [(List.nth i_list i)])
          end;
        done;
        let final_stmt = mkStmt(Instr(!curr_instr_list)) in	(
                final_stmt.skind <- Instr(!curr_instr_list);
	match final_stmt.skind with
	| If(e,b1,b2,l) ->
		self#put_if_info_in_hash e; 
	|_ -> ();

	);
        let final_stmt_list = List.append !stmt_list [final_stmt] in
                (List.hd final_stmt_list).labels <- labels;
                final_stmt_list;
   end

   method mkManyIfCond_deref(lval_in_list: lval list) : exp =
   begin
      let cond_list = ref [] in
    
      (* Create an expression to compare index to array upper bound for each array*)
      for i = 0 to (List.length lval_in_list) - 1 do
	      let lv = (List.nth lval_in_list i) in
	      match lv with (lhost, offset) -> (
             		match lhost with
             		|  Mem(exp) -> (
			   let check_var = (UnOp(LNot, exp , typeOf exp)) in
			   cond_list := check_var :: !cond_list;
		        );	
			|  Var (vinfo) -> (Printf.fprintf stderr "Seen vinfo %s.\n" vinfo.vname);
	);

	      (* let check_var = (UnOp(LNot, (expify_lval (List.nth lval_in_list i)) , typeOf (expify_lval (List.nth lval_in_list i)))) in 
              cond_list := check_var :: !cond_list; *) 
      done;

       let cond = ref (List.nth !cond_list 0) in
        for i = 1 to (List.length !cond_list) - 1 do
        	cond := BinOp(LOr, !cond, (List.nth !cond_list i), intType);
        done;
        !cond;
   end



  method get_stmt_from_if_stmt_deref (cont_deref_lvals: lval list) (labels: label list) : stmt =
   begin
                (* Form condition for if statement *)
                let cond_exp = (self#mkManyIfCond_deref cont_deref_lvals) in
                let new_stmt = (mkStmt (If(cond_exp,
                                (mkBlock [(mkStmt (Return(Some(Const(CInt64((Int64.of_int 75),IInt,None))),
                                        locUnknown)))]),
                                (mkBlock [(mkEmptyStmt ())]),
                                locUnknown))) in
                 new_stmt.skind <- If(cond_exp,
                                (mkBlock [(mkStmt (Return(Some(Const(CInt64((Int64.of_int 75),IInt,None))),
                                        locUnknown)))]),
                                (mkBlock [(mkEmptyStmt ())]),
                                locUnknown);
                 new_stmt.labels <- labels;
                 new_stmt;
   end


   method find_cont_deref_lvals (lval_list: lval list) : lval list =
    begin
     match lval_list with
     | hd_lval :: tl_lval_list ->
      begin
       match hd_lval with (lhost, offset) -> (
             match lhost with
             |  Mem(exp) -> (
		if (self#process_dereference exp = 1)
		then begin
			hd_lval :: (self#find_cont_deref_lvals tl_lval_list);
		  end
		else (self#find_cont_array_lvals tl_lval_list);
	    );
            |_ -> self#find_cont_array_lvals tl_lval_list;
          )
      end
     |_ -> [];
  end

   method find_deref_lval_list_from_exp(e : exp) : lval list=
   begin
      (* Printf.fprintf stderr "In find dref %s\n\n\n" (exp_to_string e); *)
      match e with
      |   Lval (lval) -> (
           match lval with (lhost, offset) -> (
               match lhost with
            |  Mem(exp) -> [lval];
            |_ -> [];
            )
          )

      |   SizeOfE(exp) -> (self#find_deref_lval_list_from_exp exp; )
      |   AlignOfE(exp) -> (self#find_deref_lval_list_from_exp exp;)
      |   UnOp(u, exp, tp) -> (self#find_deref_lval_list_from_exp exp;)
      |   BinOp(bi, exp1, exp2,tp) -> (   (self#find_deref_lval_list_from_exp exp1)@(self#find_deref_lval_list_from_exp exp2;) ;);
      |   CastE (tp, exp) -> (self#find_deref_lval_list_from_exp exp;)
      |   AddrOf (lval) ->  (
           match lval with (lhost, offset) -> (
               match lhost with
            |  Mem(exp) -> (Printf.fprintf stderr "here .\n"; [lval] ; );
            |_ -> [];
            )
          )
      |   StartOf (lval) -> (
           match lval with (lhost, offset) -> (
               match lhost with
            |  Mem(exp) ->  [lval] ;
            |_ -> [];
           )
          )

        |_ -> [];

   end


   method get_stmt_list_deref (s: stmt) : stmt list =
   begin
        match s.skind with
        | Instr(i_list) -> (self#get_stmt_list_from_instr_list_deref i_list s.labels); 
        | If(e,b1,b2,l) ->
           begin
	      Printf.fprintf stderr "Saw if.\n";
              let deref_lvals = (self#find_deref_lval_list_from_exp e) in
                let cont_deref_lvals = (self#find_cont_deref_lvals deref_lvals) in
			let cont_str_list = self#find_lvals_exp e in
			for k = 0 to (List.length cont_str_list) - 1 do
			let cur_cont_str = (List.nth cont_str_list k) in
				Hashtbl.add hist_dirty (cur_cont_str , curr_func.svar.vname) "yes";
				Printf.fprintf stderr "added %s\n" cur_cont_str;
				Hashtbl.add hist_if_ptr_check (cur_cont_str , curr_func.svar.vname) l.line;
			done;
			Hashtbl.add hist_dirty ((exp_to_string e) , curr_func.svar.vname) "yes";
                        if(List.length cont_deref_lvals > 0) then
                        begin
				(* Printf.fprintf stderr "Saw iffif.\n";
				let cont_str_list = self#find_lvals_exp e in
				  for k = 0 to (List.length cont_str_list) - 1 do
				     let cur_cont_str = (List.nth cont_str_list k) in
				      Hashtbl.add hist_dirty (cur_cont_str , curr_func.svar.vname) "yes";
			              Printf.fprintf stderr "added %s .\n" cur_cont_str;
				done;
				     Hashtbl.add hist_dirty ((exp_to_string e) , curr_func.svar.vname) "yes";
				 find_lvals_exp *)
                                let new_if_stmt = (mkStmt (If(e,b1,b2,l))) in
                                        new_if_stmt.skind <- If(e,b1,b2,l);
                                        mem_deref_bugs <- mem_deref_bugs + 1;
					error_line_nos := !error_line_nos@[(Printf.sprintf "m:%d"l.line)];
                                        (self#get_stmt_from_if_stmt_deref cont_deref_lvals s.labels) :: [new_if_stmt];
                        end
                        else [s]
           end
        | _ -> [s];
   end

 
   method generate_check_code (lv: lval) : stmt =
   begin
	let check_var = (UnOp(LNot, (expify_lval lv) , voidPtrType)) in
 	let false_block = (mkBlock [(mkEmptyStmt ())]) in
	let true_block  = (mkBlock [(mkStmt (Return(Some(Const(CInt64((Int64.of_int 75),IInt,None))),
                                        locUnknown)))]) in 
	let new_stmt = (mkStmt (If (check_var, true_block, false_block, locUnknown))) in
		curr_block.bstmts <- list_append curr_block.bstmts new_stmt; 	 
	new_stmt;
   end 
  
   method process_dereference (e:exp) : int =
   begin
	let unsafe_dref = ref 0 in
	let found = ref 0 in
        let str_list = ref [] in
        str_list := self#find_lvals_exp e;
	let incoming_exp = (exp_to_string e) in

        (* Printf.fprintf stderr "DREF PROCESS FOR %s" incoming_exp;   *)
	if (last_device_call_loc = 0) then    (
		Printf.fprintf stderr "BOGUS CALL FOR %s" incoming_exp;
		found := 1; );

	if (last_instr_loc != 0) then (
	 (* Printf.fprintf stderr "last instruction seen at %d.\n" last_instr_loc;
	  Printf.fprintf stderr "last device call seen at %d.\n" last_device_call_loc; *)

	  try 
	    let ret_int = (Hashtbl.find hist_if_ptr_check (incoming_exp, curr_func.svar.vname)) in
	    (* Printf.fprintf stderr "(Maybe already checked)last ret_from_hash seen at %d.\n" ret_int; *)
	  if ((ret_int  > last_device_call_loc) & (last_instr_loc - ret_int < 10) & (last_instr_loc - ret_int > 0)) then
	  (	Printf.fprintf stderr "(Checked indeed) last ret_from_hash seen at %d.\n" ret_int;
		Hashtbl.add hist_dirty (incoming_exp, curr_func.svar.vname) "yes"; 
		found := 1;
	  );
          if (last_device_call_loc = 0) then	(
		found := 1; )
	  with Not_found -> ();
	 
	  try
	    let ret_int = (Hashtbl.find when_dirrrty (incoming_exp, curr_func.svar.vname)) in
		Printf.fprintf stderr "last instruction seen at %d.\n" last_instr_loc;
		Printf.fprintf stderr "when_dirty at %d.\n" ret_int;
		if (ret_int > 0) && (ret_int > last_instr_loc) then	(
		Printf.fprintf stderr "Not dirty yet.\n";
		found := 1;
		)
	   with Not_found -> ();
 
	);

	if (!found = 0) then (
       
	try (
	Printf.fprintf stderr "incoming exp is %s.\n" incoming_exp;
	let ret_str = (Hashtbl.find hist_dirty (incoming_exp ,curr_func.svar.vname)) in
		Printf.fprintf stderr "History Match %s.\n" ret_str; 
		(* !unsafe_dref; *)
	);
	with Not_found -> (
        (*
        let var_li = ref [] in
          var_li := (Ptranal.resolve_exp e);

        Printf.fprintf stderr "Varinfo list is %d long.\n" (List.length !var_li);
        for vlcnt = 0 to (List.length !var_li) - 1 do
          let cur_var = (List.nth !var_li vlcnt) in
                Printf.fprintf stderr "Suspect at %s" cur_var.vname;
        done;
        *)  (* checks each and every variable is dirty in the expression. *)

	        for i = 0 to (List.length !str_list) - 1 do
		    let cur_e = (List.nth !str_list i) in
		(try ( 
        	let ret_str = (Hashtbl.find dirrrty ((cur_e),curr_func.svar.vname)) in
                	(* Printf.fprintf stderr "fn(%s) NOT SAFE DETECTED mapping ->  %s for %s.\n"
                        	curr_func.svar.vname ret_str (exp_to_string e);i *)

	        try
       		     let ret_int = (Hashtbl.find hist_if_ptr_check (cur_e, curr_func.svar.vname)) in
       		 	  if ((ret_int  > last_device_call_loc) & (last_instr_loc - ret_int < 10) & (last_instr_loc - ret_int > 0)) then
	       		 (     
        	        	Hashtbl.add hist_dirty (incoming_exp, curr_func.svar.vname) "yes";
				Printf.fprintf stderr "pointer check.\n";
	        	  );
		          if (last_device_call_loc = 0) then    (
        		        found := 1; )
	        	  with Not_found -> (

			 Hashtbl.add hist_dirty
        	                          (incoming_exp , curr_func.svar.vname) "yes";

			Printf.fprintf stderr "^^Memory op found for exp %s %s.\n" (exp_to_string e) ret_str;
			unsafe_dref := 1;
			);
			
        	);
	        with Not_found -> ();
		);
		done;
	);
	);
		
	!unsafe_dref
   end
 
   method find_deref_in_exp (e : exp) : unit =
   begin
      let retval = ref 0 in
      Printf.fprintf stderr "HERE find_deref_in_exp.\n"; 
      match e with  
      |   Lval (lval) -> (
           match lval with (lhost, offset) -> (
               match lhost with
            |  Mem(exp) -> (retval := self#process_dereference exp;lval_corrupt := !lval_corrupt + !retval;) ;
            |_ -> ();
            )
          )
		
      |   SizeOfE(exp) -> (self#find_deref_in_exp exp; )
      |   AlignOfE(exp) -> (self#find_deref_in_exp exp;)
      |   UnOp(u, exp, tp) -> (self#find_deref_in_exp exp;)
      |   BinOp(bi, exp1, exp2,tp) -> ( Printf.fprintf stderr "HERE BINOP.\n";if ((bi != LAnd) & (bi != BAnd) ) then (    self#find_deref_in_exp exp1;  self#find_deref_in_exp exp2;))
      |   CastE (tp, exp) -> (self#find_deref_in_exp exp;)
      |   AddrOf (lval) ->  (
           match lval with (lhost, offset) -> (
               match lhost with
            |  Mem(exp) -> (retval := self#process_dereference exp; lval_corrupt := !lval_corrupt + !retval;) ;
            |_ -> ();
            )
          )
      |   StartOf (lval) -> (
           match lval with (lhost, offset) -> (
               match lhost with
            |  Mem(exp) ->  (retval := self#process_dereference exp; lval_corrupt := !lval_corrupt + !retval;) ;
            |_ -> ();
           ) 
          )

        |_ -> (); 
  	 
      lval_corrupt := !lval_corrupt + !retval;  
   end

    method inst_process (ins: instr) : unit =
    begin
        let empty_stmt = ref (mkEmptyStmt ()) in 
        match ins with
        | Set(lv,ex, _)  ->
                begin
		  lval_corrupt := 0;
                  self#find_deref_in_exp ex;
		  if (!lval_corrupt != 0) then	(
			Printf.fprintf stderr "lval corrupt";
			empty_stmt := self#generate_check_code (lv);
			);
                end
        | Call (lv,ex, el, l) ->
                begin
		  lval_corrupt := 0;
                  self#find_deref_in_exp ex;
		  if (!lval_corrupt != 0) then
			Printf.fprintf stderr "lval corrupt";
                  for i = 0 to (List.length el) - 1 do
                    let curr_e  = (List.nth el i) in
			lval_corrupt := 0;
                        self#find_deref_in_exp curr_e;
			if (!lval_corrupt != 0) then
				Printf.fprintf stderr "lval corrupt";
                  done;
                end
        |_ -> ();
    end

   method stmt_to_inst_process (s : stmt) : unit =
   begin
        match s.skind with
        | Instr(i_list) ->
                begin
                  for i = 0 to (List.length i_list) - 1 do
                    let curr_i = (List.nth i_list i) in
                     self#inst_process curr_i;
                  done;
                end
        | _ -> ();
   end


   
   (* Visits every block *)
   method vblock (b: block) : block visitAction =
   begin
     (* In each basic block, check if the statement is a while loop,
     * Check if any of the bad_functions are used (directly or indirectly)
     * and flag them. *)
      curr_block <- b;
      block_count := !block_count + 1;
      done_gen := 0;
      done_ret_gen := 0;
      locate_ret_call_count <- 0;
      (* The stmt_list to replace the current statement *)
      let stmt_list = ref [] in 
        for i = 0 to (List.length b.bstmts) - 1 do
		stmt_list := !stmt_list @ (self#get_stmt_list (List.nth b.bstmts i));
	    done;
        b.bstmts <- !stmt_list;	      

      let deref_stmt_list = ref [] in	
       for i = 0 to (List.length b.bstmts) - 1 do
	 deref_stmt_list := !deref_stmt_list @ (self#get_stmt_list_deref (List.nth b.bstmts i));
       done;	   
      b.bstmts <- !deref_stmt_list;

      DoChildren;
      (* ChangeDoChildrenPost (curr_block, (fun b -> curr_block)); *)
   end

   (* Visits every function *)
   method vfunc (f: fundec) : fundec visitAction =
   begin
     (* Build CFG for every function.*) 
     (Cil.prepareCFG f);
     (Cil.computeCFGInfo f false);  (* false = per-function stmt numbering,
                                             true = global stmt numbering *)

     curr_func <- f; (*Store the value of current func before getting into
                       deeper visitor analysis. *)
     
     Printf.fprintf stderr "\n\n\n((((((((((((((((((( Saw function  %s  Descending )))))))))))))))))))\n \n \n" 
     f.svar.vname;
     block_count := 0;
     last_device_call_loc <- 0;
     last_array_device_call_loc <- 0;	

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


	if (List.length per_fun -1 + num_array_checks_added + 
		mem_deref_bugs + !halt_count + return_on_device_error + report_timeout_counter + num_bad_ptr_lvals) > 0 then (

        Printf.fprintf stderr "The count of BUGS is %d.\n" (List.length
        per_fun - 1);
        Printf.printf "ticks %d " (List.length per_fun
        - 1);
        Printf.fprintf stderr "\nAdded %d new statements to check array
        bounds\n" num_array_checks_added;
        Printf.printf "newstmt %d" num_array_checks_added;
	
	Printf.printf " mem bugs %d hlt %d ret %d rtc %d pk %d dma %d." mem_deref_bugs !halt_count return_on_device_error report_timeout_counter ret_pk_count !dma_taint; (*num_bad_ptr_lvals; *)
	Printf.fprintf stderr " m b %d hlt %d ret %d rtc %d pk %d dma %d." mem_deref_bugs !halt_count return_on_device_error report_timeout_counter ret_pk_count !dma_taint; (* num_bad_ptr_lvals; *)

	if (ret_pk_count > return_on_device_error) then
		Printf.printf "Analysis exception.\n";
 
	if (gen_line_nos = 1 ) then (	
	for ctr = 0 to (List.length !error_line_nos) - 1 do
	  let cur_err_no = (List.nth !error_line_nos ctr) in
	Printf.fprintf stderr "%s " cur_err_no;
	Printf.printf "%s " cur_err_no;
	done;		
	);
	Printf.printf "\n";
	Printf.fprintf stderr "\n";
	
	);

        for count = 0 to (List.length per_fun) - 1 do
            let funn = (List.nth per_fun count) in
            let stmt_init_var = (List.nth per_fun_ctr count) in
            Printf.fprintf stderr "Generating shadow for func %s.\n" 
            funn.svar.vname;
                funn.sbody.bstmts <- stmt_init_var :: funn.sbody.bstmts;
            done;

        if (!intr_found = 1) then (
            Printf.fprintf stderr "File has ISRs.\n";
            if (!intr_correct = 1) then   (
                Printf.fprintf stderr "ISRs fixed.\n";
                Printf.printf "ISRs are correct.\n";
            )
            else (
                Printf.fprintf stderr "ISR Fail.";
                Printf.printf "ISR Fail.";
            )
        );
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
      (Printf.printf "### Asim is Asim\n"); *) 
      (* Error Report Generation *)
      (*
      let err_file = "error_report.dat";
      
      let oc = open_out err_file in
      Printf.fprintf oc "Error Report.\n";
      close_out oc;
      *)
      
      (* Interrupts initialization *)
      def_interrupt_fns := [];
      intr_correct := 0;
      intr_found := 0;
      
      let initVisitor : initialVisitor = new initialVisitor in
      initVisitor#top_level f;
      
      let driVisitor : driverVisitor = new driverVisitor in
      driVisitor#top_level f;
    
  end

(* The feature description for the drivers module *)  
let feature : featureDescr = 
  { fd_name = "drivers";              
    fd_enabled = ref false;
    fd_description = "Device Driver Analysis";
    fd_extraopt = [];
    fd_doit = dobeefyanalysis;
    fd_post_check = true      (*What does this do?? *) 
  } 

(*
* We cannot wait in any loop infinitely when any of the following functions are
* essential as a terminating condition for the loop. We also cannot wait for any
* funtion(s) that call these functions.

ioread8
ioread16
ioread16be
ioread32
ioread32be
iowrite8
iowrite16
iowrite16be
iowrite32
iowrite32be
ioread8_rep
ioread16_rep
ioread32_rep
iowrite8_rep
iowrite16_rep
iowrite32_rep
ioport_map
ioport_unmap
pci_iomap
pci_iounmap

*)

  
