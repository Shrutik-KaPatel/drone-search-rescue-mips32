`timescale 1ns/1ps

//==============================================================
// Testbench : pipe_MIPS32_tb
//
// Purpose:
// Verifies the 5-stage pipelined MIPS32 processor by executing
// a small real-world inspired workload.
//
// Application Scenario:
// Drone Search-and-Rescue Edge Processing
//
// The processor reads sensor data (Thermal, Motion, Sound),
// computes a RescueScore = Thermal + Motion + Sound,
// and stores the result in memory.
//
// Five locations are processed sequentially.
//
// Important Architectural Constraint:
// The processor has NO forwarding and NO hazard detection.
// Therefore, NOP instructions are inserted manually between
// dependent instructions to avoid pipeline hazards.
//==============================================================

module pipe_MIPS32_tb;

reg clk1, clk2;
integer k;

//--------------------------------------------------------------
// DUT : Device Under Test
//--------------------------------------------------------------
pipe_MIPS32 dut (clk1, clk2);


//--------------------------------------------------------------
// Two-phase clock generation
//--------------------------------------------------------------
initial begin
    clk1 = 0;
    clk2 = 0;

    // Run long enough for full program execution
    repeat (2000) begin
        #5 clk1 = 1; #5 clk1 = 0;
        #5 clk2 = 1; #5 clk2 = 0;
    end
end


//--------------------------------------------------------------
// Monitor important outputs during simulation
//--------------------------------------------------------------
initial begin
    $monitor(
        "Time=%0d PC=%0d Score1=%0d Score2=%0d Score3=%0d Score4=%0d Score5=%0d",
        $time,
        dut.PC,
        dut.Mem[300],
        dut.Mem[301],
        dut.Mem[302],
        dut.Mem[303],
        dut.Mem[304]
    );
end


//--------------------------------------------------------------
// Program + Memory Initialization
//--------------------------------------------------------------
initial begin

//--------------------------------------------------------------
// Reset registers and memory
//--------------------------------------------------------------
for (k = 0; k < 32; k = k + 1)
    dut.Reg[k] = 0;

for (k = 0; k < 1024; k = k + 1)
    dut.Mem[k] = 0;


//--------------------------------------------------------------
// Program Initialization
//
// Registers:
// R2 → sensor data pointer
// R3 → output score pointer
//--------------------------------------------------------------

dut.Mem[0] = 32'h280200C8;   // ADDI R2,R0,200
dut.Mem[1] = 32'h2803012C;   // ADDI R3,R0,300

// Pipeline warm-up NOPs
dut.Mem[2] = 32'h0ce77800;
dut.Mem[3] = 32'h0ce77800;


//==============================================================
// ITERATION 1  (Sensor[200..202] → Mem[300])
//==============================================================
dut.Mem[4]  = 32'h20440000;  // LW R4,0(R2)
dut.Mem[5]  = 32'h0ce77800;
dut.Mem[6]  = 32'h0ce77800;

dut.Mem[7]  = 32'h20450001;  // LW R5,1(R2)
dut.Mem[8]  = 32'h0ce77800;
dut.Mem[9]  = 32'h0ce77800;

dut.Mem[10] = 32'h20460002;  // LW R6,2(R2)
dut.Mem[11] = 32'h0ce77800;
dut.Mem[12] = 32'h0ce77800;

dut.Mem[13] = 32'h00853800;  // ADD R7,R4,R5
dut.Mem[14] = 32'h0ce77800;
dut.Mem[15] = 32'h0ce77800;

dut.Mem[16] = 32'h00E64000;  // ADD R8,R7,R6
dut.Mem[17] = 32'h0ce77800;
dut.Mem[18] = 32'h0ce77800;

dut.Mem[19] = 32'h24680000;  // SW R8,0(R3)

dut.Mem[20] = 32'h0ce77800;
dut.Mem[21] = 32'h0ce77800;

dut.Mem[22] = 32'h28420003;  // ADDI R2,R2,3
dut.Mem[23] = 32'h0ce77800;
dut.Mem[24] = 32'h0ce77800;

dut.Mem[25] = 32'h28630001;  // ADDI R3,R3,1
dut.Mem[26] = 32'h0ce77800;
dut.Mem[27] = 32'h0ce77800;


//==============================================================
// ITERATION 2  (Sensor[203..205] → Mem[301])
//==============================================================
dut.Mem[28] = 32'h20440000;
dut.Mem[29] = 32'h0ce77800;
dut.Mem[30] = 32'h0ce77800;

dut.Mem[31] = 32'h20450001;
dut.Mem[32] = 32'h0ce77800;
dut.Mem[33] = 32'h0ce77800;

dut.Mem[34] = 32'h20460002;
dut.Mem[35] = 32'h0ce77800;
dut.Mem[36] = 32'h0ce77800;

dut.Mem[37] = 32'h00853800;
dut.Mem[38] = 32'h0ce77800;
dut.Mem[39] = 32'h0ce77800;

dut.Mem[40] = 32'h00E64000;
dut.Mem[41] = 32'h0ce77800;
dut.Mem[42] = 32'h0ce77800;

dut.Mem[43] = 32'h24680000;

dut.Mem[44] = 32'h0ce77800;
dut.Mem[45] = 32'h0ce77800;

dut.Mem[46] = 32'h28420003;
dut.Mem[47] = 32'h0ce77800;
dut.Mem[48] = 32'h0ce77800;

dut.Mem[49] = 32'h28630001;
dut.Mem[50] = 32'h0ce77800;
dut.Mem[51] = 32'h0ce77800;


//==============================================================
// ITERATION 3  (Sensor[206..208] → Mem[302])
//==============================================================
dut.Mem[52] = 32'h20440000;
dut.Mem[53] = 32'h0ce77800;
dut.Mem[54] = 32'h0ce77800;

dut.Mem[55] = 32'h20450001;
dut.Mem[56] = 32'h0ce77800;
dut.Mem[57] = 32'h0ce77800;

dut.Mem[58] = 32'h20460002;
dut.Mem[59] = 32'h0ce77800;
dut.Mem[60] = 32'h0ce77800;

dut.Mem[61] = 32'h00853800;
dut.Mem[62] = 32'h0ce77800;
dut.Mem[63] = 32'h0ce77800;

dut.Mem[64] = 32'h00E64000;
dut.Mem[65] = 32'h0ce77800;
dut.Mem[66] = 32'h0ce77800;

dut.Mem[67] = 32'h24680000;

dut.Mem[68] = 32'h0ce77800;
dut.Mem[69] = 32'h0ce77800;

dut.Mem[70] = 32'h28420003;
dut.Mem[71] = 32'h0ce77800;
dut.Mem[72] = 32'h0ce77800;

dut.Mem[73] = 32'h28630001;
dut.Mem[74] = 32'h0ce77800;
dut.Mem[75] = 32'h0ce77800;


//==============================================================
// ITERATION 4  (Sensor[209..211] → Mem[303])
//==============================================================
dut.Mem[76] = 32'h20440000;
dut.Mem[77] = 32'h0ce77800;
dut.Mem[78] = 32'h0ce77800;

dut.Mem[79] = 32'h20450001;
dut.Mem[80] = 32'h0ce77800;
dut.Mem[81] = 32'h0ce77800;

dut.Mem[82] = 32'h20460002;
dut.Mem[83] = 32'h0ce77800;
dut.Mem[84] = 32'h0ce77800;

dut.Mem[85] = 32'h00853800;
dut.Mem[86] = 32'h0ce77800;
dut.Mem[87] = 32'h0ce77800;

dut.Mem[88] = 32'h00E64000;
dut.Mem[89] = 32'h0ce77800;
dut.Mem[90] = 32'h0ce77800;

dut.Mem[91] = 32'h24680000;

dut.Mem[92] = 32'h0ce77800;
dut.Mem[93] = 32'h0ce77800;

dut.Mem[94] = 32'h28420003;
dut.Mem[95] = 32'h0ce77800;
dut.Mem[96] = 32'h0ce77800;

dut.Mem[97] = 32'h28630001;
dut.Mem[98] = 32'h0ce77800;
dut.Mem[99] = 32'h0ce77800;


//==============================================================
// ITERATION 5  (Sensor[212..214] → Mem[304])
//==============================================================
dut.Mem[100] = 32'h20440000;
dut.Mem[101] = 32'h0ce77800;
dut.Mem[102] = 32'h0ce77800;

dut.Mem[103] = 32'h20450001;
dut.Mem[104] = 32'h0ce77800;
dut.Mem[105] = 32'h0ce77800;

dut.Mem[106] = 32'h20460002;
dut.Mem[107] = 32'h0ce77800;
dut.Mem[108] = 32'h0ce77800;

dut.Mem[109] = 32'h00853800;
dut.Mem[110] = 32'h0ce77800;
dut.Mem[111] = 32'h0ce77800;

dut.Mem[112] = 32'h00E64000;
dut.Mem[113] = 32'h0ce77800;
dut.Mem[114] = 32'h0ce77800;

dut.Mem[115] = 32'h24680000;

dut.Mem[116] = 32'h0ce77800;
dut.Mem[117] = 32'h0ce77800;


//--------------------------------------------------------------
// Halt processor
//--------------------------------------------------------------
dut.Mem[118] = 32'hFC000000;


//--------------------------------------------------------------
// Sensor Data Initialization
//--------------------------------------------------------------
dut.Mem[200] = 70; dut.Mem[201] = 10; dut.Mem[202] = 5;
dut.Mem[203] = 65; dut.Mem[204] = 12; dut.Mem[205] = 6;
dut.Mem[206] = 80; dut.Mem[207] = 15; dut.Mem[208] = 4;
dut.Mem[209] = 75; dut.Mem[210] = 8;  dut.Mem[211] = 7;
dut.Mem[212] = 60; dut.Mem[213] = 9;  dut.Mem[214] = 3;


//--------------------------------------------------------------
// Initialize processor state
//--------------------------------------------------------------
dut.PC           = 0;
dut.HALTED       = 0;
dut.TAKEN_BRANCH = 0;


//--------------------------------------------------------------
// End simulation and print final results
//--------------------------------------------------------------
#10000;

$display("==================================");
$display("Processed Rescue Scores:");
$display("Score1 = %0d  (expected 85)", dut.Mem[300]);
$display("Score2 = %0d  (expected 83)", dut.Mem[301]);
$display("Score3 = %0d  (expected 99)", dut.Mem[302]);
$display("Score4 = %0d  (expected 90)", dut.Mem[303]);
$display("Score5 = %0d  (expected 72)", dut.Mem[304]);
$display("==================================");

$finish;

end

endmodule