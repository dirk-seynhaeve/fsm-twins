// SPDX-License-Identifier: Apache-2.0
//
// The two twins must agree on every output in every clock.
class twins_scoreboard extends uvm_subscriber #(twins_obs);
  `uvm_component_utils(twins_scoreboard)

  int unsigned clocks, compared, mismatches;
  bit seen_reset;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void write(twins_obs t);
    clocks++;
    if (t.rst_n === 1'b0) seen_reset = 1;
    if (!seen_reset) return;        // before the first reset, both twins are unknown
    compared++;
    if (t.mismatch !== 1'b0) begin
      mismatches++;
      if (mismatches <= 10)
        `uvm_error("MISMATCH", $sformatf(
          "the VHDL and SystemVerilog twins disagree (state code %0d)", t.state_code))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SCOREBOARD", $sformatf("%0d clocks, %0d compared, %0d mismatches",
                                      clocks, compared, mismatches), UVM_NONE)
    if (compared == 0) `uvm_error("SCOREBOARD", "nothing was compared")
  endfunction
endclass
