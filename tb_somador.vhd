library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;  -- Adicionado para ceil e log2

entity tb_somador is
end entity tb_somador;

architecture test of tb_somador is
    constant N : positive := 4;
    constant M : positive := 8;
    constant PERIOD : time := 10 ns;  -- Período do clock (100 MHz)

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal input : std_logic_vector(N*M - 1 downto 0) := (others => '0');
    signal output : std_logic_vector(M + integer(ceil(log2(real(N)))) - 1 downto 0);

begin
    -- Instancia o DUT (Device Under Test)
    dut : entity work.somador
        generic map (N => N, M => M)
        port map (clk => clk, rst => rst, input => input, output => output);

    -- Geração de clock
    clk_proc: process
    begin
        clk <= '0';
        wait for PERIOD/2;
        clk <= '1';
        wait for PERIOD/2;
    end process;

    -- Estímulos
    stim_proc: process
    begin
        rst <= '1';  -- Reset inicial
        wait for 2*PERIOD;
        rst <= '0';

        -- Exemplo: Todos inputs = 00000001 (1 em decimal), soma esperada = N*1 = 4
        for i in 0 to N-1 loop
            input((i+1)*M - 1 downto i*M) <= "00000001";
        end loop;
        wait for (N+1)*PERIOD;  -- Espera latência + extra

        -- Output no simulador (00000100 para N=4)
        assert unsigned(output) = to_unsigned(N, output'length)
            report "Erro na soma!" severity error;

        wait;
    end process;
end architecture test;
