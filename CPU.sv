module CPU(output[14:0] a1, inout[15:0] d1, inout[2:0] c1, input clk, input int cache_hits, input int cache_requests);
        reg[2:0] c1_reg;
        reg[14:0] a1_reg;
        reg[15:0] d1_reg;
        reg in_or_out1;
        parameter integer CACHE_OFFSET_SIZE = 5;
        parameter integer CACHE_LINE_SIZE = 32;

        integer M;
        integer N;
        integer K;
        integer pa;
        integer pb;
        integer pc;
        integer y;
        integer x;
        integer k;
        integer s;
        reg[7:0] a_value;
        reg[15:0] b_value;

        assign a1 = a1_reg;
        assign c1 = in_or_out1 ? c1_reg : 3'bzzz;
        assign d1 = in_or_out1 ? d1_reg : 16'bzzzzzzzzzzzzzzzz;

        initial begin
        M = 64;
        #2;
        N = 60;
        #2;
        K = 32;
        #2;

        pa = 0;
        #2;
        pc = 0;
        #2;

        for (y = 0; y < M; y += 1) begin
        for (x = 0; x < N; x += 1) begin
        pb = 0;
        #2;
        s = 0;
        #2;
        for (k = 0; k < K; k += 1) begin
        c1_reg = 1;
        in_or_out1 = 1;
        a1_reg = (pa * K + k) >> CACHE_OFFSET_SIZE;
        #2;
        a1_reg = (pa * K + k) % CACHE_LINE_SIZE;
        #2;
        in_or_out1 = 0;
        #1;
        wait(c1 === 7);
        a_value = d1;

        c1_reg = 2;
        in_or_out1 = 1;
        a1_reg = (M * K + (pb * N + x) * 2) >> CACHE_OFFSET_SIZE;
        #2;
        a1_reg = (M * K + (pb * N + x) * 2) % CACHE_LINE_SIZE;
        #2;
        in_or_out1 = 0;
        #1;
        wait(c1 === 7);
        b_value = d1;

        s += a_value * b_value;
        #10;
        pb += 1;
        #2;
        #2;
        end
        c1_reg = 7;
        in_or_out1 = 1;
        a1_reg = (M * K + K * N * 2 + (pc * N + x) * 4) >> CACHE_OFFSET_SIZE;
        #2;
        a1_reg = (M * K + K * N * 2 + (pc * N + x) * 4) % CACHE_LINE_SIZE;
        #2;
        in_or_out1 = 0;
        #2;
        wait(c1 === 7);
        #2;
        end
        pa += 1;
        #2;
        pc += 1;
        #2;
        #2;
        end

        #2;
        $display("Cache hits: %0d", cache_hits);
        $display("Cache requests: %0d", cache_requests);
        $display("Tacts: %0d", $time / 2);
        $finish;
        end
        endmodule