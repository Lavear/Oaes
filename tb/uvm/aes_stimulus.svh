//======================================================================
// aes_stimulus.svh  -  FEATURE 1: constrained-random stimulus.
//
// Two things live here:
//   aes_item      one encryption request (a plaintext + a key)
//   aes_sequence  the generator that produces a stream of them
//======================================================================


//----------------------------------------------------------------------
// aes_item - one transaction.
//----------------------------------------------------------------------
class aes_item extends uvm_sequence_item;

    // `rand` means "the randomizer picks this value for me".
    rand bit [127:0] plain_text;
    rand bit [127:0] key;

    // No `rand` - this is the RESULT, filled in by the monitor after it
    // watches the DUT. The randomizer leaves it alone.
    bit [127:0] cipher_text;

    // Registers this class with the UVM "factory" and auto-generates
    // copy/print/compare for the listed fields. Sequence items are
    // uvm_object (not uvm_component), so it is `uvm_object_utils.
    `uvm_object_utils_begin(aes_item)
        `uvm_field_int(plain_text,  UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(key,         UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(cipher_text, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "aes_item");
        super.new(name);
    endfunction

    // ------------------------------------------------------------------
    // THE "CONSTRAINED" PART.
    //
    // Pure randomness would never test the interesting corners: the odds
    // of randomly drawing 128 zeros are 1 in 2^128. So we tell the
    // randomizer to weight its choices.
    //
    // `dist` = weighted distribution. Weights are relative, so out of
    // every ~100 items:
    //     ~5  are all zeros
    //     ~5  are all ones
    //     ~5  are 10101010...
    //     ~5  are 01010101...
    //     ~80 are anything else (the big range at the end)
    //
    // WATCH THE OPERATOR - this trips people up:
    //     :=  gives that weight to EACH value in the range
    //     :/  splits the weight ACROSS the whole range
    // The last line must use `:/`. With `:=` every one of the ~2^128
    // values in that range would get a weight of 80, and the four edge
    // cases (weight 5) would then essentially never be picked.
    // ------------------------------------------------------------------
    constraint c_plain_text {
        plain_text dist {
            128'h0000_0000_0000_0000_0000_0000_0000_0000 := 5,   // all zeros
            128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF := 5,   // all ones
            128'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA := 5,   // 1010...
            128'h5555_5555_5555_5555_5555_5555_5555_5555 := 5,   // 0101...
            [128'h1 : 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFE] :/ 80
        };
    }

    constraint c_key {
        key dist {
            128'h0000_0000_0000_0000_0000_0000_0000_0000 := 5,
            128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF := 5,
            128'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA := 5,
            128'h5555_5555_5555_5555_5555_5555_5555_5555 := 5,
            [128'h1 : 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFE] :/ 80
        };
    }

endclass


//----------------------------------------------------------------------
// aes_sequence - generates num_txn random items.
//
// A sequence is NOT a permanent component; it is a temporary object that
// runs, produces traffic, and disappears. That is why it has a body()
// task instead of build/connect/run phases.
//----------------------------------------------------------------------
class aes_sequence extends uvm_sequence #(aes_item);

    `uvm_object_utils(aes_sequence)

    int unsigned num_txn = 200;

    function new(string name = "aes_sequence");
        super.new(name);
    endfunction

    virtual task body();
        aes_item item;

        `uvm_info("SEQ", $sformatf("Sending %0d random encryptions", num_txn), UVM_LOW)

        repeat (num_txn) begin
            // create() goes through the UVM factory instead of new().
            item = aes_item::type_id::create("item");

            // The standard four-step handshake with the driver:
            //   start_item  - wait until the driver is ready
            //   randomize   - pick the values
            //   finish_item - wait until the driver has finished with it
            start_item(item);
            if (!item.randomize())
                `uvm_fatal("SEQ", "randomize() failed")
            finish_item(item);
        end
    endtask

endclass
