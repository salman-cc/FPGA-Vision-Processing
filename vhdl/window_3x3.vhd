-- Muhammed Salman
--
-- window_3x3.vhd
--
-- Turns a raster-scanned pixel stream into 3x3 pixel neighbourhoods.
--
-- Two line buffers delay the stream by one and two scanlines. Three
-- tap registers per row then expose the 3x3 window ending at the
-- current pixel. Pixel ordering is raster scan with a constant line
-- length of LINE_LENGTH pixels and no blanking.
--
-- Tap naming: pRC, row 1 is the oldest (two lines back), column 3 is
-- the newest pixel in each row. p22 is the window centre.
--
-- window_valid pulses high for one clock when the taps hold a complete
-- window whose centre is a real pixel. Windows that would need pixels
-- from outside the frame (first two lines, first two columns) are
-- suppressed, so downstream logic sees a (LINE_LENGTH-2) wide output
-- per line starting from the third input line.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity window_3x3 is
    generic (
        DATA_WIDTH  : positive := 8;
        LINE_LENGTH : positive := 640
    );
    port (
        clk          : in  std_logic;
        rst_n        : in  std_logic;
        pixel_valid  : in  std_logic;
        pixel_in     : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        p11          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        p12          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        p13          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        p21          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        p22          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        p23          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        p31          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        p32          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        p33          : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        window_valid : out std_logic
    );
end entity window_3x3;

architecture rtl of window_3x3 is

    component line_buffer is
        generic (
            DATA_WIDTH  : positive;
            LINE_LENGTH : positive
        );
        port (
            clk       : in  std_logic;
            ce        : in  std_logic;
            pixel_in  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
            pixel_out : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    signal line1_out : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal line2_out : std_logic_vector(DATA_WIDTH - 1 downto 0);

    signal col : natural range 0 to LINE_LENGTH - 1 := 0;
    signal row : natural := 0;

begin

    lb1 : line_buffer
        generic map (DATA_WIDTH => DATA_WIDTH, LINE_LENGTH => LINE_LENGTH)
        port map (clk => clk, ce => pixel_valid,
                  pixel_in => pixel_in, pixel_out => line1_out);

    lb2 : line_buffer
        generic map (DATA_WIDTH => DATA_WIDTH, LINE_LENGTH => LINE_LENGTH)
        port map (clk => clk, ce => pixel_valid,
                  pixel_in => line1_out, pixel_out => line2_out);

    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                col <= 0;
                row <= 0;
                p11 <= (others => '0'); p12 <= (others => '0');
                p13 <= (others => '0');
                p21 <= (others => '0'); p22 <= (others => '0');
                p23 <= (others => '0');
                p31 <= (others => '0'); p32 <= (others => '0');
                p33 <= (others => '0');
                window_valid <= '0';
            elsif pixel_valid = '1' then
                p11 <= p12; p12 <= p13; p13 <= line2_out;
                p21 <= p22; p22 <= p23; p23 <= line1_out;
                p31 <= p32; p32 <= p33; p33 <= pixel_in;
                -- A full window exists once at least two earlier pixels
                -- on this line and two earlier lines were accepted.
                if col >= 2 and row >= 2 then
                    window_valid <= '1';
                else
                    window_valid <= '0';
                end if;
                if col = LINE_LENGTH - 1 then
                    col <= 0;
                    row <= row + 1;
                else
                    col <= col + 1;
                end if;
            else
                window_valid <= '0';
            end if;
        end if;
    end process;

end architecture rtl;
