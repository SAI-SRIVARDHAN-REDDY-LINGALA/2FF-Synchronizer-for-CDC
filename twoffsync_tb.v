module tb;

reg clk_src;
reg clk_dst;
reg rst_n;

reg async_signal;

wire sync_signal;

sync_2ff dut(
    .clk_dst(clk_dst),
    .rst_n(rst_n),
    .async_in(async_signal),
    .sync_out(sync_signal)
);

initial
begin
    clk_src = 0;
    forever #5 clk_src = ~clk_src;   //100MHz
end

initial
begin
    clk_dst = 0;
    // forever #13 clk_dst = ~clk_dst;  //38.46MHz  - sourcce > destination - short pulse not captured
    // forever #2.5 clk_dst = ~clk_dst;  //200MHz  -- source < destination
    forever #5 clk_dst = ~clk_dst;  //200MHz  -- source < destination




end

initial
begin
    rst_n = 0;
    async_signal = 0;

    #30;
    rst_n = 1;

    #17 async_signal = 1;
    #21 async_signal = 0;

    #11 async_signal = 1;
    #40 async_signal = 0;

    #200 $finish;
end

initial begin 
    $dumpfile("2ffsync_tb.vcd");
    $dumpvars(0, tb);
end 
endmodule