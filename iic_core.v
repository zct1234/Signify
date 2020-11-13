module iic_core 
  (
   input 	    CLK_100K_SDA, CLK_100K_SCL,
   input 	    reset_n,

   input [7:0] 	    iic_addr,
   input [7:0] 	    iic_datain,
   output reg [7:0]   iic_dataout,

   input 	       iic_enable,
   output reg 	    iic_busy,
   output reg 	    iic_ackerror,
   output reg 	    iic_arbitlost,
   
   input 	       scl_i, sda_i,
   output          scl_o, sda_o,
   output reg 	    scl_t, sda_t
   );

   parameter [2:0] IIC_IDLE=3'h1, IIC_START=3'h2, IIC_ADDR=3'h3, IIC_ACKA=3'h4, IIC_DATA=3'h5, IIC_ACKD=3'h6, IIC_STOP=3'h7;
   
   reg [3:0] 	iic_core_state, iic_core_nextstate; 
   reg [7:0] 	addr_i, datain_i;   
   reg [7:0] 	sdain;
   reg [3:0] 	bit_count;  
   reg         sdaout;
   
   always @(posedge CLK_100K_SDA or negedge reset_n)
     if (~reset_n) iic_core_state <= IIC_IDLE;
     else iic_core_state <= iic_core_nextstate;
   
   always @(*) begin            
      iic_core_nextstate <= IIC_IDLE;           
      case (iic_core_state)
        IIC_IDLE  :  iic_core_nextstate <= iic_enable ? 
                                           IIC_START : IIC_IDLE;
        
        IIC_START :  iic_core_nextstate <= IIC_ADDR;
        
        IIC_ADDR  :  iic_core_nextstate <= iic_arbitlost ? 
                                           IIC_IDLE : bit_count ? IIC_ADDR : IIC_ACKA;
        
        IIC_ACKA  :  iic_core_nextstate <= iic_ackerror ? 
                                           IIC_STOP : IIC_DATA;
        
        IIC_DATA  :  iic_core_nextstate <= iic_arbitlost ? 
                                           IIC_IDLE : bit_count ? IIC_DATA : IIC_ACKD;
        
        IIC_ACKD  :  iic_core_nextstate <= (iic_enable & (addr_i == iic_addr)) ? 
                                           IIC_DATA : iic_enable ? IIC_IDLE : IIC_STOP;
        
        IIC_STOP  :  iic_core_nextstate <= IIC_IDLE;
      endcase 
   end 
   
   always @(posedge CLK_100K_SDA or negedge reset_n)
     if (~reset_n) begin
        sda_t <= 0; sdaout <= 1;
        bit_count <= 0; 
        iic_busy <= 0;
     end else begin
        sda_t <= 1; sdaout <= 1;
        iic_busy <= 1;
        case (iic_core_nextstate)
          IIC_IDLE  : begin 
             sda_t <= 0;
             iic_busy <= 0;
          end
          IIC_START : begin 
             sdaout <= 0;
             bit_count <= 8;
          end
          IIC_ADDR  : begin
             sdaout <= iic_addr[bit_count - 1];
             bit_count <= bit_count - 1;             
          end
          IIC_ACKA  : begin
             sda_t <= 0;
             bit_count <= 8;
          end
          IIC_DATA  : begin
             sda_t <= ~addr_i[0];
             sdaout <= addr_i[0] ? 1'b1 : datain_i[bit_count - 1]; 
             bit_count <= bit_count - 1; 
          end
          IIC_ACKD  : begin
             sda_t <= (iic_enable & addr_i[0]) & (addr_i == iic_addr);
             sdaout <= ~((iic_enable & addr_i[0]) & (addr_i == iic_addr));	     
             bit_count <= 8; iic_busy <= 0;
          end
          IIC_STOP  : begin 
             sdaout <= 0;
             iic_busy <= 0;
          end
        endcase 
     end
   
   always @(negedge CLK_100K_SCL or negedge reset_n)
     if (~reset_n) begin 
        sdain <= 0; 
        scl_t <= 0;
        iic_ackerror <= 0;
        iic_arbitlost <= 0;
        addr_i <= 0; datain_i <= 0; 
     end else begin
        sdain <= {sdain[6:0],sda_i};
        scl_t <= 1;
        case (iic_core_state)
          IIC_IDLE  : scl_t <= 0;
          IIC_START : begin
             addr_i <= iic_addr; datain_i <= iic_datain;
          end
          IIC_ADDR  : iic_arbitlost <= (sdaout != sda_i);
          IIC_ACKA  : iic_ackerror  <= sda_i;
          IIC_DATA  : iic_arbitlost <= sda_t ? (sdaout != sda_i) : 0;
          IIC_ACKD  : begin 
             iic_ackerror  <= sda_t ? sda_i : 0;
             datain_i <= iic_datain;
             if (addr_i[0]) iic_dataout <= sdain;
          end
          IIC_STOP  : scl_t <= 0;
        endcase 
     end 
  
   assign scl_o = CLK_100K_SCL;
   assign sda_o = sdaout & CLK_100K_SDA;
// assign scl = scl_t ? scl_o : 1'bz;
// assign sda = sda_t ? sda_o : 1'bz;
   
endmodule
