// SPDX-License-Identifier: Apache-2.0
//
// What the monitor saw in one clock: the inputs, and both twins' verdict.
class twins_obs extends uvm_object;
  bit       rst_n, clr, abort;
  bit [3:0] state_code;
  bit [1:0] sub_code;
  logic     mismatch;

  `uvm_object_utils(twins_obs)

  function new(string name = "twins_obs");
    super.new(name);
  endfunction
endclass
