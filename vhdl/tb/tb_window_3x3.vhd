-- Muhammed Salman
--
-- tb_window_3x3.vhd
--
-- Self-checking testbench for window_3x3.
--
-- Streams an 8x4 frame whose pixel values equal their linear index
-- plus one. For every asserted window_valid the nine taps are compared
-- against the golden frame positions: acceptance k must produce the
-- window ending at k, i.e. taps k-18 .. k (top-left to bottom-right).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_window_3x3 is
end entity;

architecture sim of tb_window_3x3 is

    constant WIDTH  : positive := 8;
    constant HEIGHT : positive := 4;
    constant NPIX   : positive := WIDTH * HEIGHT;

    signal clk          : std_logic := '0';
    signal rst_n        : std_logic := '0';
    signal pixel_valid  : std_logic := '0';
    signal pixel_in     : std_logic_vector(7 downto 0) := (others => '0');
    signal p11, p12, p13, p21, p22, p23, p31, p32, p33
                       : std_logic_vector(7 downto 0);
    signal window_valid : std_logic;

    signal accepted : integer := 0;

begin

    dut : entity work.window_3x3
        generic map (DATA_WIDTH => 8, LINE_LENGTH => WIDTH)
        port map (
            clk => clk, rst_n => rst_n,
            pixel_valid => pixel_valid, pixel_in => pixel_in,
            p11 => p11, p12 => p12, p13 => p13,
            p21 => p21, p22 => p22, p23 => p23,
            p31 => p31, p32 => p32, p33 => p33,
            window_valid => window_valid);

    clk <= not clk after 5 ns;

    count_accepted : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '1' and pixel_valid = '1' then
                accepted <= accepted + 1;
            end if;
        end if;
    end process;

    checker : process (clk)
        variable kw     : integer;
        variable checks : integer := 0;
        variable errors : integer := 0;

        procedure check_tap (
            signal got  : in std_logic_vector(7 downto 0);
            constant idx : in integer) is
        begin
            checks := checks + 1;
            if to_integer(unsigned(got)) /= idx + 1 then
                errors := errors + 1;
                report "tap mismatch: got "
                       & integer'image(to_integer(unsigned(got)))
                       & " want " & integer'image(idx + 1)
                       severity error;
            end if;
        end procedure;
    begin
        if rising_edge(clk) then
            if rst_n = '1' and window_valid = '1' then
                kw := accepted - 1;
                check_tap(p11, kw - 2 * WIDTH - 2);
                check_tap(p12, kw - 2 * WIDTH - 1);
                check_tap(p13, kw - 2 * WIDTH);
                check_tap(p21, kw - WIDTH - 2);
                check_tap(p22, kw - WIDTH - 1);
                check_tap(p23, kw - WIDTH);
                check_tap(p31, kw - 2);
                check_tap(p32, kw - 1);
                check_tap(p33, kw);
            end if;
            if checks = 12 * 9 and errors = 0 then
                report "PASS tb_window_3x3: " & integer'image(checks)
                       & " checks" severity note;
                finish;
            elsif checks = 12 * 9 then
                report "FAIL tb_window_3x3: " & integer'image(errors)
                       & " errors" severity failure;
                finish;
            end if;
        end if;
    end process;

    stim : process
    begin
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        rst_n <= '1';
        for i in 0 to NPIX - 1 loop
            wait until falling_edge(clk);
            pixel_valid <= '1';
            pixel_in    <= std_logic_vector(to_unsigned(i + 1, 8));
        end loop;
        wait until falling_edge(clk);
        pixel_valid <= '0';
        -- Safety net: if the checker never saw enough windows, fail.
        for i in 0 to 9 loop
            wait until falling_edge(clk);
        end loop;
        report "FAIL tb_window_3x3: not enough windows seen"
               severity failure;
        finish;
    end process;

end architecture sim;
