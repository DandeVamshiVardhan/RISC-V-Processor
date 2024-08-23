`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2024 18:00:01
// Design Name: 16_bit risc processor
// Module Name: risc
// Project Name: 16 bit cpu
// Target Devices: 
// Tool Versions: 
// Description:  
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module risc(input clk,reset,output reg eop);

// parameter deciding
parameter ADD=4'b0000,SUB=4'b0001,AND=4'b0010,OR=4'b0011,NOT=4'b0100,XOR=4'b0101,CMP=4'b0110,SL=4'b0111,
          SR=4'b1000,LOAD=4'b1001,STORE=4'b1010,JUMP=4'b1011,END=4'b1100,JZ=4'b1101,JNZ=4'b1110,LOAD_IMM=4'b1111;
          
parameter RR_OP=3'b000,RM_OP=3'b001,MR_OP=3'b010,J_P=3'b011,END_P=3'b100;


// memory and register bank deciding
reg [15:0]memory[0:1023];
reg [15:0]regbank[0:15];

//loading with instruction and data
initial $readmemh("instruction.txt",memory,0,1023);
initial $readmemb("data.txt",regbank,0,15);

//deciding registers and wire datatypes
reg [9:0]pc,pc_1;
reg [15:0]ir,alu_out,rg_rs1,alu_ir;
reg [2:0]op_type;


wire [15:0]rs1,rs2,rd;
wire [15:0]aluout;
wire ctrl;
wire jump=(op_type==J_P)&(alu_out==16'b0000000000011111);
wire jumping=jump&(ctrl==1'b0);
wire [15:0]ir1,ir2;
wire equal1=(ctrl==1'b0)&(alu_ir[11:8]==ir1[11:8])&((op_type==RR_OP)|(op_type==MR_OP));
wire equal2=(ctrl==1'b0)&(alu_ir[11:8]==ir1[7:4])&((op_type==RR_OP)|(op_type==MR_OP));
wire equal3=(ctrl==1'b0)&(alu_ir[11:8]==ir1[3:0])&((op_type==RR_OP)|(op_type==MR_OP));
wire equal4=(ctrl==1'b0)&(rg_rs1==pc_1)&(op_type==RM_OP);
wire equal5=(ctrl==1'b0)&(rg_rs1==pc)&(op_type==RM_OP);
wire [15:0]rg_store=(op_type==RR_OP)?alu_out:memory[alu_out];


// instantiating muxex for register to register and memory to register instructions;
multiplexer mux1(equal1,regbank[ir1[11:8]],rg_store,rd);
multiplexer mux2(equal2,regbank[ir1[7:4]],rg_store,rs1);
multiplexer mux3(equal3,regbank[ir1[3:0]],rg_store,rs2);
multiplexer mux4(equal4,ir,alu_out,ir1);
// mux for register to memory function
multiplexer mux5(equal5,memory[pc],alu_out,ir2);

// fsm which disables every action after jump is executed
controller fsm_jump(jump,clk,reset,ctrl);

always @(posedge clk)
begin                                       //instruction fetch stage in processor
if(eop==1'b0) 
              begin 
                  ir<=ir2;
                  pc_1<=pc;
              end
end


ALU arithmetic_logic_unit(rs1,rs2,rd,ir1,aluout);  // instantiating arithmetic logic unit



always @(posedge clk)                             // instruction decode and execute stage
begin
if(eop==1'b0)
begin
rg_rs1<=rs1;
alu_ir<=ir1;
alu_out<=aluout;
case(ir1[15:12])
ADD,SUB,AND,OR,NOT,XOR,CMP,SL,SR,LOAD_IMM: op_type<=RR_OP;
LOAD:  op_type<=MR_OP;
STORE: op_type<=RM_OP;
JUMP,JZ,JNZ:  op_type<=J_P;
END:   op_type<=END_P;
endcase
end
end




always @(posedge clk)                             // write back and data memory stage
begin
if((eop==1'b0)&&(ctrl==1'b0))
case(op_type)
RR_OP,MR_OP:  regbank[alu_ir[11:8]]<=rg_store;
RM_OP:  memory[rg_rs1]<=alu_out;
endcase
end



always @(posedge clk,negedge reset)                  // nstate program counter loading part
if(reset==1'b0)  pc<=10'b0; 
else 
    begin
          if(jumping) pc<=pc+{{2{1'b0}},alu_ir[7:0]}+10'b1111111110;
                else pc<=pc+1'b1;
          
 
          end
  
   
always @(posedge clk,negedge reset)                   // end of program decider
if(reset==1'b0) eop<=1'b0;
  else if((op_type==END_P)&&(ctrl==1'b0)) eop<=1'b1;   
          

initial $monitor("e1=%b,e2=%b,e3=%b,rs1=%b,rs2=%b,rd=%b,rg_store=%b,pc=%b",alu_out,equal2,equal3,rs1,rs2,rd,alu_ir,pc);

// loading updated memory and register bank into files
always @(eop)
begin
$writememb("output.txt",regbank,0,15);  
$writememb("instruction1.txt",memory,0,1023);
end

endmodule




module ALU(input [15:0]data_1,data_2,data_3,instruction,output reg[15:0]data_out);

parameter ADD=4'b0000,SUB=4'b0001,AND=4'b0010,OR=4'b0011,NOT=4'b0100,XOR=4'b0101,CMP=4'b0110,SL=4'b0111,
          SR=4'b1000,LOAD=4'b1001,STORE=4'b1010,JUMP=4'b1011,END=4'b1100,JZ=4'b1101,JNZ=4'b1110,LOAD_IMM=4'b1111;
          
parameter RR_OP=3'b000,RM_OP=3'b001,MR_OP=3'b010,J_P=3'b011,END_P=3'b100;

wire grt=(data_1>data_2);
wire [3:0]opcode=instruction[15:12];
wire checking=(data_3==16'b0);
// operation deciding
always @*
begin
case(opcode)
ADD: data_out=data_1+data_2;
SUB: if(grt) data_out=data_1+~data_2+1'b1; else data_out=data_2+~data_1+1'b1;
AND: data_out=data_1&data_2;
OR:  data_out=data_1|data_2;
NOT: data_out=~data_2;
XOR: data_out=data_1^data_2;
CMP: data_out={data_1<data_2,grt,~|data_2,~|data_1,(&(data_1~^data_2))};
SL:  data_out={data_1[14:0],1'b0};
SR:  data_out={1'b0,data_1[15:1]};
LOAD:data_out=data_1;
STORE:data_out=data_2;
JUMP:data_out={5{1'b1}};
JZ:  data_out={5{checking}};
JNZ: data_out={5{~checking}};
LOAD_IMM:data_out={{8{1'b0}},instruction[7:0]};
default:data_out=16'bx;
endcase
end

endmodule



module controller(input jump,clk,reset,output ctrl);
// fsm controller
reg [1:0]state,nstate;

always @(posedge clk,negedge reset)
if(reset==1'b0) state<=2'b00;
           else state<=nstate;


always @*
begin
nstate=2'b00;
case(state)
2'b00: if(jump) nstate=2'b01; else nstate=2'b00;
2'b01: nstate=2'b10;
2'b10:nstate=2'b00;
default:nstate=2'b00;
endcase
end
assign ctrl=|state;


endmodule




module multiplexer(input select,input [15:0]data1,data2,output reg[15:0]out);
// multiplexer module

always @*
begin
out=data1;
case(select)
1'b1: out=data2;
default: out=data1;
endcase 
end


endmodule