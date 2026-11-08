// SPDX-License-Identifier: Apache-2.0
//
// Drives one item per clock, half a clock before the rising edge.
class twins_driver extends uvm_driver #(twins_item);
  virtual twins_if vif;
  `uvm_component_utils(twins_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(virtual twins_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "no virtual interface")
  endfunction

  task run_phase(uvm_phase phase);
    vif.rst_n  <= 1'b0;
    vif.clr    <= 1'b0;
    vif.abort  <= 1'b0;
    vif.start  <= 1'b0;
    vif.cmd    <= 2'b00;
    vif.resume <= 1'b0;
    vif.stop   <= 1'b0;
    vif.last   <= 1'b0;
    forever begin
      seq_item_port.get_next_item(req);
      @(negedge vif.clk);
      vif.rst_n  <= req.rst_n;
      vif.clr    <= req.clr;
      vif.abort  <= req.abort;
      vif.start  <= req.start;
      vif.cmd    <= req.cmd;
      vif.resume <= req.resume;
      vif.stop   <= req.stop;
      vif.last   <= req.last;
      seq_item_port.item_done();
    end
  endtask
endclass
