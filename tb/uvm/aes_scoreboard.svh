//======================================================================
// aes_scoreboard.svh  -  FEATURE 2: the "answer key".
//
// The monitor hands us what the hardware produced. We ask a known-good
// AES (aes_encrypt(), in aes_reference.svh) what the answer SHOULD be,
// and compare.
//======================================================================

class aes_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(aes_scoreboard)

    // This is the "inbox" the monitor posts transactions into. Declaring
    // a uvm_analysis_imp obliges us to provide a `write()` function.
    uvm_analysis_imp #(aes_item, aes_scoreboard) item_imp;

    int unsigned num_passed;
    int unsigned num_failed;

    // Components take (name, parent) - the parent is what puts them in
    // the UVM hierarchy.
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_imp = new("item_imp", this);
    endfunction

    // ------------------------------------------------------------------
    // write() is called by the monitor for every encryption it saw.
    // It is a function, not a task, so it takes zero simulation time.
    // ------------------------------------------------------------------
    virtual function void write(aes_item t);
        bit [127:0] expected;

        // Ask the reference model (aes_reference.svh) for the correct
        // answer.
        expected = aes_encrypt(t.plain_text, t.key);

        if (t.cipher_text === expected) begin
            num_passed++;
            // UVM_HIGH keeps passes out of the log by default - a log
            // with one line per pass is a log nobody reads.
            `uvm_info("SB", $sformatf("PASS ct=%032h", t.cipher_text), UVM_HIGH)
        end
        else begin
            num_failed++;
            // `uvm_error, not `uvm_fatal, so a long run reports EVERY bad
            // vector instead of stopping at the first one.
            `uvm_error("SB", $sformatf(
                "MISMATCH\n  plain_text     = %032h\n  key            = %032h\n  DUT gave       = %032h\n  reference gave = %032h",
                t.plain_text, t.key, t.cipher_text, expected))
        end
    endfunction

    // report_phase runs at the very end of the simulation.
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SB", $sformatf("\n  SCOREBOARD: %0d passed, %0d failed",
                                  num_passed, num_failed), UVM_NONE)
        // A run that checked nothing at all must not look like a pass.
        if (num_passed + num_failed == 0)
            `uvm_error("SB", "Scoreboard checked ZERO transactions")
    endfunction

endclass
