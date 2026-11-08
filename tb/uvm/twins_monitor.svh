// SPDX-License-Identifier: Apache-2.0
//
// Reads the pins just before every rising edge and publishes what it saw.
class twins_monitor extends uvm_monitor;
  virtual twins_if vif;
  uvm_analysis_port #(twins_obs) ap;
  `uvm_component_utils(twins_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(virtual twins_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "no virtual interface")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      twins_obs o;
      @(vif.mon_cb);
      o = twins_obs::type_id::create("o");
      o.rst_n      = vif.mon_cb.rst_n;
      o.clr        = vif.mon_cb.clr;
      o.abort      = vif.mon_cb.abort;
      o.state_code = vif.mon_cb.state_code;
      o.sub_code   = vif.mon_cb.sub_code;
      o.mismatch   = vif.mon_cb.mismatch;
      ap.write(o);
    end
  endtask
endclass
