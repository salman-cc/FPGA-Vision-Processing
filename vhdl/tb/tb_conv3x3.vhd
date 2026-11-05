-- Muhammed Salman
--
-- tb_conv3x3.vhd
--
-- Self-checking integration testbench: window_3x3 feeding two conv3x3
-- instances with different kernels over the same 8x4 frame.
--
--   conv_id:   identity kernel (K22=1, SHIFT=0) -> output = centre tap
--   conv_blur: all-ones kernel, SHIFT=4         -> floor(sum/16)
--
-- Golden results are recomputed in the testbench from the frame with
-- plain integer arithmetic.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_conv3x3 is
end entity;

architecture sim of tb_conv3x3 is

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

    signal id_out     : std_logic_vector(7 downto 0);
    signal id_valid   : std_logic;
    signal blur_out   : std_logic_vector(7 downto 0);
    signal blur_valid : std_logic;

    signal accepted : integer := 0;
    signal k_win    : integer := -1;

    type int_arr is array (natural range <>) of integer;
    signal frame : int_arr(0 to NPIX - 1);

begin

    dut_win : entity work.window_3x3
        generic map (DATA_WIDTH => 8, LINE_LENGTH => WIDTH)
        port map (
            clk => clk, rst_n => rst_n,
            pixel_valid => pixel_valid, pixel_in => pixel_in,
            p11 => p11, p12 => p12, p13 => p13,
            p21 => p21, p22 => p22, p23 => p23,
            p31 => p31, p32 => p32, p33 => p33,
            window_valid => window_valid);

    conv_id : entity work.conv3x3
        generic map (K22 => 1, SHIFT => 0)
        port map (
            clk => clk, in_valid => window_valid,
            p11 => p11, p12 => p12, p13 => p13,
            p21 => p21, p22 => p22, p23 => p23,
            p31 => p31, p32 => p32, p33 => p33,
            pixel_out => id_out, out_valid => id_valid);

    conv_blur : entity work.conv3x3
        generic map (
            K11 => 1, K12 => 1, K13 => 1,
            K21 => 1, K22 => 1, K23 => 1,
            K31 => 1, K32 => 1, K33 => 1,
            SHIFT => 4)
        port map (
            clk => clk, in_valid => window_valid,
            p11 => p11, p12 => p12, p13 => p13,
            p21 => p21, p22 => p22, p23 => p23,
            p31 => p31, p32 => p32, p33 => p33,
            pixel_out => blur_out, out_valid => blur_valid);

    clk <= not clk after 5 ns;

    track : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '1' and window_valid = '1' then
                k_win <= accepted - 1;
            end if;
            if rst_n = '1' and pixel_valid = '1' then
                accepted <= accepted + 1;
            end if;
        end if;
    end process;

    checker : process (clk)
        variable checks : integer := 0;
        variable errors : integer := 0;
        variable sum    : integer;
        variable golden : integer;
    begin
        if rising_edge(clk) then
            if rst_n = '1' and id_valid = '1' then
                -- Golden identity: the centre tap of the consumed
                -- window is frame(k_win - WIDTH - 1).
                checks := checks + 1;
                golden := frame(k_win - WIDTH - 1);
                if to_integer(unsigned(id_out)) /= golden then
                    errors := errors + 1;
                    report "id mismatch: got "
                        & integer'image(to_integer(unsigned(id_out)))
                        & " want " & integer'image(golden)
                        severity error;
                end if;
                -- Golden blur: floor(sum of the nine taps / 16).
                sum := 0;
                for i in -1 to 1 loop
                    for j in -1 to 1 loop
                        sum := sum + frame(k_win - WIDTH - 1
                                           + i * WIDTH + j);
                    end loop;
                end loop;
                checks := checks + 1;
                golden := sum / 16;
                if to_integer(unsigned(blur_out)) /= golden then
                    errors := errors + 1;
                    report "blur mismatch: got "
                        & integer'image(to_integer(unsigned(blur_out)))
                        & " want " & integer'image(golden)
                        severity error;
                end if;
            end if;
            if checks = 12 * 2 then
                if errors = 0 then
                    report "PASS tb_conv3x3: " & integer'image(checks)
                           & " checks" severity note;
                else
                    report "FAIL tb_conv3x3: " & integer'image(errors)
                           & " errors" severity failure;
                end if;
                finish;
            end if;
        end if;
    end process;

    stim : process
    begin
        for i in 0 to NPIX - 1 loop
            frame(i) <= (i * 7 + 13) mod 256;
        end loop;
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        rst_n <= '1';
        for i in 0 to NPIX - 1 loop
            wait until falling_edge(clk);
            pixel_valid <= '1';
            pixel_in    <= std_logic_vector(to_unsigned(
                               (i * 7 + 13) mod 256, 8));
        end loop;
        wait until falling_edge(clk);
        pixel_valid <= '0';
        for i in 0 to 9 loop
            wait until falling_edge(clk);
        end loop;
        report "FAIL tb_conv3x3: not enough windows seen"
               severity failure;
        finish;
    end process;

end architecture sim;
