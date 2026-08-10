//======================================================================
// aes_env.svh  -  the wiring.
//
// The four interesting files are stimulus / scoreboard / assertions /
// coverage. This file is the boilerplate that connects them:
//
//     sequence --> sequencer --> driver --> [ DUT pins ]
//                                              |
//                                           monitor --+--> scoreboard
//                                                     +--> coverage
//
// Read it once to see the shape, then you can mostly leave it alone.
//======================================================================


// The sequencer just hands items from a sequence to the driver. There is
// nothing to customise, so a typedef of the library class is all we need.
typedef uvm_sequencer #(aes_item) aes_sequencer;


//----------------------------------------------------------------------
// DRIVER - turns a transaction into pin wiggles.
//----------------------------------------------------------------------
class aes_driver extends uvm_driver #(aes_item);

    // `uvm_component_utils (not object_utils) because a driver is a
    // COMPONENT: it is built once and lives for the whole simulation.
    `uvm_component_utils(aes_driver)

    virtual aes_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Fetch the interface handle that tb_top put in the config
        // database. This is how classes get access to pins.
        if (!uvm_config_db#(virtual aes_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "virtual interface not set for driver")
    endfunction

    task run_phase(uvm_phase phase);
        // Park the pins somewhere safe and wait for reset to release.
        vif.drv_cb.valid_in   <= 0;
        vif.drv_cb.plain_text <= 0;
        vif.drv_cb.key        <= 0;
        wait (vif.rst_n === 1'b1);

        forever begin
            // get_next_item blocks until a sequence provides one.
            seq_item_port.get_next_item(req);
            drive(req);
            // Forgetting item_done() is the #1 cause of a UVM testbench
            // that hangs silently.
            seq_item_port.item_done();
        end
    endtask

    task drive(aes_item item);
        // Present the data and pulse valid_in for exactly ONE cycle. The
        // FSM starts on the first clock it sees start high; holding it
        // longer would kick off a second encryption immediately.
        @(vif.drv_cb);
        vif.drv_cb.plain_text <= item.plain_text;
        vif.drv_cb.key        <= item.key;
        vif.drv_cb.valid_in   <= 1;

        @(vif.drv_cb);
        vif.drv_cb.valid_in   <= 0;

        // IMPORTANT: we do NOT clear plain_text/key here. Your key
        // expansion block re-reads cipher_key during round 0, so the data
        // has to stay put for the whole encryption, not just the pulse.
        // Dropping it early gives a silently wrong ciphertext.
        do @(vif.drv_cb); while (vif.drv_cb.valid_out !== 1'b1);
    endtask

endclass


//----------------------------------------------------------------------
// MONITOR - watches the pins and rebuilds what it saw.
//
// It never drives anything, and it never looks at the driver's copy of
// the data. If it did, a driver bug would be invisible - the testbench
// would just be comparing itself against itself.
//----------------------------------------------------------------------
class aes_monitor extends uvm_monitor;

    `uvm_component_utils(aes_monitor)

    virtual aes_if vif;

    // An analysis port is a broadcast: one write() call reaches every
    // subscriber connected to it (here: scoreboard AND coverage).
    uvm_analysis_port #(aes_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual aes_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "virtual interface not set for monitor")
    endfunction

    task run_phase(uvm_phase phase);
        aes_item item;

        forever begin
            // Wait for a request to start.
            @(vif.mon_cb);
            if (vif.rst_n !== 1'b1)           continue;
            if (vif.mon_cb.valid_in !== 1'b1) continue;

            item = aes_item::type_id::create("item");
            item.plain_text = vif.mon_cb.plain_text;
            item.key        = vif.mon_cb.key;

            // Follow it until the answer comes out.
            do @(vif.mon_cb); while (vif.mon_cb.valid_out !== 1'b1);
            item.cipher_text = vif.mon_cb.cipher_text;

            // Broadcast to the scoreboard and the coverage collector.
            ap.write(item);
        end
    endtask

endclass


//----------------------------------------------------------------------
// ENVIRONMENT - builds everything and wires it together.
//----------------------------------------------------------------------
class aes_env extends uvm_env;

    `uvm_component_utils(aes_env)

    aes_sequencer  sequencer;
    aes_driver     driver;
    aes_monitor    monitor;
    aes_scoreboard scoreboard;
    aes_coverage   coverage;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // build_phase runs top-down, before anything is connected.
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sequencer  = aes_sequencer ::type_id::create("sequencer",  this);
        driver     = aes_driver    ::type_id::create("driver",     this);
        monitor    = aes_monitor   ::type_id::create("monitor",    this);
        scoreboard = aes_scoreboard::type_id::create("scoreboard", this);
        coverage   = aes_coverage  ::type_id::create("coverage",   this);
    endfunction

    // connect_phase runs bottom-up, AFTER every build_phase has finished
    // - that ordering is why it is a separate phase. You cannot connect
    // to something that has not been built yet.
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.ap.connect(scoreboard.item_imp);
        monitor.ap.connect(coverage.analysis_export);
    endfunction

endclass


//----------------------------------------------------------------------
// TEST - the top of the hierarchy. Decides what stimulus to run.
//
// `uvm_component_utils registers it by name, which is what makes
// +UVM_TESTNAME=aes_test work on the command line.
//----------------------------------------------------------------------
class aes_test extends uvm_test;

    `uvm_component_utils(aes_test)

    aes_env      env;
    int unsigned num_txn = 200;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = aes_env::type_id::create("env", this);
        // Let the command line override the run length:
        //   vsim ... +num_txn=2000
        void'($value$plusargs("num_txn=%d", num_txn));
    endfunction

    task run_phase(uvm_phase phase);
        aes_sequence seq;

        // OBJECTIONS decide when the test ends: UVM stops run_phase once
        // every objection is dropped. Forget to raise one and the
        // simulation ends at time 0 with a meaningless "pass".
        phase.raise_objection(this);

        seq = aes_sequence::type_id::create("seq");
        seq.num_txn = num_txn;
        seq.start(env.sequencer);

        #500ns;   // let the last encryption finish and get checked

        phase.drop_objection(this);
    endtask

endclass
