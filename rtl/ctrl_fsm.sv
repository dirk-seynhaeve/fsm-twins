// SPDX-License-Identifier: Apache-2.0
//
// Transfer controller, SystemVerilog twin.
//
// The same machine as rtl/ctrl_fsm.vhd, written the same way: a clocked process that copies the
// next state, and a combinational process that decides it. The top level runs both on the same
// inputs and compares every output on every clock.
//
// What the machine shows, on purpose:
//   - an asynchronous active-low reset (rst_n) and a synchronous one (clr), both to IDLE;
//   - one condition that wins in every state (abort, tested before the case), to ERROR;
//   - a next state decided in a function (decode), called from two states;
//   - several transitions between the same two states;
//   - staying in a state by default, and staying by an explicit assignment;
//   - a machine inside a state (the beat counter inside RUN), encoded with named constants;
//   - a dead state (ERROR), an unreachable state (SPARE), and two states with no arm of their
//     own (ODD, PARK), handled only by the default arm;
//   - Moore outputs, Mealy outputs, defaults, and one registered output.

module ctrl_fsm_sv (
  input  logic       clk,
  input  logic       rst_n,     // asynchronous reset, active low
  input  logic       clr,       // synchronous reset, active high
  input  logic       abort,     // wins in every state
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
  output logic [1:0] sub_code
);

  // The outer states. Ten values in four bits: six codes are no state at all.
  typedef enum logic [3:0] {
    IDLE  = 4'd0,
    LOAD  = 4'd1,
    RUN   = 4'd2,
    HOLD  = 4'd3,
    FLUSH = 4'd4,
    FINISH  = 4'd5,
    ERROR = 4'd6,
    SPARE = 4'd7,
    ODD   = 4'd8,
    PARK  = 4'd9
  } state_t;

  // The inner machine's states, as named constants rather than an enumeration.
  localparam logic [1:0] SA = 2'b00;
  localparam logic [1:0] SB = 2'b01;
  localparam logic [1:0] SC = 2'b10;

  state_t     state, nxt;
  logic [1:0] sub, sub_nxt;

  // Where a command sends the machine.
  function automatic state_t decode(input logic [1:0] c);
    case (c)
      2'b00:   return LOAD;   // load, then run
      2'b01:   return RUN;    // run at once
      2'b10:   return ODD;    // a command with no state of its own
      default: return LOAD;   // 2'b11 loads as well
    endcase
  endfunction

  // The state register, with both resets.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      sub   <= SA;
    end else if (clr) begin
      state <= IDLE;
      sub   <= SA;
    end else begin
      state <= nxt;
      sub   <= sub_nxt;
    end
  end

  // A registered output: counts the clocks spent in RUN, cleared in IDLE.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      beats <= 8'd0;
    end else if (state == RUN) begin
      beats <= beats + 8'd1;
    end else if (state == IDLE) begin
      beats <= 8'd0;
    end
  end

  // The next state and the outputs.
  always_comb begin
    nxt     = state;    // stay, unless an arm says otherwise
    sub_nxt = sub;
    busy    = 1'b0;
    pulse   = 1'b0;
    done    = 1'b0;
    fault   = 1'b0;

    if (abort) begin
      // An abort sends every state to ERROR.
      nxt = ERROR;
    end else begin
      case (state)
        // Waiting for a command.
        IDLE: begin
          if (start) begin
            // A command arrives: decode it.
            nxt   = decode(cmd);
            pulse = 1'b1;
          end
        end

        // Loading the first word.
        LOAD: begin
          busy = 1'b1;
          if (last) begin
            // A one-word transfer waits for the next command.
            nxt = PARK;
          end else begin
            nxt = RUN;
          end
        end

        // Transferring. The beat counter runs inside this state.
        RUN: begin
          busy = 1'b1;
          case (sub)
            SA: sub_nxt = SB;
            SB: begin
              if (cmd[0]) begin
                sub_nxt = SC;
              end
            end
            SC: sub_nxt = SA;
            default: sub_nxt = SA;
          endcase
          if (stop) begin
            // Paused by the consumer.
            nxt = HOLD;
          end else if (last) begin
            // The last word went out.
            nxt = FLUSH;
          end
        end

        // Paused.
        HOLD: begin
          if (resume) begin
            // Resume with a new command.
            nxt = decode(cmd);
          end else if (stop) begin
            // Still stopped: stay, and say so.
            nxt = HOLD;
          end
        end

        // Emptying the pipeline.
        FLUSH: begin
          busy  = 1'b1;
          pulse = 1'b1;
          nxt   = FINISH;
        end

        // Finished; a new start returns to IDLE.
        FINISH: begin
          done = 1'b1;
          if (start) begin
            nxt = IDLE;
          end
        end

        // Aborted. Only a reset leaves this state.
        ERROR: begin
          fault = 1'b1;
        end

        // Never entered: kept for a future command.
        SPARE: begin
          nxt = IDLE;
        end

        // ODD, PARK, and every code that is no state.
        default: begin
          nxt = IDLE;
        end
      endcase
    end
  end

  assign state_code = state;
  assign sub_code   = sub;

endmodule
