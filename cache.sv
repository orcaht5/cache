module cache(input[14:0] a1, inout[15:0] d1, inout[2:0] c1, output[14:0] a2, inout[15:0] d2, inout[1:0] c2, input clk, input reset, input c_dump, output int cache_hits, output int cache_requests);
        parameter integer CACHE_WAY = 2;
        parameter integer CACHE_LINE_SIZE = 32;
        parameter integer CACHE_LINE_COUNT = 32;
        parameter integer CACHE_SETS_COUNT = 16;
        parameter integer CACHE_ADDR_SIZE = 20;
        parameter integer CACHE_OFFSET_SIZE = 5;
        parameter integer CACHE_TAG_SIZE = 11;
        parameter integer CACHE_SET_SIZE = 4;
        parameter integer CACHE_SIZE = 1024;

        reg[2:0] c1_reg;
        reg[2:0] c2_reg;
        reg[14:0] a1_reg;
        reg[14:0] a2_reg;
        reg[15:0] d1_reg;
        reg[15:0] d2_reg;
        reg[15:0] d1_reg2;

        int cache_hits_count;
        int cache_requests_count;

        reg in_or_out1;
        reg in_or_out2;

        reg[CACHE_TAG_SIZE - 1:0] tag[0:CACHE_WAY - 1][0:CACHE_SETS_COUNT - 1];
        reg is_valid[0:CACHE_WAY - 1][0:CACHE_SETS_COUNT - 1];
        reg dirty[0:CACHE_WAY - 1][0:CACHE_SETS_COUNT - 1];
        reg lru[0:CACHE_WAY - 1][0:CACHE_SETS_COUNT - 1];
        reg[7:0] data[0:CACHE_WAY - 1][0:CACHE_SETS_COUNT - 1][0:CACHE_LINE_SIZE - 1];

        reg[CACHE_SET_SIZE - 1:0] cur_set_numb;
        reg[CACHE_TAG_SIZE - 1:0] cur_tag;
        reg[CACHE_OFFSET_SIZE - 1:0] offset;
        reg cache_hit;
        reg cur_way;

        assign c1 = in_or_out1 ? c1_reg : 3'bzzz;
        assign c2 = in_or_out2 ? c2_reg : 2'bzz;
        assign d1 = in_or_out1 ? d1_reg : 16'bzzzzzzzzzzzzzzzz;
        assign d2 = in_or_out2 ? d2_reg : 16'bzzzzzzzzzzzzzzzz;
        assign a2 = a2_reg;

        assign cache_hits = cache_hits_count;
        assign cache_requests = cache_requests_count;

        integer i = 0;
        integer y = 0;


        initial begin
        in_or_out1 = 0;
        cache_hits_count = 0;
        cache_requests_count = 0;
        for (i = 0; i < CACHE_SETS_COUNT; i += 1) begin
        is_valid[0][i] = 0;
        is_valid[1][i] = 0;
        dirty[0][i] = 0;
        dirty[1][i] = 0;
        lru[0][i] = 0;
        lru[1][i] = 0;
        tag[0][i] = 0;
        tag[1][i] = 0;
        end
        end

        task get_information;
        a1_reg = a1;
        #2;
        cur_set_numb = a1_reg % CACHE_SETS_COUNT;
        cur_tag = a1_reg >> CACHE_SET_SIZE;
        offset = a1;
        cache_hit = 0;
        if (is_valid[0][cur_set_numb] == 1 && tag[0][cur_set_numb] == cur_tag) begin
        cur_way = 0;
        cache_hit = 1;
        end else if (is_valid[1][cur_set_numb] == 1 && tag[1][cur_set_numb] == cur_tag) begin
        cur_way = 1;
        cache_hit = 1;
        end
        cache_requests_count += 1;
        endtask

        task write_to_mem;
        a2_reg[CACHE_SET_SIZE-1:0] = cur_set_numb;
        a2_reg[14:CACHE_SET_SIZE] = tag[cur_way][cur_set_numb];
        c2_reg = 3;
        in_or_out2 = 1;
        for (i = 0; i < CACHE_LINE_SIZE; i += 2) begin
        d2_reg[7:0] = data[cur_way][cur_set_numb][i];
        d2_reg[15:8] = data[cur_way][cur_set_numb][i + 1];
        #2;
        end
        in_or_out2 = 0;
        #2;
        wait(c2 === 1);
        dirty[cur_way][cur_set_numb] = 0;
        #2;
        endtask

        task read_from_mem;
        a2_reg = a1_reg;
        c2_reg = 2;
        in_or_out2 = 1;
        #2;
        in_or_out2 = 0;
        #2;
        wait(c2 === 1);
        for (i = 0; i < CACHE_LINE_SIZE; i += 2) begin
        data[cur_way][cur_set_numb][i] = d2[7:0];
        data[cur_way][cur_set_numb][i + 1] = d2[15:8];
        #2;
        end
        dirty[cur_way][cur_set_numb] = 0;
        tag[cur_way][cur_set_numb] = cur_tag;
        is_valid[cur_way][cur_set_numb] = 1;
        #1;
        endtask

        task processing_read_request(int req);
        get_information;

        if (cache_hit) begin
        #10;
        cache_hits_count += 1;
        end else begin
        cache_miss;
        end
        d1_reg[7:0] = data[cur_way][cur_set_numb][offset];
        if (req > 1) d1_reg[15:8] = data[cur_way][cur_set_numb][offset + 1];
        else d1_reg[15:8] = 0;
        lru[cur_way][cur_set_numb] = 1;
        lru[1 - cur_way][cur_set_numb] = 0;
        c1_reg = 7;
        #1;
        in_or_out1 = 1;
        if (req === 3) begin
        #1;
        d1_reg[7:0] = data[cur_way][cur_set_numb][offset + 2];
        d1_reg[15:8] = data[cur_way][cur_set_numb][offset + 3];
        #1;
        end
        #1;
        in_or_out1 = 0;
        endtask

        task processing_write_request(int req);
        d1_reg = d1;
        get_information;
        if (req === 7) d1_reg2 = d1;
        if (cache_hit) begin
        #10;
        cache_hits_count += 1;
        end else begin
        cache_miss;
        end
        c1_reg = 7;
        dirty[cur_way][cur_set_numb] = 1;
        lru[cur_way][cur_set_numb] = 1;
        lru[1 - cur_way][cur_set_numb] = 0;

        data[cur_way][cur_set_numb][offset] = d1_reg[7:0];
        if (req > 5) data[cur_way][cur_set_numb][offset + 1] = d1_reg[15:8];
        if (req === 7) begin
        data[cur_way][cur_set_numb][offset + 2] = d1_reg2[7:0];
        data[cur_way][cur_set_numb][offset + 3] = d1_reg2[15:8];
        end
        #1;
        in_or_out1 = 1;
        #1;
        in_or_out1 = 0;
        endtask

        task cache_miss;
        #5;
        cur_way = 0;
        if (is_valid[1][cur_set_numb] === 0 || lru[0][cur_set_numb]) cur_way = 1;
        if (dirty[cur_way][cur_set_numb] === 1) begin
        write_to_mem;
        end
        read_from_mem;
        endtask

        always @(posedge clk) begin
        if (reset) begin
        for (i = 0; i < CACHE_SETS_COUNT; i += 1) begin
        is_valid[0][i] = 0;
        is_valid[1][i] = 0;
        dirty[0][i] = 0;
        dirty[1][i] = 0;
        end
        end
        if(c_dump) begin
        $dumpfile("c_dump.vcd");
        $dumpvars(1, cache);
        end
        case(c1)
        0: $display("NOP");
        1: begin
        //$display("read8");
        processing_read_request(1);
        end
        2: begin
        //$display("read16");
        processing_read_request(2);
        end
        3: begin
        //$display("read32");
        processing_read_request(3);
        end
        4: begin
        //$display("invalidate line");
        a1_reg = a1;
        cur_set_numb = a1_reg[CACHE_SET_SIZE - 1:0];
        cur_tag = a1_reg[14:CACHE_SET_SIZE];
        #2 offset = a1;
        cache_hit = 0;
        if (is_valid[0][cur_set_numb] == 1 && tag[0][cur_set_numb] == cur_tag) begin
        cur_way = 0;
        is_valid[cur_way][cur_set_numb] = 0;
        if (dirty[cur_way][cur_set_numb] === 1) begin
        write_to_mem;
        end
        end else if (is_valid[1][cur_set_numb] == 1 && tag[1][cur_set_numb] == cur_tag) begin
        cur_way = 1;
        is_valid[cur_way][cur_set_numb] = 0;
        if (dirty[cur_way][cur_set_numb] === 1) begin
        write_to_mem;
        end
        end
        end
        5: begin
        //$display("write8");
        processing_write_request(5);
        end
        6: begin
        //$display("write16");
        processing_write_request(6);
        end
        7: begin
        //$display("write32");
        processing_write_request(7);
        end
        endcase
        end
        endmodule