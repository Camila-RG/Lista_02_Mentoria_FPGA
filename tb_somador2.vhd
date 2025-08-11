library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;  -- Adicionado para ceil e log2

entity tb_somador2 is
end entity tb_somador2;

architecture test of tb_somador2 is
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

        -- Caso 1: Inputs = 00000011, 00000011, 00000011, 00000011 (3 em decimal), soma esperada = N*3 = 12
        for i in 0 to N-1 loop
            input((i+1)*M - 1 downto i*M) <= "00000011";
        end loop;
        wait for (N+1)*PERIOD;  -- Espera latência + extra

        -- Verifique output no simulador (deve ser 0000011000 para N=4, soma=12)
        assert unsigned(output) = to_unsigned(12, output'length)
            report "Erro na soma! Esperado 12, obtido " & integer'image(to_integer(unsigned(output))) severity error;

        -- Caso 2: Inputs = 00000111, 00000111, 00000111, 00000110 (7, 7, 7, 6 em decimal), soma esperada = 7 + 7 + 7 + 6 = 27
        input(31 downto 24) <= "00000111";  -- Primeiro elemento
        input(23 downto 16) <= "00000111";  -- Segundo elemento
        input(15 downto 8)  <= "00000111";  -- Terceiro elemento
        input(7 downto 0)   <= "00000110";  -- Quarto elemento
        wait for (N+1)*PERIOD;  -- Espera latência + extra

        -- Verifique output no simulador (deve ser 000011011 para 27 em 10 bits)
        assert unsigned(output) = to_unsigned(27, output'length)
            report "Erro na soma! Esperado 27, obtido " & integer'image(to_integer(unsigned(output))) severity error;

        wait;
    end process;
end architecture test;
