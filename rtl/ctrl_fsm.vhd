-- SPDX-License-Identifier: Apache-2.0
--
-- Transfer controller, VHDL twin.
--
-- The same machine as rtl/ctrl_fsm.sv, written the same way: a clocked process that copies the
-- next state, and a combinational process that decides it. The top level runs both on the same
-- inputs and compares every output on every clock. See ctrl_fsm.sv for what the machine shows.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_fsm_vhd is
  port (
    clk        : in  std_logic;
    rst_n      : in  std_logic;                     -- asynchronous reset, active low
    clr        : in  std_logic;                     -- synchronous reset, active high
    abort      : in  std_logic;                     -- wins in every state
    start      : in  std_logic;
    cmd        : in  std_logic_vector(1 downto 0);
    resume     : in  std_logic;
    stop       : in  std_logic;
    last       : in  std_logic;
    busy       : out std_logic;
    pulse      : out std_logic;
    done       : out std_logic;
    fault      : out std_logic;
    beats      : out std_logic_vector(7 downto 0);
    state_code : out std_logic_vector(3 downto 0);
    sub_code   : out std_logic_vector(1 downto 0)
  );
end entity ctrl_fsm_vhd;

architecture rtl of ctrl_fsm_vhd is

  -- The outer states. Ten values: a four-bit register leaves six codes that are no state.
  type state_t is (IDLE, LOAD, RUN, HOLD, FLUSH, FINISH, ERROR, SPARE, ODD, PARK);

  -- The inner machine's states, as named constants rather than an enumeration.
  constant SA : std_logic_vector(1 downto 0) := "00";
  constant SB : std_logic_vector(1 downto 0) := "01";
  constant SC : std_logic_vector(1 downto 0) := "10";

  signal state, nxt    : state_t;
  signal sub, sub_nxt  : std_logic_vector(1 downto 0);
  signal beats_r       : unsigned(7 downto 0);

  -- Where a command sends the machine.
  function decode(c : std_logic_vector(1 downto 0)) return state_t is
  begin
    case c is
      when "00"   => return LOAD;   -- load, then run
      when "01"   => return RUN;    -- run at once
      when "10"   => return ODD;    -- a command with no state of its own
      when others => return LOAD;   -- "11" loads as well
    end case;
  end function decode;

begin

  -- The state register, with both resets.
  state_reg : process (clk, rst_n)
  begin
    if rst_n = '0' then
      state <= IDLE;
      sub   <= SA;
    elsif rising_edge(clk) then
      if clr = '1' then
        state <= IDLE;
        sub   <= SA;
      else
        state <= nxt;
        sub   <= sub_nxt;
      end if;
    end if;
  end process state_reg;

  -- A registered output: counts the clocks spent in RUN, cleared in IDLE.
  beat_count : process (clk, rst_n)
  begin
    if rst_n = '0' then
      beats_r <= (others => '0');
    elsif rising_edge(clk) then
      if state = RUN then
        beats_r <= beats_r + 1;
      elsif state = IDLE then
        beats_r <= (others => '0');
      end if;
    end if;
  end process beat_count;

  -- The next state and the outputs.
  next_state : process (all)
  begin
    nxt     <= state;   -- stay, unless an arm says otherwise
    sub_nxt <= sub;
    busy    <= '0';
    pulse   <= '0';
    done    <= '0';
    fault   <= '0';

    if abort = '1' then
      -- An abort sends every state to ERROR.
      nxt <= ERROR;
    else
      case state is
        -- Waiting for a command.
        when IDLE =>
          if start = '1' then
            -- A command arrives: decode it.
            nxt   <= decode(cmd);
            pulse <= '1';
          end if;

        -- Loading the first word.
        when LOAD =>
          busy <= '1';
          if last = '1' then
            -- A one-word transfer waits for the next command.
            nxt <= PARK;
          else
            nxt <= RUN;
          end if;

        -- Transferring. The beat counter runs inside this state.
        when RUN =>
          busy <= '1';
          case sub is
            when SA =>
              sub_nxt <= SB;
            when SB =>
              if cmd(0) = '1' then
                sub_nxt <= SC;
              end if;
            when SC =>
              sub_nxt <= SA;
            when others =>
              sub_nxt <= SA;
          end case;
          if stop = '1' then
            -- Paused by the consumer.
            nxt <= HOLD;
          elsif last = '1' then
            -- The last word went out.
            nxt <= FLUSH;
          end if;

        -- Paused.
        when HOLD =>
          if resume = '1' then
            -- Resume with a new command.
            nxt <= decode(cmd);
          elsif stop = '1' then
            -- Still stopped: stay, and say so.
            nxt <= HOLD;
          end if;

        -- Emptying the pipeline.
        when FLUSH =>
          busy  <= '1';
          pulse <= '1';
          nxt   <= FINISH;

        -- Finished; a new start returns to IDLE.
        when FINISH =>
          done <= '1';
          if start = '1' then
            nxt <= IDLE;
          end if;

        -- Aborted. Only a reset leaves this state.
        when ERROR =>
          fault <= '1';

        -- Never entered: kept for a future command.
        when SPARE =>
          nxt <= IDLE;

        -- ODD, PARK, and every code that is no state.
        when others =>
          nxt <= IDLE;
      end case;
    end if;
  end process next_state;

  beats      <= std_logic_vector(beats_r);
  state_code <= std_logic_vector(to_unsigned(state_t'pos(state), 4));
  sub_code   <= sub;

end architecture rtl;
