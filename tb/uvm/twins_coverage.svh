// SPDX-License-Identifier: Apache-2.0
//
// Functional coverage of the machine: every state it can reach, every transition it can take,
// and the inner machine inside RUN. Sampled once per clock, from what the monitor saw.
//
// Counted by the bench itself rather than with covergroups, so that it also runs on simulators
// whose free editions leave covergroups out. Each bin is a name and what hits it; 100% means
// every bin was hit at least once.
//
// SPARE is unreachable by design (nothing enters it), so it has no bin: 100% means every
// reachable state and transition. A code that is no state at all is an error.
class twins_coverage extends uvm_subscriber #(twins_obs);
  `uvm_component_utils(twins_coverage)

  // The outer machine's states, by code, and its transitions, as "FROM>TO".
  string state_name[int] = '{0: "IDLE", 1: "LOAD", 2: "RUN", 3: "HOLD", 4: "FLUSH",
                             5: "FINISH", 6: "ERROR", 7: "SPARE", 8: "ODD", 9: "PARK"};
  string outer_states[$] = '{"IDLE", "LOAD", "RUN", "HOLD", "FLUSH", "FINISH", "ERROR", "ODD",
                             "PARK"};
  string outer_trans[$] = '{
    // Staying.
    "IDLE>IDLE", "RUN>RUN", "HOLD>HOLD", "FINISH>FINISH", "ERROR>ERROR",
    // Going.
    "IDLE>LOAD", "IDLE>RUN", "IDLE>ODD", "LOAD>RUN", "LOAD>PARK", "RUN>HOLD", "RUN>FLUSH",
    "HOLD>LOAD", "HOLD>RUN", "HOLD>ODD", "FLUSH>FINISH", "FINISH>IDLE", "ODD>IDLE",
    "PARK>IDLE",
    // abort, from every state that can be reached.
    "IDLE>ERROR", "LOAD>ERROR", "RUN>ERROR", "HOLD>ERROR", "FLUSH>ERROR", "FINISH>ERROR",
    "ODD>ERROR", "PARK>ERROR"};

  // The inner machine inside RUN.
  string sub_name[int] = '{0: "SA", 1: "SB", 2: "SC"};
  string inner_states[$] = '{"SA", "SB", "SC"};
  string inner_trans[$]  = '{"SA>SB", "SB>SB", "SB>SC", "SC>SA"};

  int unsigned hits[string];     // every bin hit, with how often
  string       prev_state, prev_sub;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void hit(string bin);
    if (hits.exists(bin)) hits[bin]++;
    else hits[bin] = 1;
  endfunction

  function void write(twins_obs t);
    string s, u;
    // Before the first reset the state is unknown, and a reset is not a transition of the
    // machine: start the history again.
    if (t.rst_n !== 1'b1 || t.clr) begin
      prev_state = "";
      prev_sub   = "";
      return;
    end
    if (!state_name.exists(t.state_code)) begin
      `uvm_error("COVERAGE", $sformatf("state code %0d is no state", t.state_code))
      return;
    end
    s = state_name[t.state_code];
    hit({"state ", s});
    if (prev_state != "") hit({"trans ", prev_state, ">", s});
    prev_state = s;

    // The inner machine counts only while RUN holds it.
    if (s == "RUN") begin
      if (!sub_name.exists(t.sub_code)) begin
        `uvm_error("COVERAGE", $sformatf("inner code %0d is no state", t.sub_code))
        return;
      end
      u = sub_name[t.sub_code];
      hit({"inner ", u});
      if (prev_sub != "") hit({"inner ", prev_sub, ">", u});
      prev_sub = u;
    end else begin
      prev_sub = "";
    end
  endfunction

  // Percentage of the bins in the list that were hit; names the ones that were not.
  function real percent(string kind, string bin_list[$], ref string missing[$]);
    int unsigned got = 0;
    foreach (bin_list[i]) begin
      if (hits.exists({kind, " ", bin_list[i]})) got++;
      else missing.push_back({kind, " ", bin_list[i]});
    end
    return 100.0 * got / bin_list.size();
  endfunction

  function void report_phase(uvm_phase phase);
    string missing[$];
    real s  = percent("state", outer_states, missing);
    real tr = percent("trans", outer_trans,  missing);
    real i  = percent("inner", inner_states, missing);
    real it = percent("inner", inner_trans,  missing);
    `uvm_info("COVERAGE", $sformatf(
      "states %0.1f%% (%0d), transitions %0.1f%% (%0d), inner states %0.1f%% (%0d), inner transitions %0.1f%% (%0d)",
      s, outer_states.size(), tr, outer_trans.size(), i, inner_states.size(), it,
      inner_trans.size()), UVM_NONE)
    if (hits.exists("state SPARE"))
      `uvm_error("COVERAGE", "SPARE was entered, but nothing should enter it")
    foreach (missing[k]) `uvm_error("COVERAGE", {"not covered: ", missing[k]})
  endfunction
endclass
