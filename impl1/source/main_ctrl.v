//   ==================================================================
//   >>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
//   ------------------------------------------------------------------
//   Copyright (c) 2013 by Lattice Semiconductor Corporation
//   ALL RIGHTS RESERVED 
//   ------------------------------------------------------------------
//
//   Permission:
//
//      Lattice SG Pte. Ltd. grants permission to use this code
//      pursuant to the terms of the Lattice Reference Design License Agreement. 
//
//
//   Disclaimer:
//
//      This VHDL or Verilog source code is intended as a design reference
//      which illustrates how these types of functions can be implemented.
//      It is the user's responsibility to verify their design for
//      consistency and functionality through the use of formal
//      verification methods.  Lattice provides no warranty
//      regarding the use or functionality of this code.
//
//   --------------------------------------------------------------------
//
//                  Lattice SG Pte. Ltd.
//                  101 Thomson Road, United Square #07-02 
//                  Singapore 307591
//
//
//                  TEL: 1-800-Lattice (USA and Canada)
//                       +65-6631-2000 (Singapore)
//                       +1-503-268-8001 (other locations)
//
//                  web: http://www.latticesemi.com/
//                  email: techsupport@latticesemi.com
//
//   -------------------------------------------------------------------
//  Project:           SPI slave with EFB
//  File:              main_ctrl.v
//  Title:             main_ctrl
//  Description:       Main control module of this reference design for XO2 architecture
//
// --------------------------------------------------------------------
// Code Revision History :
// --------------------------------------------------------------------
// Ver: | Author   | Mod. Date  | Changes Made:
// V1.0 | H.C.     | 2012-03-09 | Initial Release
//
// --------------------------------------------------------------------

`timescale 1 ns/ 1 ps

module main_ctrl #(parameter GPI_PORT_NUM = 4,           // GPI port number          
                   parameter GPI_DATA_WIDTH = 8,         // GPI data width           
                   parameter GPO_PORT_NUM = 4,           // GPO port number          
                   parameter GPO_DATA_WIDTH = 4,         // GPO data width           
                   parameter MEM_ADDR_WIDTH = 8,         // Memory addrss width      
                   parameter IRQ_NUM = 4,                // Interrupt request number 
                   parameter REVISION_ID = 8'h55,        // Revision ID             
                   parameter MAX_MEM_BURST_NUM = 8       // Maximum memory burst number
                   )                                     
   (                                                     
    input  wire                            clk,          // System clock
    input  wire                            rst_n,        // System reset
    input  wire                            spi_csn,      // Hard SPI chip-select (active low)
    output reg  [7:0]                      address,      // Local address for the WISHBONE interface
    output reg                             wr_en,        // Local write enable for the WISHBONE interface
    output reg  [7:0]                      wr_data,      // Local write data for the WISHBONE interface        
    output reg                             rd_en,        // Local read enable for the WISHBONE interface          
    input  wire [7:0]                      rd_data,      // Local read data for the WISHBONE interface          
    input  wire                            wb_xfer_done, // WISHBONE transfer done    
    input  wire                            wb_xfer_req,   // WISHBONE transfer request 
    //output reg                             en_port,      // Genaral purpose enable port
    //output reg                             gpi_ld,       // GPI latch
    //output reg                             gpio_wr,      // GPIO write (high) and read (low)
    //output reg  [7:0]                      gpio_addr,    // GPIO port address                     
    output reg	[3:0]						input_sel,
	output reg	[2:0]						mu_sel,
	output reg	[3:0]						avk_sel,
	output reg								ref_sel,
	output reg								fil1_sel,
	output reg								fil2_sel,
	output wire 							relay_reset,
	
	output wire  [GPO_DATA_WIDTH-1:0]       cs_out,    // GPIO port output data bus
	input wire [23:0] 						fifo_data,
	output reg								fifo_rd_en
    //input  wire [GPI_DATA_WIDTH-1:0]       gpio_din,     // GPIO port input data bus
    //output reg                             mem_wr,       // Memory write (high) and read (low)
    //output reg  [MEM_ADDR_WIDTH-1:0]       mem_addr,     // Memory address
    //output reg  [7:0]                      mem_wdata,    // Memory write data bus
    //input  wire [7:0]                      mem_rdata,    // Memory read data bus
    //input  wire [IRQ_NUM-1:0]              irq_status,   // IRQ status     
    //output reg  [IRQ_NUM-1:0]              irq_en,       // IRQ enable
    //output reg  [IRQ_NUM-1:0]              irq_clr       // IRQ clear
    );
    
	
	reg  [GPO_DATA_WIDTH-1:0]       cs_dout;    // GPIO port output data bus
    
    // The definitions for SPI EFB register address
    `define SPITXDR 8'h59
    `define SPISR   8'h5A
    `define SPIRXDR 8'h5B
    
    // The definitions for the state values of the main state machine
    `define S_IDLE      4'h0
    `define S_RXDR_RD   4'h1
    `define S_TXDR_WR   4'h2
    `define S_CMD_ST    4'h3
    `define S_CMD_LD    4'h4
    `define S_CMD_DEC   4'h5
    `define S_TXDR_WR1  4'h6
    `define S_ADDR_ST   4'h7
    `define S_ADDR_LD   4'h8
    `define S_WDATA_ST  4'h9
    `define S_DATA_WR   4'hA  
    `define S_DATA_RD   4'hB    
    `define S_RDATA_ST  4'hC
    
    // The definitions for the SPI command values of the reference design
    `define C_CS_SEL      	8'h01 
    `define C_INPUT_SEL   	8'h02  
    `define C_MU_SEL  	 	8'h03  
    `define C_AVK_SEL  	 	8'h04  
    `define C_REF_SEL  	 	8'h05
    `define C_FIL_SEL  	 	8'h06
	`define C_FIFO_RD  	 	8'h07
	
    `define C_REV_ID     8'h9F 
    
    // The definitions for the slim version of the SPI command values
    `define CS_SEL     	 4'h0  
    `define INPUT_SEL  	 4'h1  
    `define MU_SEL  	 4'h2  
    `define AVK_SEL  	 4'h3  
    `define REF_SEL  	 4'h4 
	`define FIL_SEL  	 4'h5
	`define FIFO_RD  	 4'h6
	
    `define REV_ID     4'hB  
    `define INVALID    4'hF  
        
       
       
    reg [3:0]  main_sm;           // The state register of the main state machine
    reg        spi_csn_buf0_p;    // The postive-egde sampling of spi_csn
    reg        spi_csn_buf1_p;    // The postive-egde sampling of spi_csn_buf0_p 
    reg        spi_csn_buf2_p;    // The postive-egde sampling of spi_csn_buf1_p
    wire       spi_cmd_start;     // A new SPI command start
    reg        spi_cmd_start_reg; // The buffer of a new SPI command start
    reg        spi_idle;          // SPI IDLE signal    
    reg  [3:0] spi_cmd;           // The slim buffer version of the SPI command used for the performance 
    wire       spi_rx_rdy;        // SPI receive ready    
    wire       spi_tx_rdy;        // SPI transmit ready             
    wire       spi_xfer_done;     // SPI transmitting complete (1: complete, 0: in progress) 
    //reg  [7:0] mem_burst_cnt;

	reg [3:0] 	spi_byte_counter;	

	assign cs_out[3:0] = spi_csn_buf0_p ? cs_dout[3:0] : 4'hF;

    // Bufferring spi_csn with postive edge                    
    always @(posedge clk or posedge rst_n)
       if (rst_n)
          spi_csn_buf0_p <= 1'b1;
       else
          spi_csn_buf0_p <= spi_csn;
              
    // Bufferring spi_csn_buf0_p with postive edge                    
    always @(posedge clk or posedge rst_n)
       if (rst_n)
          spi_csn_buf1_p <= 1'b1;
       else
          spi_csn_buf1_p <= spi_csn_buf0_p;

    // Bufferring spi_csn_buf1_p with postive edge 
    always @(posedge clk or posedge rst_n)
       if (rst_n)
          spi_csn_buf2_p <= 1'b1;
       else
          spi_csn_buf2_p <= spi_csn_buf1_p;
       
    // Generate SPI command start buffer signal                 
    always @(posedge clk or posedge rst_n)
       if (rst_n)
          spi_cmd_start_reg <= 1'b0;
       else
          if (spi_csn_buf2_p && !spi_csn_buf1_p)
             spi_cmd_start_reg <= 1'b1;
          else if (main_sm == `S_IDLE || main_sm == `S_RXDR_RD || (!spi_csn_buf2_p && spi_csn_buf1_p))
             spi_cmd_start_reg <= 1'b0;
    
    // Generate SPI command start signal
    assign spi_cmd_start = (spi_csn_buf2_p & ~spi_csn_buf1_p) | spi_cmd_start_reg;
    
    // spi_idle will be asserted between spi_csn de-asserted and main_sm == `S_IDLE                    
    always @(posedge clk or posedge rst_n)
       if (rst_n)
          spi_idle <= 1'b0;
       else 
          if (spi_csn_buf1_p)
             spi_idle <= 1'b1;
          else if (main_sm == `S_IDLE)   
             spi_idle <= 1'b0;
    
    assign spi_xfer_done = (~spi_csn_buf2_p & spi_csn_buf1_p) | spi_idle;
             
    assign spi_rx_rdy = rd_data[3] ? 1'b1 : 1'b0;
    assign spi_tx_rdy = rd_data[4] ? 1'b1 : 1'b0;
    
    //The main state machine with its output registers      
    always @(posedge clk or posedge rst_n)
       if (rst_n) begin
          main_sm <= `S_IDLE;
          spi_cmd <= `REV_ID;
          rd_en <= 1'b0;
          wr_en <= 1'b0;
          address <= `SPITXDR;
          wr_data <= 8'd0;
          //en_port <= 1'b0;
          //gpi_ld <= 1'b0;
          //irq_en <= 'b0;
          //irq_clr <= 'b0;
          //gpio_wr <= 1'b0;  
          //gpio_addr <= 8'd0;
		  
		  input_sel <= 4'b0;
		  mu_sel <= 3'b0;
		  //avk_sel <= 4'b0;
		  ref_sel <= 1'b0;
		  fil1_sel <= 1'b0;		  
          fil2_sel <= 1'b0;		  
          cs_dout <= 4'b0;
          
		  //mem_wr <= 1'b0;
          //mem_addr <= 'b0;
          //mem_wdata <= 'b0;
          //mem_burst_cnt <= 'b0;
       end else begin
          rd_en <= 1'b0;
          wr_en <= 1'b0;
          //irq_clr <= 'b0;
          //gpio_wr <= 1'b0;
          //mem_wr <= 1'b0;
          
          address <= `SPITXDR;
          
          case (main_sm)
          // IDLE state
          `S_IDLE:     if (spi_cmd_start && wb_xfer_req) begin
                          main_sm <= `S_RXDR_RD;            // Go to `S_RSDR_RD state when a new SPI command starts and
                                                            // WISHBONE is ready to transfer
                          rd_en <= 1'b1;                        
                          address <= `SPIRXDR;
                       end
          // Read SPI EFB RXDR register first to get ready to read the SPI command next
          `S_RXDR_RD:  if (wb_xfer_done) begin
                          main_sm <= `S_TXDR_WR;            // Go to `S_TXDR_WR state when the RXDR register read is done
                          wr_en <= 1'b1; 
                          address <= `SPITXDR; 
						  wr_data <= 8'd0;
                       end
          // Write dummy data to the SPI EFB TXDR register in order to write next data to the register correctly       
          `S_TXDR_WR:  if (wb_xfer_done) begin                
                          main_sm <= `S_CMD_ST;             // Go to `S_CMD_ST state when the TXDR register write is done
                          rd_en <= 1'b1;
                          address <= `SPISR;
                       end
          // Wait for the SPI command is ready in the RXDR register                                              
          `S_CMD_ST:   begin 
                          if (wb_xfer_done && spi_rx_rdy) begin  
                             main_sm <= `S_CMD_LD;          // Go to `S_CMD_LD state when the SPI command is ready in the RXDR register
                             rd_en <= 1'b1;                        
                             address <= `SPIRXDR;
                          end else if (wb_xfer_done && spi_xfer_done)   
                             main_sm <= `S_IDLE;            // Go to `S_IDLE state when the SPI transfer is complete 
                          else if (wb_xfer_done && spi_tx_rdy) begin
                             main_sm <= `S_TXDR_WR;         // Go to `S_TXDR_WR state to rewrite the TXDR register when SPI transmit is ready
                             wr_en <= 1'b1; 
                             address <= `SPITXDR;                              
                          end else if (wb_xfer_done) begin
                             rd_en <= 1'b1;                 // Otherwise, keep read SR register in the current state
                             address <= `SPISR;
                          end  
                       end 
          // Load the SPI command to improve the performance because the path delay from the RXDR register is very big 
          `S_CMD_LD:   if (wb_xfer_done) begin
                          main_sm <= `S_CMD_DEC;            // Go to `S_CMD_DEC state when the RXDR register read is done
                          case (rd_data)
    						  `C_CS_SEL:	 spi_cmd <= `CS_SEL;
                              `C_INPUT_SEL:	 spi_cmd <= `INPUT_SEL;
                              `C_MU_SEL:	 spi_cmd <= `MU_SEL;
                              `C_AVK_SEL:	 spi_cmd <= `AVK_SEL;
                              `C_REF_SEL:	 spi_cmd <= `REF_SEL;
                              `C_FIL_SEL:	 spi_cmd <= `FIL_SEL;
                              `C_FIFO_RD:	 spi_cmd <= `FIFO_RD;
                              //`C_EN_SET:     spi_cmd <= `EN_SET;   
                              //`C_EN_CLR:     spi_cmd <= `EN_CLR;  
                              //`C_GPO_WR:     spi_cmd <= `GPO_WR;  
                              //`C_GPI_LD:     spi_cmd <= `GPI_LD;  
                              //`C_GPI_RD:     spi_cmd <= `GPI_RD;  
                              //`C_MEM_WR:     spi_cmd <= `MEM_WR;  
                              //`C_MEM_RD:     spi_cmd <= `MEM_RD;  
                              //`C_IRQ_EN_WR:  spi_cmd <= `IRQ_EN_WR;  
                              //`C_IRQ_EN_RD:  spi_cmd <= `IRQ_EN_RD;
                              //`C_IRQ_ST:     spi_cmd <= `IRQ_ST;  
                              //`C_IRQ_CLR:    spi_cmd <= `IRQ_CLR; 
                              `C_REV_ID:     spi_cmd <= `REV_ID;    
                              default:       spi_cmd <= `INVALID;
                          endcase
                       end
          // Decode the SPI command              
          `S_CMD_DEC:  begin
                          case (spi_cmd)
                          `CS_SEL:     begin 
                                          main_sm <= `S_TXDR_WR1;     // Go to `S_IDLE state when the SPI command is Enable
										  wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
										  //wr_data <= 8'hFF;
                                       end  
                          `INPUT_SEL:     begin 
                                          main_sm <= `S_TXDR_WR1;     // Go to `S_IDLE state when the SPI command is Enable
										  wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                       end 									   
                          `MU_SEL:     begin 
                                          main_sm <= `S_TXDR_WR1;     // Go to `S_IDLE state when the SPI command is Enable
										  wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                       end 									   
                          `AVK_SEL:     begin 
                                          main_sm <= `S_TXDR_WR1;     // Go to `S_IDLE state when the SPI command is Enable
										  wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                       end 									   
                          `REF_SEL:     begin 
                                          main_sm <= `S_TXDR_WR1;     // Go to `S_IDLE state when the SPI command is Enable
										  wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                       end 									   
                          `FIL_SEL:     begin 
                                          main_sm <= `S_TXDR_WR1;     // Go to `S_IDLE state when the SPI command is Enable
										  wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                       end 		
						  `FIFO_RD:     begin 
                                          main_sm <= `S_TXDR_WR1;     // Go to `S_IDLE state when the SPI command is Enable
										  wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                       end 									   
                          //`EN_SET:     begin 
                                          //main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Enable
                                          //en_port <= 1'b1; 
                                       //end  
                          //`EN_CLR:     begin 
                                          //main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Disable
                                          //en_port <= 1'b0; 
                                       //end
                          //`GPO_WR:     begin 
                                          //main_sm <= `S_TXDR_WR1; // Go to `S_TXDR_WR1 state when the SPI command is Write GPO 
                                          //wr_en <= 1'b1; 
                                          //address <= `SPITXDR; 
                                       //end
                          //`GPI_LD:     begin 
                                          //main_sm <= `S_WDATA_ST; // Go to `S_WDATA_ST state when the SPI command is Latch GPI
                                          //rd_en <= 1'b1; 
                                          //address <= `SPISR; 
                                       //end
                          //`GPI_RD:     begin 
                                          //main_sm <= `S_TXDR_WR1; // Go to `S_TXDR_WR1 state when the SPI command is Read GPI 
                                          //wr_en <= 1'b1; 
                                          //address <= `SPITXDR; 
                                       //end
                          //`MEM_WR:     begin 
                                          //main_sm <= `S_TXDR_WR1; // Go to `S_TXDR_WR1 state when the SPI command is Write Memory 
                                          //wr_en <= 1'b1; 
                                          //address <= `SPITXDR; 
                                       //end
                          //`MEM_RD:     begin 
                                          //main_sm <= `S_TXDR_WR1; // Go to `S_TXDR_WR1 state when the SPI command is Read Memory 
                                          //wr_en <= 1'b1; 
                                          //address <= `SPITXDR; 
                                       //end
                          //`IRQ_EN_WR:  begin 
                                          //main_sm <= `S_WDATA_ST; // Go to `S_WDATA_ST state when the SPI command is IRQ Enable Write
                                          //rd_en <= 1'b1; 
                                          //address <= `SPISR; 
                                       //end
                          //`IRQ_EN_RD:  begin 
                                          //main_sm <= `S_TXDR_WR1; // Go to `S_TXDR_WR1 state when the SPI command is IRQ Enable Read
                                          //wr_en <= 1'b1; 
                                          //address <= `SPITXDR; 
                                          //wr_data <= irq_en[IRQ_NUM-1:0]; 
                                       //end                                       
                          //`IRQ_ST:     begin 
                                          //main_sm <= `S_TXDR_WR1; // Go to `S_TXDR_WR1 state when the SPI command is IRQ Status
                                          //wr_en <= 1'b1; 
                                          //address <= `SPITXDR; 
                                          //wr_data <= irq_status[IRQ_NUM-1:0]; 
                                       //end
                          //`IRQ_CLR:    begin 
                                          //main_sm <= `S_WDATA_ST; // Go to `S_WDATA_ST state when the SPI command is IRQ Clear
                                          //rd_en <= 1'b1; 
                                          //address <= `SPISR; 
                                       //end
                          `REV_ID:     begin 
                                          main_sm <= `S_TXDR_WR1; // Go to `S_TXDR_WR1 state when the SPI command is Revision ID
                                          wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                          wr_data <= REVISION_ID; 
                                       end
                          `INVALID:   main_sm <= `S_IDLE;        // Go to `S_IDLE state when the SPI command is illegal
                          default:     main_sm <= `S_IDLE;        // Go to `S_IDLE state when the SPI command is illegal
                          endcase
                  
                          if (spi_xfer_done) begin        
                             main_sm <= `S_IDLE;               // Go to `S_IDLE state when the current SPI transaction is ended
                             rd_en <= 1'b0;
                             wr_en <= 1'b0;
                          end                           

                          //mem_burst_cnt <= 'b0;
                                                                
                       end   
          // For GPIO/memory commands, write dummy data to the SPI EFB TXDR register in order to write next data to the register correctly.
          // For IRQ_ST/REV_ID commands, write their data to the SPI EFB TXDR register.                
          `S_TXDR_WR1: if (wb_xfer_done) begin
                          main_sm <= `S_ADDR_ST;               // Go to `S_ADDR_ST state when the TXDR register write is done
                          rd_en <= 1'b1;
                          address <= `SPISR;
                       end
          // For GPIO/memory commands, wait for the address ready in the RXDR register.
          // For IRQ_ST/REV_ID commands, wait for the data write done             
          `S_ADDR_ST:  begin 
                          if (wb_xfer_done && spi_rx_rdy) begin
                              main_sm <= `S_DATA_WR;           // Go to `S_ADDR_LD state when the address is ready in the RXDR register
                              rd_en <= 1'b1;                        
                              address <= `SPIRXDR;
                              
                              if (spi_xfer_done) begin
                                 main_sm <= `S_IDLE;           // Go to `S_IDLE state when the current SPI transaction is complete
                                 rd_en <= 1'b0;
                              end   
                          end else if (wb_xfer_done && spi_xfer_done)   
                             main_sm <= `S_IDLE;               // Go to `S_IDLE state when the SPI transfer is complete
                          else if (wb_xfer_done && spi_tx_rdy) begin
                             main_sm <= `S_TXDR_WR1;           // Go to `S_TXDR_WR1 state to rewrite the TXDR register when SPI transmit is ready
                             wr_en <= 1'b1; 
                             address <= `SPITXDR; 
							 //wr_data <= 8'd0;
                          end else if (wb_xfer_done) begin
                             rd_en <= 1'b1;                    // Otherwise, keep read SR register in the current state
                             address <= `SPISR;
                          end  
                       end 
          // For GPIO/memory commands, load address.
          // For IRQ_ST/REV_ID commands, go to `S_IDLE state.                
          `S_ADDR_LD:  if (wb_xfer_done) begin
                          case (spi_cmd) 
						  `CS_SEL:     begin 
                                          main_sm <= `S_WDATA_ST; // Go to `S_WDATA_ST state when the SPI command is Write GPO
                                          //gpio_addr <= rd_data;
                                          rd_en <= 1'b1; 
                                          address <= `SPISR; 
                                       end
									   
                          //`GPO_WR:     begin 
                                          //main_sm <= `S_WDATA_ST; // Go to `S_WDATA_ST state when the SPI command is Write GPO
                                          //gpio_addr <= rd_data;
                                          //rd_en <= 1'b1; 
                                          //address <= `SPISR; 
                                       //end
                          //`MEM_WR:     begin 
                                          //main_sm <= `S_WDATA_ST; // Go to `S_WDATA_ST state when the SPI command is Write Memory 
                                          //mem_addr <= rd_data[MEM_ADDR_WIDTH-1:0];  
                                          //rd_en <= 1'b1; 
                                          //address <= `SPISR; 
                                       //end
                          //`GPI_RD:     begin 
                                          //main_sm <= `S_DATA_RD;  // Go to `S_DATA_RD state when the SPI command is Read GPI
                                          //gpio_addr <= rd_data;
                                          //rd_en <= 1'b1; 
                                          //address <= `SPISR; 
                                       //end
                          //`MEM_RD:     begin 
                                          //main_sm <= `S_DATA_RD;  // Go to `S_DATA_RD state when the SPI command is Read Memory
                                          //mem_addr <= rd_data[MEM_ADDR_WIDTH-1:0];  
                                          //rd_en <= 1'b1; 
                                          //address <= `SPISR; 
                                       //end           
                          //`IRQ_EN_RD:  main_sm <= `S_IDLE;        // Go to `S_IDLE state when the SPI command is IRQ Enable Read                                      
                          //`IRQ_ST:     main_sm <= `S_IDLE;        // Go to `S_IDLE state when the SPI command is IRQ Status
                          `REV_ID:     main_sm <= `S_IDLE;        // Go to `S_IDLE state when the SPI command is Revision ID                              
                          endcase
                       end
          // Wait for the SPI write data ready in the RXDR register       
          `S_WDATA_ST: begin
                          if (wb_xfer_done && spi_rx_rdy) begin
                             main_sm <= `S_DATA_WR;            // Go to `S_DATA_WR state when the SPI write data is ready in the RXDR register
                             rd_en <= 1'b1;                        
                             address <= `SPIRXDR;
                          end else if (wb_xfer_done && spi_xfer_done)   
                             main_sm <= `S_IDLE;               // Go to `S_IDLE state when the SPI transfer is complete
                          else if (wb_xfer_done) begin
                             rd_en <= 1'b1;                    // Otherwise, keep read SR register in the current state
                             address <= `SPISR;
                          end  
                 
                          //if (mem_wr) begin
                             //mem_addr <= mem_addr + 8'b1;
                             
                             //if (mem_burst_cnt !== MAX_MEM_BURST_NUM)
                                //mem_burst_cnt <= mem_burst_cnt + 8'b1;
                          //end      
                       end
          // Load SPI data                             
          `S_DATA_WR:  if (wb_xfer_done) begin
                          case (spi_cmd) 
                          `CS_SEL:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          cs_dout <= rd_data[GPO_DATA_WIDTH-1:0]; 
                                       end	
                          `INPUT_SEL:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          input_sel <= rd_data[3:0]; 
                                       end	
                          `MU_SEL:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          mu_sel <= rd_data[2:0]; 
                                       end	
                          `AVK_SEL:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          avk_sel <= rd_data[3:0]; 
                                       end	
                          `REF_SEL:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          ref_sel <= rd_data[0:0]; 
                                       end	
                          `FIL_SEL:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          fil1_sel <= rd_data[0:0]; 
                                          fil2_sel <= rd_data[0:0]; 
                                       end			
					      `FIFO_RD:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          fifo_rd_en <= 1'b1; 
                                       end		
                          //`GPI_LD:     begin 
                                          //main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Latch GPI
                                          //gpi_ld <= rd_data[0]; 
                                       //end
                          //`IRQ_EN_WR:  begin 
                                          //main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is IRQ Enable Write
                                          //irq_en <= rd_data[IRQ_NUM-1:0]; 
                                       //end
                          //`IRQ_CLR:    begin 
                                          //main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is IRQ Clear
                                          //irq_clr <= rd_data[IRQ_NUM-1:0]; 
                                       //end
                          //`GPO_WR:     begin 
                                          //main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          //cs_dout <= rd_data[GPO_DATA_WIDTH-1:0]; 
                                          //gpio_wr <= 1'b1; 
                                       //end
                          //`MEM_WR:     begin 
                                          //if (spi_xfer_done) begin        
                                             //main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write Memory and
                                                                      ////the current SPI transaction is ended
                                             //rd_en <= 1'b0;                      
                                          //end else begin
                                             //main_sm <= `S_WDATA_ST; // Go to `S_WDATA_ST state when the SPI command is Write Memory but
                                                                      //the current SPI transaction is not ended
                                             //rd_en <= 1'b1;
                                          //end
                                       
                                          //address <= `SPISR; 
                                                                                                         
                                          //mem_wdata <= rd_data;
                                          
                                          //if (mem_burst_cnt !== MAX_MEM_BURST_NUM)
                                             //mem_wr <= 1'b1; 
                                          //else
                                             //mem_wr <= 1'b0;   
                                       //end 
                          endcase
                       end
          // Write the SPI read data to the TXDR register    
          //`S_DATA_RD:  begin
                          //if (wb_xfer_done && spi_tx_rdy) begin
                             //case (spi_cmd) 
                             //`GPI_RD:  begin 
                                          //main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Read GPI
                                          //wr_en <= 1'b1; 
                                          //address <= `SPITXDR;
                                          //wr_data <= gpio_din[GPI_DATA_WIDTH-1:0]; 
                                       //end
                             //`MEM_RD:  begin 
                                          //main_sm <= `S_RDATA_ST; // Go to `S_RDATA_ST state when the SPI command is Read Memory
                                          //wr_en <= 1'b1; 
                                          //address <= `SPITXDR;
                                          
                                          //if (mem_burst_cnt !== MAX_MEM_BURST_NUM)
                                             //wr_data <= mem_rdata; // Write memory read data when memory burst number is no more than MAX_MEM_BURST_NUM 
                                          //else
                                             //wr_data <= 8'hFF;     // Write all '1's when memory burst number is more than MAX_MEM_BURST_NUM
                                       //end
                             //endcase  
                                                  
                             //if (spi_xfer_done) begin
                                //main_sm <= `S_IDLE;               // Go to `S_IDLE state when the current SPI transaction is complete
                                //wr_en <= 1'b0;
                             //end   
                          //end else if (wb_xfer_done && spi_xfer_done)   
                             //main_sm <= `S_IDLE;                  // Go to `S_IDLE state when the current SPI transaction is complete
                          //else if (wb_xfer_done) begin
                             //rd_en <= 1'b1;
                             //address <= `SPISR;
                          //end   
                       //end 
          // Wait for the SPI read data to be transmitted from the TXDR register
          //`S_RDATA_ST: begin 
                          //if (wb_xfer_done) begin
                             //main_sm <= `S_DATA_RD;               // Go to `S_DATA_RD state when the SPI read data is transmitted from in the TXDR register
                             //rd_en <= 1'b1;
                             //address <= `SPISR;
                          //end  
                          
                          //if (wr_en) begin 
                             //mem_addr <= mem_addr + 8'b1; 
                             
                             //if (mem_burst_cnt !== MAX_MEM_BURST_NUM)
                                //mem_burst_cnt <= mem_burst_cnt + 8'b1; 
                          //end      
                       //end   
                                         
          default: main_sm <= `S_IDLE;                                
          endcase              
       end

    
endmodule     
    
    
    