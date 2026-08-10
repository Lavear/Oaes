//======================================================================
// aes_coverage.svh  -  FEATURE 4: the functional coverage "checklist".
//
// The scoreboard answers "was the answer right?". Coverage answers the
// other question: "did we actually TEST the cases we said we would?"
//
// At the end of the run it prints a percentage. 100% means every box on
// the checklist below got ticked at least once.
//======================================================================

// uvm_subscriber is a small helper base class: it already contains the
// `analysis_export` that the monitor plugs into, so all we have to write
// is write().
class aes_coverage extends uvm_subscriber #(aes_item);

    `uvm_component_utils(aes_coverage)

    // A covergroup samples VARIABLES, so we park the transaction here
    // first and then call sample().
    aes_item item;

    covergroup cg;
        option.per_instance = 1;

        // Each `bins` is one box on the checklist. Naming them matters:
        // a report saying "all_zeros: 12 hits" is something you can show
        // someone, "auto_bin_3: 12 hits" is not.
        cp_plain_text : coverpoint item.plain_text {
            bins all_zeros = {128'h0000_0000_0000_0000_0000_0000_0000_0000};
            bins all_ones  = {128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF};
            bins alt_aaaa  = {128'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA};
            bins alt_5555  = {128'h5555_5555_5555_5555_5555_5555_5555_5555};
            bins other     = default;   // everything the randomizer picked
        }

        cp_key : coverpoint item.key {
            bins all_zeros = {128'h0000_0000_0000_0000_0000_0000_0000_0000};
            bins all_ones  = {128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF};
            bins alt_aaaa  = {128'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA};
            bins alt_5555  = {128'h5555_5555_5555_5555_5555_5555_5555_5555};
            bins other     = default;
        }

        // A `cross` checks COMBINATIONS. Hitting "plaintext all zeros"
        // and "key all ones" on separate runs is much weaker than hitting
        // them at the same time. This gives 16 combination boxes.
        // (The `other` default bins are excluded from crosses by the
        // language, which is why it is 4x4 and not 5x5.)
        cx_pt_key : cross cp_plain_text, cp_key;
    endgroup

    // A covergroup is an object: it must be built with new(), and it has
    // to happen in the constructor. Forgetting this is the most common
    // beginner crash - a null handle on the first sample().
    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    // uvm_subscriber requires us to define write(). The monitor calls it.
    virtual function void write(aes_item t);
        item = t;
        cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", $sformatf("\n  FUNCTIONAL COVERAGE: %0.2f %%",
                                   cg.get_inst_coverage()), UVM_NONE)
    endfunction

endclass
