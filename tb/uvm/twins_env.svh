// SPDX-License-Identifier: Apache-2.0
//
// The environment: the agent, the coverage model and the scoreboard.
class twins_env extends uvm_env;
  twins_agent      agt;
  twins_coverage   cov;
  twins_scoreboard sb;
  `uvm_component_utils(twins_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    agt = twins_agent::type_id::create("agt", this);
    cov = twins_coverage::type_id::create("cov", this);
    sb  = twins_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    agt.mon.ap.connect(cov.analysis_export);
    agt.mon.ap.connect(sb.analysis_export);
  endfunction
endclass
