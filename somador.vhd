library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;  -- Para calcular log2(N)

-- Entidade principal: Somador iterativo pipelined usando for generate
entity somador is
    generic (
        N : positive := 4;  -- Número de elementos a somar (deve ser >0)
        M : positive := 8   -- Bits por elemento
    );
    port (
        clk : in std_logic;  -- Clock para sincronismo
        rst : in std_logic;  -- Reset síncrono
        input : in std_logic_vector(N*M - 1 downto 0);  -- Entrada: vetor flat com N elementos de M bits
        output : out std_logic_vector(M + integer(ceil(log2(real(N)))) - 1 downto 0)  -- Saída: soma total com bits suficientes
    );
end entity somador;

architecture struct of somador is
    constant LOG2N : integer := integer(ceil(log2(real(N))));  -- Calcula log2(N) para largura da saída
    constant W : positive := M + LOG2N;  -- Largura máxima para evitar overflow (M + log2(N) bits)

    -- Tipo para array de entradas
    type input_array_t is array (0 to N-1) of unsigned(M - 1 downto 0);
    signal inputs : input_array_t;

    -- Sinais para a cadeia de soma
    type chain_array_t is array (0 to N) of unsigned(W - 1 downto 0);
    signal chain : chain_array_t;

    -- Sinal de depuração para verificar a soma intermediária
    signal debug_sum : unsigned(W - 1 downto 0);

    -- Componente: Somador combinacional de dois operandos
    component adder
        generic (
            W : positive
        );
        port (
            a, b : in unsigned(W - 1 downto 0);
            sum : out unsigned(W - 1 downto 0)
        );
    end component;

    -- Componente: Registrador síncrono
    component reg
        generic (
            W : positive
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            d : in unsigned(W - 1 downto 0);
            q : out unsigned(W - 1 downto 0)
        );
    end component;

begin
    -- Desempacota a entrada flat em um array de unsigned (estrutural com generate)
    unpack_gen: for i in 0 to N-1 generate
        inputs(i) <= unsigned(input((i+1)*M - 1 downto i*M));
    end generate;

    -- Início da cadeia: soma inicial = 0 + inputs(0), mas o primeiro adder cuida disso
    chain(0) <= (others => '0');  -- Início da cadeia com 0

    -- Geração estrutural da cadeia de somadores e registradores usando for generate
    stages_gen: for i in 0 to N-1 generate
        signal add_out : unsigned(W - 1 downto 0);  -- Saída temporária do somador
    begin
        -- Instancia o somador: adiciona a soma anterior ao input atual (resize para W bits)
        add_i : adder
            generic map (
                W => W
            )
            port map (
                a => chain(i),
                b => resize(inputs(i), W),
                sum => add_out
            );

        -- Instancia o registrador: sincroniza a saída do somador (torna pipelined)
        reg_i : reg
            generic map (
                W => W
            )
            port map (
                clk => clk,
                rst => rst,
                d => add_out,
                q => chain(i+1)
            );
    end generate;

    -- Saída final: a soma acumulada após o último estágio
    output <= std_logic_vector(chain(N));

    -- Depuração: armazena a soma final para verificação
    debug_sum <= chain(N);
end architecture struct;

-- Repetir library/use para a próxima unidade (adder)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Implementação do componente adder (combinacional)
entity adder is
    generic (
        W : positive
    );
    port (
        a, b : in unsigned(W - 1 downto 0);
        sum : out unsigned(W - 1 downto 0)
    );
end entity adder;

architecture behav of adder is
begin
    sum <= a + b;  -- Adição simples (combinacional, sem clock)
end architecture behav;

-- Repetir library/use para a próxima unidade (reg)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Implementação do componente reg (registrador síncrono)
entity reg is
    generic (
        W : positive
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        d : in unsigned(W - 1 downto 0);
        q : out unsigned(W - 1 downto 0)
    );
end entity reg;

architecture behav of reg is
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                q <= (others => '0');
            else
                q <= d;
            end if;
        end if;
    end process;
end architecture behav;
