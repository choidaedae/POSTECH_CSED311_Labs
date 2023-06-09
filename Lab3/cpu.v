// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
wire[31:0]current_pc;
wire[31:0]next_pc;
wire[31:0]accessMem;
wire[31:0]dout;
wire[31:0]rs1_dout;
wire[31:0]rs2_dout;
wire[31:0]imm_gen_out;
wire[31:0]alu_in_1;
wire[31:0]alu_in_2;
wire[31:0]alu_result;
wire[31:0]writeData;



  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.




//control
wire pc_write_not_cond;
wire pc_write;
wire IorD;
wire mem_to_reg;
wire mem_read;
wire mem_write;
wire ir_write;
wire pc_source;
wire [1:0]ALU_SrcB;
wire ALU_SrcA;
wire reg_write;
wire alu_bcond;
wire ALU_op;
wire [4:0]command;
wire [4:0] rs1;

always @(posedge clk)begin
  if(!IorD && ir_write) IR <= dout;
  if(IorD) MDR <= dout;
  A <= rs1_dout;
  B <= rs2_dout;
  ALUOut <= alu_result;
end


assign is_halted = (is_ecall && rs1_dout==10)? 1:0;


mux2to1 mem_selector(
  .in1(current_pc),
  .in2(ALUOut),
  .signal(IorD),
  .result(accessMem)
);//mux before memory

mux2to1 data_to_write(
  .in1(ALUOut),
  .in2(MDR),
  .signal(mem_to_reg),
  .result(writeData)
);//determine data to write

mux2to1 alusrcA_selector(
  .in1(current_pc),
  .in2(A),
  .signal(ALU_SrcA),
  .result(alu_in_1)
);//okay

mux4to1 alusrcB_selector(
  .in1(B),
  .in2(4),
  .in3(imm_gen_out),
  .in4(0),
  .signal(ALU_SrcB),
  .result(alu_in_2)
);

mux2to1 pcSrc_selector(
  .in1(alu_result),
  .in2(ALUOut),
  .signal(pc_source),
  .result(next_pc)
);

mux2to1 rs1_selector(
  .in1(IR[19:15]),
  .in2(5'b10001),
  .signal(is_ecall),
  .result(rs1)
);


  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),  //input
    .pc_write(pc_write),  //input
    .alu_bcond(alu_bcond),  //input
    .pc_write_not_cond(pc_write_not_cond),  //input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(rs1),          // input
    .rs2(IR[24:20]),          // input
    .rd(IR[11:7]),           // input
    .rd_din(writeData),       // input
    .write_enable(reg_write),    // input
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout)     // output
  );



  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(accessMem),         // input
    .din(rs2_dout),          // input
    .mem_read(mem_read),     // input
    .mem_write(mem_write),    // input
    .dout(dout)          // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .clk(clk),
    .reset(reset),
    .part_of_inst(IR[6:0]),
    .alu_bcond(alu_bcond),  // input
    .pc_write_not_cond(pc_write_not_cond),        // output
    .pc_write(pc_write),       // output
    .IorD(IorD),        // output
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .ir_write(ir_write),      // output
    .reg_write(reg_write),     // output
    .pc_source(pc_source),
    .ALU_op(ALU_op),
    .ALU_SrcB(ALU_SrcB),
    .ALU_SrcA(ALU_SrcA),  // output
    .is_ecall(is_ecall) // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .inst(IR[31:0]),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .part_of_inst(IR[31:0]),
    .alu_op(ALU_op),  // input
    .command(command)         // output
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_op(command),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );

endmodule
