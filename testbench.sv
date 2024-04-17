`include "cache.sv"
`include "CPU.sv"
`include "mem.sv"

module testbench();
        parameter integer CACHE_WAY = 2;
        parameter integer CACHE_LINE_SIZE = 32;
        parameter integer CACHE_LINE_COUNT = 32;
        parameter integer CACHE_SETS_COUNT = 16;
        parameter integer CACHE_ADDR_SIZE = 20;
        parameter integer CACHE_OFFSET_SIZE = 5;
        parameter integer CACHE_TAG_SIZE = 11;
        parameter integer CACHE_SET_SIZE = 4;
        parameter integer CACHE_SIZE = 1024;
        parameter integer MEM_SIZE = 2 ** 20;
        parameter integer ADDR1_BUS_SIZE = 15;
        parameter integer ADDR2_BUS_SIZE = 15;
        parameter integer DATA1_BUS_SIZE = 16;
        parameter integer DATA2_BUS_SIZE = 16;
        parameter integer CTR1_BUS_SIZE = 3;
        parameter integer CTR2_BUS_SIZE = 2;

        wire[ADDR1_BUS_SIZE - 1:0] a1;
        reg[ADDR1_BUS_SIZE - 1:0] a1Reg;
        wire[ADDR2_BUS_SIZE - 1:0] a2;
        wire[DATA1_BUS_SIZE - 1:0] d1;
        wire[DATA2_BUS_SIZE - 1:0] d2;
        wire[CTR1_BUS_SIZE - 1:0] c1;
        wire[CTR2_BUS_SIZE - 1:0] c2;
        reg c_dump;
        reg m_dump;
        reg reset;

        wire int cache_hits;
        wire int cache_requests;

        reg clkReg;
        wire clk;
        integer x;
        integer y;

        assign clk = clkReg;
        always #1 clkReg = ~clkReg;

        cache cache(.a1(a1), .c1(c1), .d1(d1), .a2(a2), .d2(d2), .c2(c2), .clk(clk), .cache_hits(cache_hits), .cache_requests(cache_requests), .c_dump(c_dump), .reset(reset));
        CPU cpu(.a1(a1), .c1(c1), .d1(d1), .clk(clk), .cache_hits(cache_hits), .cache_requests(cache_requests));
        mem mem(.a2(a2), .c2(c2), .d2(d2), .clk(clk), .m_dump(m_dump), .reset(reset));

        initial begin
        clkReg = 0;
        m_dump = 0;
        c_dump = 0;
        reset = 0;
        end
        endmodule