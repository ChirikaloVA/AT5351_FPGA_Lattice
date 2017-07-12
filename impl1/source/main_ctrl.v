`timescale 1 ns/ 1 ps

module main_ctrl (                                                     
    clk,          // System clock
    rst_n,        // System reset
    spi_csn,      // Hard SPI chip-select (active low)
    spi_clk,
	wr_data_read,
	spi_bit_3,
	spi_bit_0,
	
	//address,      // Local address for the WISHBONE interface
    //wr_en,        // Local write enable for the WISHBONE interface
    wr_data,      // Local write data for the WISHBONE interface        
    //rd_en,        // Local read enable for the WISHBONE interface          
    rd_data,      // Local read data for the WISHBONE interface          
    wb_xfer_done, // WISHBONE transfer done    
    wb_xfer_req,   // WISHBONE transfer request 
	spi_xfer_done,     // SPI transmitting complete (1: complete, 0: in progress) 
    

    input_sel,
	mu_sel,
	avk_sel,
	ref_sel,
	fil1_sel,
	fil2_sel,
	relay_reset,
	
	cs_out,    // GPIO port output data bus
	
	count_mode,
	ref_avk_1,
	read_meas_data,
	meas_data,
	fifo_level,
	fifo_level_reset,
	spi_cmd           // The slim buffer version of the SPI command used for the performance 
    
    );
    
	
	reg  [2:0] cs_dout;    // GPIO port output data bus
    
	
    input  wire    clk;          // System clock
    input  wire    rst_n;        // System reset
    input  wire    spi_csn;      // Hard SPI chip-select (active low)
    input  wire	   spi_clk;
	output reg     wr_data_read;
	output reg     spi_bit_3;
	output reg     spi_bit_0;
	
	//output reg  [7:0] address /* synthesis syn_keep*/;      // Local address for the WISHBONE interface
    //output reg        wr_en;        // Local write enable for the WISHBONE interface
    output reg  [7:0] wr_data;      // Local write data for the WISHBONE interface        
    //output reg        rd_en;        // Local read enable for the WISHBONE interface          
    input  wire [7:0] rd_data;      // Local read data for the WISHBONE interface          
    input  wire       wb_xfer_done; // WISHBONE transfer done    
    input  wire       wb_xfer_req;   // WISHBONE transfer request 
	output wire       spi_xfer_done;     // SPI transmitting complete (1: complete, 0: in progress) 
    

    output reg	[3:0] input_sel;
	output reg	[2:0] mu_sel;
	output reg	[3:0] avk_sel;
	output wire		ref_sel;
	output reg		fil1_sel;
	output reg		fil2_sel;
	output wire 	relay_reset;
	
	output wire  [2:0]	cs_out;    // GPIO port output data bus
	
	output reg	count_mode;
	reg 		ref_avk_0;
	input wire 	ref_avk_1;
	output reg	read_meas_data;
	input wire [7:0] meas_data;
	input wire [3:0] fifo_level;
	output reg fifo_level_reset;
	output reg  [3:0] spi_cmd /* synthesis syn_keep*/;          // The slim buffer version of the SPI command used for the performance 
    	
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
	`define S_TXDR_WR2  4'hD
    
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
        
       
       
    reg [3:0]  main_sm /* synthesis syn_keep*/;           // The state register of the main state machine
    reg        spi_csn_buf0_p;    // The postive-egde sampling of spi_csn
    reg        spi_csn_buf1_p;    // The postive-egde sampling of spi_csn_buf0_p 
    reg        spi_csn_buf2_p;    // The postive-egde sampling of spi_csn_buf1_p
    reg        spi_clk_buf0_p;    // The postive-egde sampling of spi_clk
    reg        spi_clk_buf1_p;    // The postive-egde sampling of spi_clk_buf0_p 
	reg [2:0]  spi_clk_cnt;		  // Bit counter of SPI transfer
    wire       spi_cmd_start;     // A new SPI command start
    reg        spi_cmd_start_reg; // The buffer of a new SPI command start
    reg        spi_idle;          // SPI IDLE signal    
    wire       spi_rx_rdy;        // SPI receive ready    
    wire       spi_tx_rdy;        // SPI transmit ready             
    //reg  [7:0] mem_burst_cnt;

	reg [3:0] 	spi_byte_counter;	

    wire [7:0] meas_state;
    assign meas_state = {2'b00, count_mode, ~count_mode, fifo_level[3:0]};
	
	
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
       
	   
	   
    // Bufferring spi_clk with postive edge                    
    always @(posedge clk or posedge rst_n)
       if (rst_n)spi_clk_buf0_p <= 1'b0;
       else      spi_clk_buf0_p <= spi_clk;	   

	// Bufferring spi_clk_buf0_p with postive edge                    
    always @(posedge clk or posedge rst_n)
       if (rst_n) spi_clk_buf1_p <= 1'b0;
       else       spi_clk_buf1_p <= spi_clk_buf0_p;	   


	reg [2:0] spi_clk_cnt_prev;
	// Bit counter for spi transfer              
    always @(posedge spi_clk_buf1_p or posedge rst_n)
       if (rst_n) spi_clk_cnt <= 3'b0;
       else begin  
		  if (spi_csn_buf1_p == 1'b0) spi_clk_cnt <= spi_clk_cnt + 3'b1;	  
	      else spi_clk_cnt <= 3'b0;
		  
		  end


	
	always @(posedge clk or posedge rst_n) begin
		if (rst_n) begin
			spi_bit_3 <= 1'b0;
			spi_bit_0 <= 1'b0;
			spi_clk_cnt_prev <= 3'b0;
			end
		else begin
			if (spi_clk_cnt_prev != spi_clk_cnt) spi_clk_cnt_prev <= spi_clk_cnt;
			
			if (spi_clk_cnt_prev != spi_clk_cnt && spi_clk_cnt == 3'd4) spi_bit_3 <= 1'b1;
			else spi_bit_3 <= 1'b0;	
			
			if (spi_clk_cnt_prev != spi_clk_cnt && spi_clk_cnt == 3'd1) spi_bit_0 <= 1'b1;
			else spi_bit_0 <= 1'b0;	
			
			end
		end


    // Generate SPI command start buffer signal                 
    always @(posedge clk or posedge rst_n)
       if (rst_n)
          spi_cmd_start_reg <= 1'b0;
       else
          if (spi_csn_buf2_p && !spi_csn_buf1_p)
             spi_cmd_start_reg <= 1'b1;
          //else if (main_sm == `S_IDLE || main_sm == `S_RXDR_RD || (!spi_csn_buf2_p && spi_csn_buf1_p))
          else if (!spi_csn_buf2_p && !spi_csn_buf1_p)
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
          wr_data <= 8'd0;
          input_sel <= 4'b1111;
		  avk_sel <= 4'b1111;
          mu_sel <= 3'b110;
          ref_avk_0 <= 1'b0;
          fil1_sel <= 1'b0;       
          fil2_sel <= 1'b1;       
          cs_dout <= 3'b111;
		  
		  count_mode <= 1'b0;
		  read_meas_data <= 1'b0;
		  
       end else begin
          
		  read_meas_data <= 1'b0;
          wr_data_read <= 1'b0;
		  
		  fifo_level_reset <= 1'b0;
          case (main_sm)
          // IDLE state
          `S_IDLE:     if (spi_cmd_start) begin
						  wr_data <= 8'd0;
                          main_sm <= `S_CMD_LD;            // Go to `S_RSDR_RD state when a new SPI command starts and
                                                            // WISHBONE is ready to transfer
						end
/*						
          // Read SPI EFB RXDR register first to get ready to read the SPI command next
          `S_RXDR_RD:  if (wb_xfer_done) begin
                          main_sm <= `S_TXDR_WR;            // Go to `S_TXDR_WR state when the RXDR register read is done
                          wr_data <= 8'd0;
                       end
				   
          // Write dummy data to the SPI EFB TXDR register in order to write next data to the register correctly       
          `S_TXDR_WR:  if (wb_xfer_done) begin                
                          main_sm <= `S_CMD_ST;             // Go to `S_CMD_ST state when the TXDR register write is done
                       end
					   
          // Wait for the SPI command is ready in the RXDR register                                              
          `S_CMD_ST:   begin 
                          if (wb_xfer_done && spi_rx_rdy) begin  
                             main_sm <= `S_CMD_LD;          // Go to `S_CMD_LD state when the SPI command is ready in the RXDR register
                            end 
						  else if (wb_xfer_done && spi_xfer_done)   
                             main_sm <= `S_IDLE;            // Go to `S_IDLE state when the SPI transfer is complete 
                          else if (wb_xfer_done && spi_tx_rdy) begin
                             //main_sm <= `S_TXDR_WR;         // Go to `S_TXDR_WR state to rewrite the TXDR register when SPI transmit is ready
                            end 
						  else if (wb_xfer_done) begin
                            end  
                       end 
*/
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
					   else if (spi_xfer_done) main_sm <= `S_IDLE;
          // Decode the SPI command              
          `S_CMD_DEC:  begin
                          case (spi_cmd)
                          `SET_OUT:     begin 
                                          main_sm <= `S_ADDR_LD;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_data <= 8'h00;
										  wr_data_read <= 1'b1;
                                       end  
                          `READ_OUT:     begin 
                                          main_sm <= `S_ADDR_LD;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_data <= 8'h00;
										  wr_data_read <= 1'b1;
                                       end                                     
                          `SEL_SPI:     begin 
                                          main_sm <= `S_ADDR_LD;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_data <= 8'h00;
										  wr_data_read <= 1'b1;
                                       end                                     
                          `MEAS_STATE:  begin 
                                          main_sm <= `S_ADDR_LD;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_data <= 8'h00;
										  wr_data_read <= 1'b1;
                                          //wr_data <= meas_state;
                                       end                                     
                          `MEAS_DATA:   begin 
                                          main_sm <= `S_ADDR_LD;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_data <= 8'h00;
										  wr_data_read <= 1'b1;
										  //if (spi_cmd == `MEAS_DATA && spi_bit_3) read_meas_data <= 1'b1;
										  read_meas_data <= 1'b1;
										  
										  //read_meas_data <= 1'b0;
                                          //wr_data <= meas_data;
                                       end                                     
                          `SETTINGS:     begin 
                                          main_sm <= `S_ADDR_LD;     // Go to `S_IDLE state when the SPI command is Enable
                                          wr_data <= 8'd0;
										  wr_data_read <= 1'b1;
                                       end      

                          // `REV_ID:     begin 
                          //                 main_sm <= `S_TXDR_WR1; // Go to `S_TXDR_WR1 state when the SPI command is Revision ID
                          //                 wr_en <= 1'b1; 
                          //                 address <= `SPITXDR; 
                          //                 wr_data <= REVISION_ID; 
                          //              end
                          `INVALID:   begin 
										main_sm <= `S_IDLE;        // Go to `S_IDLE state when the SPI command is illegal
										wr_data <= 8'hFF;
										end
                          default:     begin 
										main_sm <= `S_IDLE;        // Go to `S_IDLE state when the SPI command is illegal
										wr_data <= 8'hFF;
										end
                          endcase
                  
                          if (spi_xfer_done) begin        
                             main_sm <= `S_IDLE;               // Go to `S_IDLE state when the current SPI transaction is ended
                          end                           

                          //mem_burst_cnt <= 'b0;
                                                                
                       end  

/*
          // For GPIO/memory commands, write dummy data to the SPI EFB TXDR register in order to write next data to the register correctly.
          // For IRQ_ST/REV_ID commands, write their data to the SPI EFB TXDR register.                
          `S_TXDR_WR1: if (wb_xfer_done) begin
                          main_sm <= `S_ADDR_ST;               // Go to `S_ADDR_ST state when the TXDR register write is done
                       end
					   
					   
          // For GPIO/memory commands, wait for the address ready in the RXDR register.
          // For IRQ_ST/REV_ID commands, wait for the data write done             
          `S_ADDR_ST:  begin 
                          if (wb_xfer_done && spi_rx_rdy) begin
                              main_sm <= `S_ADDR_LD;           // Go to `S_ADDR_LD state when the address is ready in the RXDR register
                              
							  if (spi_xfer_done) begin
                                 main_sm <= `S_IDLE;           // Go to `S_IDLE state when the current SPI transaction is complete
                              end   
							end 
						  else if (wb_xfer_done && spi_xfer_done)   
                             main_sm <= `S_IDLE;               // Go to `S_IDLE state when the SPI transfer is complete
                          else if (wb_xfer_done && spi_tx_rdy) begin
                             //main_sm <= `S_TXDR_WR1;           // Go to `S_TXDR_WR1 state to rewrite the TXDR register when SPI transmit is ready
                            end 
						  else if (wb_xfer_done) begin
                             end
						  
						  if (spi_cmd == `MEAS_DATA && spi_bit_3) read_meas_data <= 1'b1;
                              
							
                       end 
*/
          // For GPIO/memory commands, load address.
          // For IRQ_ST/REV_ID commands, go to `S_IDLE state.                
          `S_ADDR_LD:  if (wb_xfer_done) begin
						  case (spi_cmd) 
                          `SET_OUT:     begin 
										  main_sm <= `S_DATA_WR; // Go to `S_WDATA_ST state when the SPI command is Write GPO
										  wr_data_read <= 1'b1;
										  
                                          case(rd_data[7:4])
											//
											4'h1: begin
													case (rd_data[3:0])
														4'h1: begin 
																input_sel <= 4'b1110;
																wr_data <= 8'hAA;
																end
														4'h2: begin 
																input_sel <= 4'b1101;
																wr_data <= 8'hAA;
																end
														4'h3: begin
																input_sel <= 4'b1011;
																wr_data <= 8'hAA;
																end
														4'h4: begin
																input_sel <= 4'b0111;
																wr_data <= 8'hAA;
																end
														4'hF: begin
																input_sel <= 4'b1111;
																wr_data <= 8'hAA;
																end
														default: wr_data <= 8'hFF;
														endcase
													
													end
											4'h2: begin
													case (rd_data[3:0])
														4'h1: begin
																mu_sel <= 3'b110;
																wr_data <= 8'hAA;
																end
														4'h2: begin
																mu_sel <= 3'b101;
																wr_data <= 8'hAA;
																end
														4'h3: begin
																mu_sel <= 3'b011;
																wr_data <= 8'hAA;
																end
														default: wr_data <= 8'hFF;
														endcase
													
													end
											4'h3: begin
													case (rd_data[3:0])
														4'h1: begin 
																avk_sel <= 4'b1110;
																wr_data <= 8'hAA;
																end
														4'h2: begin 
																avk_sel <= 4'b1101;
																wr_data <= 8'hAA;
																end
														4'h3: begin
																avk_sel <= 4'b1011;
																wr_data <= 8'hAA;
																end
														4'h4: begin
																avk_sel <= 4'b0111;
																wr_data <= 8'hAA;
																end
														4'hF: begin
																avk_sel <= 4'b1111;
																wr_data <= 8'hAA;
																end
														default: wr_data <= 8'hFF;
														endcase
													
													end
											4'h4: begin
													case(rd_data[3:0])
														4'h0: begin
																fil1_sel <= 1'b1;
																wr_data <= 8'hAA;
																end
														4'hF: begin
																fil1_sel <= 1'b0;
																wr_data <= 8'hAA;
																end
														default: wr_data <= 8'hFF;
														endcase
													end
											4'h5: begin
													case(rd_data[3:0])
														4'h0: begin
																fil2_sel <= 1'b1;
																wr_data <= 8'hAA;
																end
														4'hF: begin
																fil2_sel <= 1'b0;
																wr_data <= 8'hAA;
																end
														default: wr_data <= 8'hFF;
														endcase
													end
											4'h6: begin
													case(rd_data[3:0])
														4'h0: begin
																ref_avk_0 <= 1'b0;
																wr_data <= 8'hAA;
																end
														4'hF: begin
																ref_avk_0 <= 1'b1;
																wr_data <= 8'hAA;
																end
														default: wr_data <= 8'hFF;
														endcase
													end
											default: wr_data <= 8'hFF;
											endcase
                                       end
                          `READ_OUT:   begin 
										main_sm <= `S_DATA_WR;     // Go to `S_IDLE state when the SPI command is Write GPO
										wr_data_read <= 1'b1;
										
										case(rd_data[7:0])
										  8'd1: wr_data <= {4'd0,input_sel};
										  8'd2:	wr_data <= {5'd0,mu_sel};
										  8'd3: wr_data <= {4'd0,avk_sel};
										  8'd4: wr_data <= {7'd0,fil1_sel};
										  8'd5: wr_data <= {7'd0,fil2_sel};
										  8'd6: wr_data <= {7'd0,ref_sel};
										  default: wr_data <= 8'hFF;
										  endcase
                                       end 
                          `SEL_SPI:   begin 
										main_sm <= `S_DATA_WR;     // Go to `S_IDLE state when the SPI command is Write GPO
										wr_data_read <= 1'b1;
										
										case(rd_data[7:0])
										  8'h1: begin 
												cs_dout <= 3'b110; 
												wr_data <= 8'hAA;
												end 
										  8'h2:	begin
												cs_dout <= 3'b101;
												wr_data <= 8'hAA;
												end
										  8'h3: begin
												cs_dout <= 3'b011;
												wr_data <= 8'hAA;
												end
										  8'hF: begin
												cs_dout <= 3'b111;
												wr_data <= 8'hAA;
												end
										  default: wr_data <= 8'hFF;
										  endcase
                                       end 		
						  `MEAS_STATE: begin
										main_sm <= `S_DATA_WR;     // Go to `S_IDLE state when the SPI command is Write GPO
										wr_data <= meas_state;
										wr_data_read <= 1'b1;
										end
						  `MEAS_DATA: begin
										main_sm <= `S_DATA_WR;     // Go to `S_IDLE state when the SPI command is Write GPO
										
										wr_data <= meas_data;
										wr_data_read <= 1'b1;
										read_meas_data <= 1'b1;
										//wr_data <= 8'h55;
										end
						  `SETTINGS: begin
										main_sm <= `S_DATA_WR;     // Go to `S_IDLE state when the SPI command is Write GPO
										wr_data_read <= 1'b1;
										
										case(rd_data[7:0])
											  8'h1: begin 			//—чет в режиме измерени€
													count_mode <= 1'b0; 
													wr_data <= 8'hAA;
													end 
											  8'h2:	begin			//—чет в режиме ј¬  Ємкостей
													count_mode <= 1'b1; 
													wr_data <= 8'hAA;
													end
											  8'h3:	begin			//—брос счетчика FIFO
													//count_mode <= 1'b1; 
													fifo_level_reset <= 1'b1;
													wr_data <= 8'hAA;
													end	
											  default: wr_data <= 8'hFF;
											  endcase										
										end
                          default:     begin 
										main_sm <= `S_IDLE;        // Go to `S_IDLE state when the SPI command is illegal
										wr_data <= 8'hFF;
										end
                          endcase
                      
					  end
					  else if (spi_xfer_done) main_sm <= `S_IDLE;
/*
          // For GPIO/memory commands, write dummy data to the SPI EFB TXDR register in order to write next data to the register correctly.
          // For IRQ_ST/REV_ID commands, write their data to the SPI EFB TXDR register.                
          `S_TXDR_WR2: if (wb_xfer_done) begin
                          main_sm <= `S_WDATA_ST;               // Go to `S_ADDR_ST state when the TXDR register write is done
                       end




          // Wait for the SPI write data ready in the RXDR register       
          `S_WDATA_ST: begin
                          if (wb_xfer_done && spi_rx_rdy) begin
                             main_sm <= `S_DATA_WR;            // Go to `S_DATA_WR state when the SPI write data is ready in the RXDR register
                             if (spi_xfer_done) begin
                                 main_sm <= `S_IDLE;           // Go to `S_IDLE state when the current SPI transaction is complete
                              end 
                          end else if (wb_xfer_done && spi_xfer_done)   
                             main_sm <= `S_IDLE; 
                          else if (wb_xfer_done && spi_tx_rdy) begin
                             //main_sm <= `S_TXDR_WR1;           // Go to `S_TXDR_WR1 state to rewrite the TXDR register when SPI transmit is ready
                             end                  // Go to `S_IDLE state when the SPI transfer is complete
                          else if (wb_xfer_done) begin
                             
                          end  
							
						  if (spi_cmd == `MEAS_DATA && spi_bit_3) read_meas_data <= 1'b1;
    
                       end
					   
*/
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
                                          //main_sm <= `S_TXDR_WR2;     // Go to `S_IDLE state when the SPI command is Write GPO
										  
										  wr_data <= meas_data;
										  wr_data_read <= 1'b1;
										  read_meas_data <= 1'b1;
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
						  default:     main_sm <= `S_IDLE;        // Go to `S_IDLE state when the SPI command is Revision ID                              
                          endcase
                       end
					   else if (spi_xfer_done) main_sm <= `S_IDLE;	

          default: main_sm <= `S_IDLE;                                
          endcase              
       end
    
	
	
	ref_choise REF_CHOISE(
		.ref_mode_1(ref_avk_0),
		.ref_mode_2(ref_avk_1),
		.mode(count_mode),
		.ref_avk(ref_sel)
		);	
	
	
endmodule     
    
    
	
module ref_choise(
	input wire ref_mode_1,
	input wire ref_mode_2,
	input wire mode,
	output wire ref_avk
	);
	
	assign ref_avk = mode ? ref_mode_2 : ref_mode_1;
	
endmodule	
	
    