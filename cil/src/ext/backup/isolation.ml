(* Analysis to perform sfi to specific code paths 
 *
 * 1. Locate the call to start_isolate(). 
 *
 * 2. Check all memory writes for kernel writes.
 *
 * 3. Check all kernel addresses being sent to device.  
 *
 * 4. Check all device data being used.
 * 
 * 5. Also perform CFI.
 *  
 *)

