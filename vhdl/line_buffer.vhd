-- Muhammed Salman
--
-- line_buffer.vhd
--
-- One-scanline delay for a streaming video pipeline.
--
-- Pixels enter through pixel_in while ce is high and leave through
-- pixel_out exactly LINE_LENGTH accepted pixels later. The buffer is a
-- circular memory so it maps onto a block RAM on most FPGAs.
--
-- The module has no frame knowledge of its own; window_3x3 uses two of
-- these plus tap registers to rebuild a 3x3 neighbourhood.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity line_buffer is
    generic (
        DATA_WIDTH  : positive := 8;
        LINE_LENGTH : positive := 640
    );
    port (
        clk       : in  std_logic;
        ce        : in  std_logic;
        pixel_in  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        pixel_out : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity line_buffer;

architecture rtl of line_buffer is
    type mem_t is array (0 to LINE_LENGTH - 1) of
        std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem    : mem_t;
    signal wr_ptr : natural range 0 to LINE_LENGTH - 1 := 0;
begin

    -- The location about to be overwritten still holds the oldest
    -- pixel, so the combinational read returns the pixel written
    -- LINE_LENGTH accepted pixels ago.
    pixel_out <= mem(wr_ptr);

    process (clk)
    begin
        if rising_edge(clk) then
            if ce = '1' then
                mem(wr_ptr) <= pixel_in;
                if wr_ptr = LINE_LENGTH - 1 then
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
