//======================================================================
// aes_pkg.sv  -  bundles all the classes into one namespace.
//
// The `include order matters: each file is pasted in where it appears,
// so a class must come after anything it uses.
//======================================================================

package aes_pkg;

    // uvm_macros.svh is INCLUDED because macros (`uvm_info, `uvm_fatal,
    // `uvm_component_utils) are preprocessor text.
    // uvm_pkg is IMPORTED because those are compiled classes.
    // Two different mechanisms - you need both.
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    `include "aes_reference.svh"   //     the golden model aes_encrypt() itself
    `include "aes_stimulus.svh"    // [1] transaction + random sequence
    `include "aes_scoreboard.svh"  // [2] calls aes_encrypt(), compares
    `include "aes_coverage.svh"    // [4] functional coverage
    `include "aes_env.svh"         //     driver, monitor, env, test

    // [3] the assertions are a MODULE, not a class, so they live outside
    //     this package - see aes_assertions.sv

endpackage
