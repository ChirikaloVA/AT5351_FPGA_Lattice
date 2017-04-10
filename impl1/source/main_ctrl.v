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
	
	output wire  [2:0]       				cs_out,    // GPIO port output data bus
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
    
	
	reg  [2:0] cs_dout;    // GPIO port output data bus
    
    // The definitions for SPI EFB register address
    `define SPITXDR 8'h59
    `define SPISR   8'h5A
    `define SPIRXDR 8'h5B
    
    // The definitions for the state values of the main state machine
    `define S_IDLE      4'h0    
    `define S_RXDR_RD   4'h1    // Read SPI EFB RXDR register first to get ready to read the SPI command next
    `define S_TXDR_WR   4'h2    // Write dummy data to the SPI EFB TXDR register in order to write next data to the register correctly
    `define S_CMD_ST    4'h3    // Wait for the SPI command is ready in the RXDR register 
    `define S_CMD_LD    4'h4    // Load the SPI command to improve the performance because the path delay from the RXDR register is very big 
    `define S_CMD_DEC   4'h5    // Decode the SPI command
    `define S_TXDR_WR1  4'h6
    `define S_ADDR_ST   4'h7
    `define S_ADDR_LD   4'h8
    `define S_WDATA_ST  4'h9
    `define S_DATA_WR   4'hA  
    `define S_DATA_RD   4'hB    
    `define S_RDATA_ST  4'hC
    
    // The definitions for the SPI command values of the reference design
    `define C_SET_OUT        8'h01 
    `define C_READ_OUT     8'h02  
    `define C_SEL_SPI        8'h03  
    `define C_MEAS_STATE       8'h04  
    `define C_MEAS_DATA       8'h05
    `define C_SETTINGS       8'h06
    
    `define C_REV_ID     8'h9F 
    
    // The definitions for the slim version of the SPI command values
    `define SET_OUT       4'h0  
    `define READ_OUT    4'h1  
    `define SEL_SPI       4'h2  
    `define MEAS_STATE      4'h3  
    `define MEAS_DATA      4'h4 
    `define SETTINGS      4'h5
        // `define FIFO_RD      4'h6
        
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

    reg [7:0] meas_state;
    reg [7:0] meas_data;


	assign cs_out[2:0] = spi_csn_buf0_p ? cs_dout[2:0] : 3'b111;

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
          input_sel <= 4'b1111;
		  avk_sel <= 4'b1111;
          mu_sel <= 3'b110;
          ref_sel <= 1'b0;
          fil1_sel <= 1'b0;       
          fil2_sel <= 1'b1;       
          cs_dout <= 3'b111;

       end else begin
          rd_en <= 1'b0;
          wr_en <= 1'b0;
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
                          main_sm <= `S_CMD_ST;            // Go to `S_TXDR_WR state when the RXDR register read is done
                          wr_en <= 1'b1; 
                          address <= `SPITXDR; 
                          wr_data <= 8'd0;
                       end
/*				   
          // Write dummy data to the SPI EFB TXDR register in order to write next data to the register correctly       
          `S_TXDR_WR:  if (wb_xfer_done) begin                
                          main_sm <= `S_CMD_ST;             // Go to `S_CMD_ST state when the TXDR register write is done
                          rd_en <= 1'b1;
                          address <= `SPISR;
                       end
*/					   
          // Wait for the SPI command is ready in the RXDR register                                              
          `S_CMD_ST:   begin 
                          if (wb_xfer_done && spi_rx_rdy) begin  
                             main_sm <= `S_CMD_LD;          // Go to `S_CMD_LD state when the SPI command is ready in the RXDR register
                             rd_en <= 1'b1;                        
                             address <= `SPIRXDR;
							end 
						  else if (wb_xfer_done && spi_xfer_done)   
                             main_sm <= `S_IDLE;            // Go to `S_IDLE state when the SPI transfer is complete 
                          else if (wb_xfer_done && spi_tx_rdy) begin
                             //main_sm <= `S_TXDR_WR;         // Go to `S_TXDR_WR state to rewrite the TXDR register when SPI transmit is ready
                             wr_en <= 1'b1; 
                             address <= `SPITXDR;                              
							end 
						  else if (wb_xfer_done) begin
                             rd_en <= 1'b1;                 // Otherwise, keep read SR register in the current state
                             address <= `SPISR;
							end  
                       end 
          // Load the SPI command to improve the performance because the path delay from the RXDR register is very big 
          `S_CMD_LD:   if (wb_xfer_done) begin
                          main_sm <= `S_CMD_DEC;            // Go to `S_CMD_DEC state when the RXDR register read is done
                          case (rd_data)
                              `C_SET_OUT:    spi_cmd <= `SET_OUT;
                              `C_READ_OUT:   spi_cmd <= `READ_OUT;
                              `C_SEL_SPI:    spi_cmd <= `SEL_SPI;
                              `C_MEAS_STATE: spi_cmd <= `MEAS_STATE;
                              `C_MEAS_DATA:  spi_cmd <= `MEAS_DATA;
                              `C_SETTINGS:   spi_cmd <= `SETTINGS;
                              // `C_REV_ID:     spi_cmd <= `REV_ID;    
                              default:       spi_cmd <= `INVALID;
                          endcase
                       end
          // Decode the SPI command              
          `S_CMD_DEC:  begin
                          case (spi_cmd)
                          `SET_OUT:     begin 
                                          main_sm <= `S_ADDR_ST;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                          wr_data <= 8'h00;
                                       end  
                          `READ_OUT:     begin 
                                          main_sm <= `S_ADDR_ST;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                          wr_data <= 8'h00;
                                       end                                     
                          `SEL_SPI:     begin 
                                          main_sm <= `S_ADDR_ST;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                          wr_data <= 8'h00;
                                       end                                     
                          `MEAS_STATE:  begin 
                                          main_sm <= `S_ADDR_ST;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                          wr_data <= meas_state;
                                       end                                     
                          `MEAS_DATA:   begin 
                                          main_sm <= `S_ADDR_ST;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                          wr_data <= meas_data;
                                       end                                     
                          `SETTINGS:     begin 
                                          main_sm <= `S_ADDR_ST;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_en <= 1'b1; 
                                          address <= `SPITXDR; 
                                          wr_data <= 8'd0;
                                       end      

                          // `REV_ID:     begin 
                          //                 main_sm <= `S_TXDR_WR1; // Go to `S_TXDR_WR1 state when the SPI command is Revision ID
                          //                 wr_en <= 1'b1; 
                          //                 address <= `SPITXDR; 
                          //                 wr_data <= REVISION_ID; 
                          //              end
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

/*
          // For GPIO/memory commands, write dummy data to the SPI EFB TXDR register in order to write next data to the register correctly.
          // For IRQ_ST/REV_ID commands, write their data to the SPI EFB TXDR register.                
          `S_TXDR_WR1: if (wb_xfer_done) begin
                          main_sm <= `S_ADDR_ST;               // Go to `S_ADDR_ST state when the TXDR register write is done
                          rd_en <= 1'b1;
                          address <= `SPISR;
                       end
*/					   
					   
          // For GPIO/memory commands, wait for the address ready in the RXDR register.
          // For IRQ_ST/REV_ID commands, wait for the data write done             
          `S_ADDR_ST:  begin 
                          if (wb_xfer_done && spi_rx_rdy) begin
                              main_sm <= `S_ADDR_LD;           // Go to `S_ADDR_LD state when the address is ready in the RXDR register
                              rd_en <= 1'b1;                        
                              address <= `SPIRXDR;
                              
                              if (spi_xfer_done) begin
                                 main_sm <= `S_IDLE;           // Go to `S_IDLE state when the current SPI transaction is complete
                                 rd_en <= 1'b0;
                              end   
							end 
						  else if (wb_xfer_done && spi_xfer_done)   
                             main_sm <= `S_IDLE;               // Go to `S_IDLE state when the SPI transfer is complete
                          else if (wb_xfer_done && spi_tx_rdy) begin
                             //main_sm <= `S_TXDR_WR1;           // Go to `S_TXDR_WR1 state to rewrite the TXDR register when SPI transmit is ready
                             wr_en <= 1'b1; 
                             address <= `SPITXDR; 
                            end 
						  else if (wb_xfer_done) begin
                             rd_en <= 1'b1;                    // Otherwise, keep read SR register in the current state
                             address <= `SPISR;
							end  
                       end 
          // For GPIO/memory commands, load address.
          // For IRQ_ST/REV_ID commands, go to `S_IDLE state.                
          `S_ADDR_LD:  if (wb_xfer_done) begin
						  case (spi_cmd) 
                          `SET_OUT:     begin 
										  main_sm <= `S_WDATA_ST; // Go to `S_WDATA_ST state when the SPI command is Write GPO
                          
                                          wr_en <= 1'b1;
										  address <= `SPITXDR;
										  case(rd_data[7:4])
											//
											4'h1: begin
													case (rd_data[3:0])
														4'h1: begin 
																input_sel <= 4'b1110;
																wr_data <= 8'hFF;
																end
														4'h2: begin 
																input_sel <= 4'b1101;
																wr_data <= 8'hFF;
																end
														4'h3: begin
																input_sel <= 4'b1011;
																wr_data <= 8'hFF;
																end
														4'h4: begin
																input_sel <= 4'b0111;
																wr_data <= 8'hFF;
																end
														4'hF: begin
																input_sel <= 4'b1111;
																wr_data <= 8'hFF;
																end
														default: wr_data <= 8'h00;
														endcase
													
													end
											4'h2: begin
													case (rd_data[3:0])
														4'h1: begin
																mu_sel <= 4'b1110;
																wr_data <= 8'hFF;
																end
														4'h2: begin
																mu_sel <= 4'b1101;
																wr_data <= 8'hFF;
																end
														4'h3: begin
																mu_sel <= 4'b1011;
																wr_data <= 8'hFF;
																end
														default: wr_data <= 8'h00;
														endcase
													
													end
											4'h3: begin
													case (rd_data[3:0])
														4'h1: begin 
																avk_sel <= 4'b1110;
																wr_data <= 8'hFF;
																end
														4'h2: begin 
																avk_sel <= 4'b1101;
																wr_data <= 8'hFF;
																end
														4'h3: begin
																avk_sel <= 4'b1011;
																wr_data <= 8'hFF;
																end
														4'h4: begin
																avk_sel <= 4'b0111;
																wr_data <= 8'hFF;
																end
														4'hF: begin
																avk_sel <= 4'b1111;
																wr_data <= 8'hFF;
																end
														default: wr_data <= 8'h00;
														endcase
													
													end
											4'h4: begin
													case(rd_data[3:0])
														4'h0: begin
																fil1_sel <= 1'b1;
																wr_data <= 8'hFF;
																end
														4'hF: begin
																fil1_sel <= 1'b0;
																wr_data <= 8'hFF;
																end
														default: wr_data <= 8'h00;
														endcase
													end
											4'h5: begin
													case(rd_data[3:0])
														4'h0: begin
																fil2_sel <= 1'b1;
																wr_data <= 8'hFF;
																end
														4'hF: begin
																fil2_sel <= 1'b0;
																wr_data <= 8'hFF;
																end
														default: wr_data <= 8'h00;
														endcase
													end
											default: wr_data <= 8'h00;
											endcase
                                       end
                          `READ_OUT:   begin 
										main_sm <= `S_WDATA_ST;     // Go to `S_IDLE state when the SPI command is Write GPO
										wr_en <= 1'b1;
										address <= `SPITXDR;
										case(rd_data[3:0])
										  4'd1: wr_data <= {4'd0,input_sel};
										  4'd2:	wr_data <= {5'd0,mu_sel};
										  4'd3: wr_data <= {4'd0,avk_sel};
										  4'd4: wr_data <= {7'd0,fil1_sel};
										  4'd5: wr_data <= {7'd0,fil2_sel};
										  default: wr_data <= 8'hFF;
										  endcase
                                       end 
                          `SEL_SPI:   begin 
										main_sm <= `S_WDATA_ST;     // Go to `S_IDLE state when the SPI command is Write GPO
										wr_en <= 1'b1;
										address <= `SPITXDR;
										case(rd_data[3:0])
										  4'd1: cs_dout <= 3'b110;
										  4'd2:	cs_dout <= 3'b101;
										  4'd3: cs_dout <= 3'b011;
										  default: cs_dout <= 3'b111;
										  endcase
                                       end 								   
                          default:     main_sm <= `S_IDLE;        // Go to `S_IDLE state when the SPI command is Revision ID                              
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
                 
    
                       end
					   
					   
          // Load SPI data                             
          `S_DATA_WR:  if (wb_xfer_done) begin
                          case (spi_cmd) 
                          `SET_OUT:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          //cs_dout <= rd_data[GPO_DATA_WIDTH-1:0]; 
                                       end  
                          `READ_OUT:   begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          //cs_dout <= rd_data[GPO_DATA_WIDTH-1:0]; 
                                       end  
                          `SEL_SPI:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          //mu_sel <= rd_data[2:0]; 
                                       end  
                          `MEAS_STATE:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          //meas_state <= rd_data[3:0]; 
                                       end  
                          `MEAS_DATA:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          //meas_data <= rd_data[0:0]; 
                                       end  
                          `SETTINGS:     begin 
                                          main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          //fil1_sel <= rd_data[0:0]; 
                                          //fil2_sel <= rd_data[0:0]; 
                                       end          
                          //`FIFO_RD:     begin 
                                          //main_sm <= `S_IDLE;     // Go to `S_IDLE state when the SPI command is Write GPO
                                          //fifo_rd_en <= 1'b1; 
                                       //end      

                          endcase
                       end


          default: main_sm <= `S_IDLE;                                
          endcase              
       end
    
endmodule     
    
    
    