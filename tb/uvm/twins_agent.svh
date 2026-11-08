// SPDX-License-Identifier: Apache-2.0
//
// The agent: a sequencer and a driver for the inputs, and a monitor for everything.
class twins_agent extends uvm_agent;
  uvm_sequencer #(twins_item) sqr;
  twins_driver  drv;
  twins_monitor mon;
  `uvm_component_utils(twins_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    mon = twins_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = uvm_sequencer #(twins_item)::type_id::create("sqr", this);
      drv = twins_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
