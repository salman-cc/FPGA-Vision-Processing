-- Muhammed Salman
--
-- conv3x3.vhd
--
-- Single-cycle 3x3 convolution for an 8-bit greyscale window.
--
-- The nine unsigned taps and nine signed coefficients form one
-- multiply-accumulate. The accumulated sum is arithmetic-shifted right
-- by SHIFT bits and saturated into the unsigned 8-bit output range.
-- The result is registered, so the module adds one clock of latency
-- and out_valid follows in_valid by exactly one cycle.
--
-- Choosing coefficients and SHIFT is a system decision: for example a
-- 3x3 box blur uses all-ones coefficients with SHIFT 4 (divide by 16,
-- slightly darker than the true mean), while an identity pass-through
-- uses K22 = 1 with SHIFT 0.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conv3x3 is
    generic (
        DATA_WIDTH : positive := 8;
        K11 : integer := 0;
        K12 : integer := 0;
        K13 : integer := 0;
        K21 : integer := 0;
        K22 : integer := 1;
        K23 : integer := 0;
        K31 : integer := 0;
        K32 : integer := 0;
        K33 : integer := 0;
        SHIFT : natural := 0
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
end entity conv3x3;

architecture rtl of conv3x3 is

    -- 9 products of (8-bit coeff) x (9-bit unsigned tap) need at most
    -- 9 + 8 + 4 = 21 signed bits; ACC_WIDTH keeps headroom.
    constant ACC_WIDTH : positive := DATA_WIDTH + 13;
    constant MAX_OUT   : integer  := 2 ** DATA_WIDTH - 1;

    -- One zero-extended tap times one signed coefficient, resized into
    -- the accumulator width.
    function term (
        constant k : integer;
        signal   p : std_logic_vector(DATA_WIDTH - 1 downto 0))
        return signed is
    begin
        return resize(to_signed(k, 8) *
                      signed(resize(unsigned(p), DATA_WIDTH + 1)),
                      ACC_WIDTH);
    end function;

    signal acc    : signed(ACC_WIDTH - 1 downto 0);
    signal scaled : signed(ACC_WIDTH - 1 downto 0);

begin

    acc <= term(K11, p11) + term(K12, p12) + term(K13, p13)
         + term(K21, p21) + term(K22, p22) + term(K23, p23)
         + term(K31, p31) + term(K32, p32) + term(K33, p33);

    scaled <= shift_right(acc, SHIFT);

    process (clk)
    begin
        if rising_edge(clk) then
            if in_valid = '1' then
                if scaled < 0 then
                    pixel_out <= (others => '0');
                elsif scaled > to_signed(MAX_OUT, ACC_WIDTH) then
                    pixel_out <= (others => '1');
                else
                    pixel_out <= std_logic_vector(
                        unsigned(scaled(DATA_WIDTH - 1 downto 0)));
                end if;
                out_valid <= '1';
            else
                out_valid <= '0';
            end if;
        end if;
    end process;

end architecture rtl;
