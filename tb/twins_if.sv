// SPDX-License-Identifier: Apache-2.0
//
// The pins of fsm_twins_top, for the testbench.

interface twins_if (input logic clk);
  logic       rst_n;
  logic       clr;
  logic       abort;
  logic       start;
  logic [1:0] cmd;
  logic       resume;
  logic       stop;
  logic       last;
  logic       busy;
  logic       pulse;
  logic       done;
  logic       fault;
  logic [7:0] beats;
  logic [3:0] state_code;
  logic [1:0] sub_code;
  logic       mismatch;

  // The driver changes the inputs half a clock before the edge; the monitor reads everything
  // just before the edge, so a sample is the state and the inputs that decide the next state.
  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst_n, clr, abort, start, cmd, resume, stop, last;
    input busy, pulse, done, fault, beats, state_code, sub_code, mismatch;
  endclocking
endinterface
