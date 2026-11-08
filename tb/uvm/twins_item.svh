// SPDX-License-Identifier: Apache-2.0
//
// One clock of inputs.
//
// No rand fields and no randomize(): the bench must also run on simulators whose free editions
// leave out constrained randomization. Random traffic comes from $urandom, with the same
// weights a constraint would give.
class twins_item extends uvm_sequence_item;
  bit       rst_n = 1;
  bit       clr;
  bit       abort;
  bit       start;
  bit [1:0] cmd;
  bit       resume;
  bit       stop;
  bit       last;

  `uvm_object_utils_begin(twins_item)
    `uvm_field_int(rst_n,  UVM_ALL_ON)
    `uvm_field_int(clr,    UVM_ALL_ON)
    `uvm_field_int(abort,  UVM_ALL_ON)
    `uvm_field_int(start,  UVM_ALL_ON)
    `uvm_field_int(cmd,    UVM_ALL_ON)
    `uvm_field_int(resume, UVM_ALL_ON)
    `uvm_field_int(stop,   UVM_ALL_ON)
    `uvm_field_int(last,   UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "twins_item");
    super.new(name);
  endfunction

  // True with a chance of num in den.
  static function bit chance(int unsigned num, int unsigned den);
    return $urandom_range(den - 1) < num;
  endfunction

  // Random traffic: resets and aborts are rare, the rest is busy.
  function void fill_random();
    rst_n  = !chance(1, 500);
    clr    = chance(2, 100);
    abort  = chance(3, 100);
    start  = chance(2, 5);
    cmd    = $urandom_range(3);
    resume = chance(1, 4);
    stop   = chance(1, 5);
    last   = chance(1, 5);
  endfunction
endclass
