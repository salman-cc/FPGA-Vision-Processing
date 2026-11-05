-- Muhammed Salman
--
-- tb_sobel_edge.vhd
--
-- Self-checking integration testbench: window_3x3 feeding sobel_edge
-- over an 8x6 frame with a vertical step edge (columns 0-3 dark,
-- columns 4-7 bright).
--
-- Golden magnitudes are recomputed in the testbench from the frame
-- with plain integer arithmetic: mag = |Gx| + |Gy| saturated at 255.
-- Directed expectations: flat interiors give 0, the two centre columns
-- straddling the step give the saturated maximum (768 -> 255).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_sobel_edge is
end entity;

architecture sim of tb_sobel_edge is

    constant WIDTH  : positive := 8;
    constant HEIGHT : positive := 6;
    constant NPIX   : positive := WIDTH * HEIGHT;

    signal clk          : std_logic := '0';
    signal rst_n        : std_logic := '0';
    signal pixel_valid  : std_logic := '0';
    signal pixel_in     : std_logic_vector(7 downto 0) := (others => '0');
    signal p11, p12, p13, p21, p22, p23, p31, p32, p33
                       : std_logic_vector(7 downto 0);
    signal window_valid : std_logic;

    signal edge_out   : std_logic_vector(7 downto 0);
    signal edge_valid : std_logic;

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

    dut_sobel : entity work.sobel_edge
        port map (
            clk => clk, in_valid => window_valid,
            p11 => p11, p12 => p12, p13 => p13,
            p21 => p21, p22 => p22, p23 => p23,
            p31 => p31, p32 => p32, p33 => p33,
            pixel_out => edge_out, out_valid => edge_valid);

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
        variable gx, gy, mag, c : integer;
    begin
        if rising_edge(clk) then
            if rst_n = '1' and edge_valid = '1' then
                -- Golden Sobel over the window ending at k_win.
                gx := (frame(k_win-16) + 2*frame(k_win-8) + frame(k_win))
                    - (frame(k_win-18) + 2*frame(k_win-10)
                       + frame(k_win-2));
                gy := (frame(k_win-2) + 2*frame(k_win-1) + frame(k_win))
                    - (frame(k_win-18) + 2*frame(k_win-17)
                       + frame(k_win-16));
                if gx < 0 then gx := -gx; end if;
                if gy < 0 then gy := -gy; end if;
                mag := gx + gy;
                if mag > 255 then mag := 255; end if;

                checks := checks + 1;
                if to_integer(unsigned(edge_out)) /= mag then
                    errors := errors + 1;
                    report "sobel mismatch: got "
                        & integer'image(to_integer(unsigned(edge_out)))
                        & " want " & integer'image(mag)
                        severity error;
                end if;

                -- Directed: only centre columns 3 and 4 see the step.
                c := (k_win mod WIDTH) - 1;
                if (c = 3 or c = 4) and mag /= 255 then
                    errors := errors + 1;
                    report "directed: centre col " & integer'image(c)
                           & " should saturate" severity error;
                end if;
                if (c = 1 or c = 2 or c = 5 or c = 6) and mag /= 0 then
                    errors := errors + 1;
                    report "directed: centre col " & integer'image(c)
                           & " should be flat" severity error;
                end if;
            end if;
            if checks = 24 then
                if errors = 0 then
                    report "PASS tb_sobel_edge: " & integer'image(checks)
                           & " checks" severity note;
                else
                    report "FAIL tb_sobel_edge: " & integer'image(errors)
                           & " errors" severity failure;
                end if;
                finish;
            end if;
        end if;
    end process;

    stim : process
    begin
        for i in 0 to NPIX - 1 loop
            if i mod WIDTH < 4 then
                frame(i) <= 32;
            else
                frame(i) <= 224;
            end if;
        end loop;
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        rst_n <= '1';
        for i in 0 to NPIX - 1 loop
            wait until falling_edge(clk);
            pixel_valid <= '1';
            if i mod WIDTH < 4 then
                pixel_in <= std_logic_vector(to_unsigned(32, 8));
            else
                pixel_in <= std_logic_vector(to_unsigned(224, 8));
            end if;
        end loop;
        wait until falling_edge(clk);
        pixel_valid <= '0';
        for i in 0 to 9 loop
            wait until falling_edge(clk);
        end loop;
        report "FAIL tb_sobel_edge: not enough windows seen"
               severity failure;
        finish;
    end process;

end architecture sim;
