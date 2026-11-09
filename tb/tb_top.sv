// SPDX-License-Identifier: Apache-2.0
//
// Testbench top: a clock, the design, and the UVM test. Pick the test with +UVM_TESTNAME
// (twins_test by default).

module tb_top;
  import uvm_pkg::*;
  import twins_uvm_pkg::*;

  logic clk = 1'b0;
  always #5 clk = ~clk;

  twins_if vif (clk);

  fsm_twins_top dut (
    .clk        (clk),
    .rst_n      (vif.rst_n),
    .clr        (vif.clr),
    .abort      (vif.abort),
    .start      (vif.start),
    .cmd        (vif.cmd),
    .resume     (vif.resume),
    .stop       (vif.stop),
    .last       (vif.last),
    .busy       (vif.busy),
    .pulse      (vif.pulse),
    .done       (vif.done),
    .fault      (vif.fault),
    .beats      (vif.beats),
    .state_code (vif.state_code),
    .sub_code   (vif.sub_code),
    .mismatch   (vif.mismatch)
  );

  initial begin
    uvm_config_db #(virtual twins_if)::set(null, "uvm_test_top*", "vif", vif);
    run_test("twins_test");
  end
endmodule
