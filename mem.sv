module mem(input[14:0] a2, inout[15:0] d2, inout[1:0] c2, input clk, input reset, input m_dump);
        parameter CACHE_LINE_SIZE = 32;
        parameter integer MEM_SIZE = 1048576;
        parameter integer MEM_POW = 20;
        parameter integer CACHE_OFFSET_SIZE = 5;

        reg[MEM_POW - 1:0] a2_reg;
        reg[2:0] c2_reg;
        reg[15:0] d2_reg;

        assign c2 = in_or_out ? c2_reg : 2'bzz;
        assign d2 = in_or_out ? d2_reg : 16'bzzzzzzzzzzzzzzzz;

        reg in_or_out;

        reg[7:0] a[0:MEM_SIZE - 1];
        integer SEED = 225526;
        integer i = 0;
        initial begin
        in_or_out = 0;
        gener;
        end

        task gener;
        for (i = 0; i < MEM_SIZE; i += 1) begin
        a[i] = $random(SEED)>>16;
        end
        endtask

        always @(posedge clk) begin
        if (reset) begin
        end
        if(m_dump) begin
        $dumpfile("m_dump.vcd");
        $dumpvars(1, mem);
        end
        case(c2)
        2: begin
        //$display("mem read line");
        a2_reg = a2 << CACHE_OFFSET_SIZE;
        c2_reg = 1;
        #199;
        in_or_out = 1;
        for (i = a2_reg; i < a2_reg + CACHE_LINE_SIZE; i += 2) begin
        d2_reg[7:0] = a[i];
        d2_reg[15:8] = a[i + 1];
        #2;
        end
        in_or_out = 0;
        end
        3: begin
        //$display("mem write line");
        a2_reg = a2 << CACHE_OFFSET_SIZE;
        for (i = 0; i < CACHE_LINE_SIZE; i += 2) begin
        a[a2_reg + i] = d2[7:0];
        a[a2_reg + i + 1] = d2[15:8];
        #2;
        end
        #(199 - CACHE_LINE_SIZE);
        c2_reg = 1;
        in_or_out = 1;
        #2;
        in_or_out = 0;
        end
        endcase
        end
        endmodule