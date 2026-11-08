// SPDX-License-Identifier: Apache-2.0
//
// The directed tour: every state the machine can reach and every transition it can take, in one
// walk from reset. Then random traffic on top of it.

class twins_base_seq extends uvm_sequence #(twins_item);
  `uvm_object_utils(twins_base_seq)

  function new(string name = "twins_base_seq");
    super.new(name);
  endfunction

  // One clock with the given inputs; everything not named is inactive.
  task step(bit rst_n = 1, bit clr = 0, bit abort = 0, bit start = 0, bit [1:0] cmd = 2'b00,
            bit resume = 0, bit stop = 0, bit last = 0, int unsigned times = 1);
    repeat (times) begin
      twins_item it = twins_item::type_id::create("it");
      start_item(it);
      it.rst_n  = rst_n;
      it.clr    = clr;
      it.abort  = abort;
      it.start  = start;
      it.cmd    = cmd;
      it.resume = resume;
      it.stop   = stop;
      it.last   = last;
      finish_item(it);
    end
  endtask
endclass

class twins_tour_seq extends twins_base_seq;
  `uvm_object_utils(twins_tour_seq)

  function new(string name = "twins_tour_seq");
    super.new(name);
  endfunction

  task body();
    step(.rst_n(0), .times(2));                        // reset: IDLE

    // The main path, and every way to stay.
    step();                                            // IDLE stays
    step(.start(1), .cmd(2'b00));                      // IDLE -> LOAD (decode: load)
    step();                                            // LOAD -> RUN
    step(.times(3));                                   // RUN stays; inner SA -> SB, SB stays
    step(.cmd(2'b01));                                 // RUN stays; inner SB -> SC
    step();                                            // RUN stays; inner SC -> SA
    step(.stop(1));                                    // RUN -> HOLD
    step(.stop(1));                                    // HOLD stays, said so
    step();                                            // HOLD stays by default
    step(.resume(1), .cmd(2'b01));                     // HOLD -> RUN (decode: run)
    step();                                            // RUN stays
    step(.last(1));                                    // RUN -> FLUSH
    step();                                            // FLUSH -> FINISH
    step();                                            // FINISH stays
    step(.start(1));                                   // FINISH -> IDLE

    // The other decoded commands, and the states with no arm of their own.
    step(.start(1), .cmd(2'b01));                      // IDLE -> RUN (decode: run)
    step(.stop(1));                                    // RUN -> HOLD
    step(.resume(1), .cmd(2'b00));                     // HOLD -> LOAD (decode: load)
    step(.last(1));                                    // LOAD -> PARK
    step();                                            // PARK -> IDLE (default arm)
    step(.start(1), .cmd(2'b10));                      // IDLE -> ODD (decode: odd)
    step();                                            // ODD -> IDLE (default arm)
    step(.start(1), .cmd(2'b11));                      // IDLE -> LOAD (decode: 11 loads)
    step();                                            // LOAD -> RUN
    step(.stop(1));                                    // RUN -> HOLD
    step(.resume(1), .cmd(2'b10));                     // HOLD -> ODD (decode: odd)
    step();                                            // ODD -> IDLE
    step(.start(1), .cmd(2'b11));                      // IDLE -> LOAD
    step();                                            // LOAD -> RUN
    step(.stop(1));                                    // RUN -> HOLD
    step(.resume(1), .cmd(2'b11));                     // HOLD -> LOAD (decode: 11 loads)
    step(.last(1));                                    // LOAD -> PARK
    step();                                            // PARK -> IDLE

    // abort from every state that can be reached; ERROR stays until a reset.
    step(.abort(1));                                   // IDLE -> ERROR
    step(.times(2));                                   // ERROR stays
    step(.clr(1));                                     // synchronous reset: IDLE
    step(.start(1), .cmd(2'b00));  step(.abort(1)); step(); // LOAD -> ERROR
    step(.clr(1));
    step(.start(1), .cmd(2'b01));  step(.abort(1)); step(); // RUN -> ERROR
    step(.rst_n(0));                                   // asynchronous reset: IDLE
    step(.start(1), .cmd(2'b01));  step(.stop(1));
    step(.abort(1)); step();                           // HOLD -> ERROR
    step(.clr(1));
    step(.start(1), .cmd(2'b01));  step(.last(1));
    step(.abort(1)); step();                           // FLUSH -> ERROR
    step(.clr(1));
    step(.start(1), .cmd(2'b01));  step(.last(1));  step();
    step(.abort(1)); step();                           // FINISH -> ERROR
    step(.clr(1));
    step(.start(1), .cmd(2'b10));  step(.abort(1)); step(); // ODD -> ERROR
    step(.clr(1));
    step(.start(1), .cmd(2'b00));  step(.last(1));
    step(.abort(1)); step();                           // PARK -> ERROR
    step(.clr(1));
    step(.times(2));
  endtask
endclass

class twins_random_seq extends twins_base_seq;
  int unsigned n = 3000;   // clocks of random traffic; +TWINS_RANDOM_CLOCKS=<n> overrides
  `uvm_object_utils(twins_random_seq)

  function new(string name = "twins_random_seq");
    super.new(name);
    void'($value$plusargs("TWINS_RANDOM_CLOCKS=%d", n));
  endfunction

  task body();
    repeat (n) begin
      twins_item it = twins_item::type_id::create("it");
      start_item(it);
      it.fill_random();
      finish_item(it);
    end
  endtask
endclass
