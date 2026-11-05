-- Muhammed Salman
--
-- sobel_edge.vhd
--
-- Sobel edge magnitude for an 8-bit greyscale 3x3 window.
--
--   Gx = (p13 + 2*p23 + p33) - (p11 + 2*p21 + p31)
--   Gy = (p31 + 2*p32 + p33) - (p11 + 2*p12 + p13)
--
-- magnitude = |Gx| + |Gy|, saturated to 255. The |Gx| + |Gy| form is
-- the common resource-light approximation of sqrt(Gx^2 + Gy^2); it
-- overestimates diagonal edges by up to about 41 percent, which is
-- acceptable for a thresholded edge flag but worth knowing when the
-- magnitude itself is consumed.
--
-- The result is registered; out_valid follows in_valid by one cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sobel_edge is
    generic (
        DATA_WIDTH : positive := 8
    );
    port (
        clk       : in  std_logic;
        in_valid  : in  std_logic;
        p11       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        p12       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        p13       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        p21       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        p22       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        p23       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        p31       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        p32       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        p33       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        pixel_out : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        out_valid : out std_logic
    );
end entity sobel_edge;

architecture rtl of sobel_edge is

    constant SUM_WIDTH : positive := DATA_WIDTH + 3;  -- max |G| = 1020
    constant MAX_OUT   : integer  := 2 ** DATA_WIDTH - 1;

    -- Zero-extend a tap into the signed gradient width.
    function ext (signal p : std_logic_vector(DATA_WIDTH - 1 downto 0))
        return signed is
    begin
        return signed(resize(unsigned(p), SUM_WIDTH));
    end function;

    signal gx, gy : signed(SUM_WIDTH - 1 downto 0);
    signal mag    : unsigned(SUM_WIDTH downto 0);

begin

    gx <= (ext(p13) + shift_left(ext(p23), 1) + ext(p33))
        - (ext(p11) + shift_left(ext(p21), 1) + ext(p31));
    gy <= (ext(p31) + shift_left(ext(p32), 1) + ext(p33))
        - (ext(p11) + shift_left(ext(p12), 1) + ext(p13));

    mag <= resize(unsigned(abs(gx)), SUM_WIDTH + 1)
         + resize(unsigned(abs(gy)), SUM_WIDTH + 1);

    process (clk)
    begin
        if rising_edge(clk) then
            if in_valid = '1' then
                if mag > to_unsigned(MAX_OUT, SUM_WIDTH + 1) then
                    pixel_out <= (others => '1');
                else
                    pixel_out <= std_logic_vector(
                        mag(DATA_WIDTH - 1 downto 0));
                end if;
                out_valid <= '1';
            else
                out_valid <= '0';
            end if;
        end if;
    end process;

end architecture rtl;
