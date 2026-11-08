// SPDX-License-Identifier: Apache-2.0
//
// Two implementations of one transfer controller, side by side: ctrl_fsm_sv (SystemVerilog) and
// ctrl_fsm_vhd (VHDL) get the same inputs, and every output is compared on every clock.
// mismatch is high in any clock where the two disagree. The outputs are the SystemVerilog twin's.

module fsm_twins_top (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       clr,
  input  logic       abort,
  input  logic       start,
  input  logic [1:0] cmd,
  input  logic       resume,
  input  logic       stop,
  input  logic       last,
  output logic       busy,
  output logic       pulse,
  output logic       done,
  output logic       fault,
  output logic [7:0] beats,
  output logic [3:0] state_code,
  output logic [1:0] sub_code,
  output logic       mismatch
);

  // Everything one twin drives, packed in one vector so the comparison cannot miss an output.
  localparam int W = 1 + 1 + 1 + 1 + 8 + 4 + 2;
  logic [W-1:0] out_sv, out_vhd;

  logic       busy_v, pulse_v, done_v, fault_v;
  logic [7:0] beats_v;
  logic [3:0] state_code_v;
  logic [1:0] sub_code_v;

  ctrl_fsm_sv u_sv (
    .clk        (clk),
    .rst_n      (rst_n),
    .clr        (clr),
    .abort      (abort),
    .start      (start),
    .cmd        (cmd),
    .resume     (resume),
    .stop       (stop),
    .last       (last),
    .busy       (busy),
    .pulse      (pulse),
    .done       (done),
    .fault      (fault),
    .beats      (beats),
    .state_code (state_code),
    .sub_code   (sub_code)
  );

  ctrl_fsm_vhd u_vhd (
    .clk        (clk),
    .rst_n      (rst_n),
    .clr        (clr),
    .abort      (abort),
    .start      (start),
    .cmd        (cmd),
    .resume     (resume),
    .stop       (stop),
    .last       (last),
    .busy       (busy_v),
    .pulse      (pulse_v),
    .done       (done_v),
    .fault      (fault_v),
    .beats      (beats_v),
    .state_code (state_code_v),
    .sub_code   (sub_code_v)
  );

  assign out_sv  = {busy,   pulse,   done,   fault,   beats,   state_code,   sub_code};
  assign out_vhd = {busy_v, pulse_v, done_v, fault_v, beats_v, state_code_v, sub_code_v};

  // Strict comparison: an X or Z on either side is a mismatch too.
  assign mismatch = (out_sv !== out_vhd);

endmodule
