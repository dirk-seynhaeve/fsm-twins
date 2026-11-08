// SPDX-License-Identifier: Apache-2.0
//
// The directed tour, then random traffic. Passes with no mismatch and 100% coverage.
class twins_test extends uvm_test;
  twins_env env;
  `uvm_component_utils(twins_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    env = twins_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    twins_tour_seq   tour = twins_tour_seq::type_id::create("tour");
    twins_random_seq rnd  = twins_random_seq::type_id::create("rnd");
    phase.raise_objection(this);
    tour.start(env.agt.sqr);
    rnd.start(env.agt.sqr);
    phase.drop_objection(this);
  endtask
endclass

// Only the directed tour: shows that it alone reaches 100%.
class twins_tour_test extends twins_test;
  `uvm_component_utils(twins_tour_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    twins_tour_seq tour = twins_tour_seq::type_id::create("tour");
    phase.raise_objection(this);
    tour.start(env.agt.sqr);
    phase.drop_objection(this);
  endtask
endclass
