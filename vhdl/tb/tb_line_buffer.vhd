-- Muhammed Salman
--
-- tb_line_buffer.vhd
--
-- Self-checking testbench for line_buffer.
--
-- Drives 24 pixels with intermittent gaps (ce low) and checks that
-- pixel_out always returns the pixel accepted exactly LINE_LENGTH
-- accepted-pixels earlier.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_line_buffer is
end entity;

architecture sim of tb_line_buffer is

    constant LINE_LENGTH : positive := 8;

    signal clk       : std_logic := '0';
    signal ce        : std_logic := '0';
    signal pixel_in  : std_logic_vector(7 downto 0) := (others => '0');
    signal pixel_out : std_logic_vector(7 downto 0);

    type int_arr is array (natural range <>) of integer;
    signal history : int_arr(0 to 63) := (others => 0);
    signal accepted : integer := 0;
    signal errors   : integer := 0;
    signal checks   : integer := 0;

begin

    dut : entity work.line_buffer
        generic map (DATA_WIDTH => 8, LINE_LENGTH => LINE_LENGTH)
        port map (clk => clk, ce => ce,
                  pixel_in => pixel_in, pixel_out => pixel_out);

    clk <= not clk after 5 ns;

    count_accepted : process (clk)
    begin
        if rising_edge(clk) then
            if ce = '1' then
                accepted <= accepted + 1;
            end if;
        end if;
    end process;

    stim : process
        variable v : integer;
    begin
        wait until falling_edge(clk);
        for i in 0 to 23 loop
            -- Insert a stall cycle after every third pixel.
            if i mod 3 = 2 then
                ce <= '0';
                wait until falling_edge(clk);
                -- Output must hold the oldest pixel while stalled.
                if accepted >= LINE_LENGTH then
                    checks <= checks + 1;
                    assert pixel_out = std_logic_vector(to_unsigned(
                        history(accepted - LINE_LENGTH), 8))
                        report "stalled output mismatch"
                        severity error;
                    if pixel_out /= std_logic_vector(to_unsigned(
                        history(accepted - LINE_LENGTH), 8)) then
                        errors <= errors + 1;
                    end if;
                end if;
            end if;
            v := 100 + i;
            history(i) <= v;
            pixel_in   <= std_logic_vector(to_unsigned(v, 8));
            ce         <= '1';
            wait until falling_edge(clk);
            -- The acceptance happened at the rising edge inside the
            -- wait above; history index accepted-LINE_LENGTH is golden.
            if accepted >= LINE_LENGTH then
                checks <= checks + 1;
                assert pixel_out = std_logic_vector(to_unsigned(
                    history(accepted - LINE_LENGTH), 8))
                    report "output mismatch at pixel " & integer'image(i)
                    severity error;
                if pixel_out /= std_logic_vector(to_unsigned(
                    history(accepted - LINE_LENGTH), 8)) then
                    errors <= errors + 1;
                end if;
            end if;
            ce <= '0';
        end loop;

        if errors = 0 then
            report "PASS tb_line_buffer: " & integer'image(checks)
                   & " checks" severity note;
        else
            report "FAIL tb_line_buffer: " & integer'image(errors)
                   & " errors" severity failure;
        end if;
        finish;
    end process;

end architecture sim;
