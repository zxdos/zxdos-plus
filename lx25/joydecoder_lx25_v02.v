`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 09:00:25 2018-07-20 by Miguel Angel Rodriguez Jodar
//    (c)2014-2020 ZXUNO association.
//    ZXUNO official repository: http://svn.zxuno.com/svn/zxuno
//    Username: guest   Password: zxuno
//    Github repository for this core: https://github.com/mcleod-ideafix/zxuno_spectrum_core
//
//    ZXUNO Spectrum core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ZXUNO Spectrum core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with the ZXUNO Spectrum core.  If not, see <https://www.gnu.org/licenses/>.
//
//    Any distributed copy of this file must keep this notice intact.
//    Port to support megadrive joystick with ZXDOS+ LX25 Board by AvlixA 
//
//    *** clk should be higher than 50Mhz to be able to generate a 16Mhz Clk
//     ** Use a divisible FRECCLKIN and FRECCLKOUT to get the right value
//     ** Tested on LX25 board test with following output values:
//     **    10.00 Mhz -> OK
//     **    12.50 Mhz -> OK
//     **    14.28 Mhz -> NOK
//     **    16.66 Mhz -> OK
//     **    20.00 Mhz -> OK
//     ** It may give different values with other cores
//
module joydecoder (
//-------------------------------------------
  input wire  clk,
  input wire  joy_data,
  output wire joy_clk,
  output wire joy_load_n,
  input wire reset,
//-----------------------------------------
	input wire hsync_n_s,

	output wire [11:0] joy1_o, // -- MXYZ SACB RLDU  Negative Logic
	output wire [11:0] joy2_o  // -- MXYZ SACB RLDU  Negative Logic
  );
  
  parameter FRECCLKIN = 50;
  parameter FRECCLKOUT = 16;
  
  //Generación del joy_clk
  wire[4:0] clkcnt = (FRECCLKIN / FRECCLKOUT) - 1;
  reg[4:0] reg_clkcnt = 5'b0;
  reg      joy_clk_en = 1'b0;
  
  always @(posedge clk) begin
      if (reg_clkcnt == 5'b0) begin
         reg_clkcnt <= clkcnt;
         joy_clk_en <= 1'b1;
      end
      else begin
         reg_clkcnt <= reg_clkcnt - 5'd1;
         joy_clk_en <= 1'b0;
      end
  end
  
  assign joy_clk = joy_clk_en;

	reg [3:0] hsaux = 4'b0000;
	wire hsref;

	//hs de referencia
	assign hsref = hsync_n_s; 
  
  //Gestion de Joystick
   reg [5:0] joy1  = 6'b111111, joy2  = 6'b111111;   // CB RLDU
   reg joy_renew = 1'b1;
   reg [4:0]joy_count = 5'd0;
   
   assign joy_load_n = joy_renew;

	//Lectura pins de joystick - a través de un shifter
	always @(posedge clk) 
	begin 
	  if (reset) begin
		 hsaux <= 4'b0;
		 joy_renew <= 1'b1;
	  end
	  else if (joy_clk_en) begin
         hsaux <= {hsaux[2:0], hsref};

         // Generador señal joy_load_n
         if (joy_count == 5'd0) begin
            joy_renew <= 1'b0;
         end else begin
            joy_renew <= 1'b1;
         end

         // reseteo al inicio del sincronismo horizontal hs, 
         // con un pequeño desplazamiento ya que la carga debe 
         // hacerse con el hs en valor bajo para las lecturas adicionales
         // En el momento de la carga es cuando se recogen 
         // los valores en el shifter aunque se lean posteriormente
         if (joy_count == 5'd18 || (hsaux[3] && !hsaux[2])) begin
            joy_count <= 5'd0;
         end else begin
            joy_count <= joy_count + 1'b1;
         end      
     end
   end
   
   //Lectura de botones joystick mediante shifter on board
   always @(posedge clk) begin
      if (reset) begin
       joy1 <= 6'b111111;
       joy2 <= 6'b111111;
      end else if (joy_clk_en) begin
         case (joy_count)
            5'd4  : joy1[5]  <= joy_data;   //  1p fire2
            5'd5  : joy1[4]  <= joy_data;   //  1p fire1
            5'd6  : joy1[3]  <= joy_data;   //  1p right
            5'd7  : joy1[2]  <= joy_data;   //  1p left
            5'd8  : joy1[1]  <= joy_data;   //  1p down
            5'd9  : joy1[0]  <= joy_data;   //  1p up
            5'd12  : joy2[5]  <= joy_data;   //  2p fire2
            5'd13  : joy2[4]  <= joy_data;   //  2p fire1
            5'd14 : joy2[3]  <= joy_data;   //  2p right
            5'd15 : joy2[2]  <= joy_data;   //  2p left
            5'd16 : joy2[1]  <= joy_data;   //  2p down
            5'd17 : joy2[0]  <= joy_data;   //  2p up
         endcase              
      end
   end
	
	//Logica joystick megadrive 6 botones o joystick pasivo
	// a partir de los pins leidos previamente
   sega_joystick_6b joystick_md
	(
		.clk( clk ),
      .clk_en( joy_clk_en ),
		.joy_load( ~joy_renew ),
		.reset( reset ),
		.joy1_up_i(joy1[0]),
		.joy1_down_i(joy1[1]),
		.joy1_left_i(joy1[2]),
		.joy1_right_i(joy1[3]),
		.joy1_p6_i(joy1[4]),
		.joy1_p9_i(joy1[5]),
		.joy2_up_i(joy2[0]),
		.joy2_down_i(joy2[1]),
		.joy2_left_i(joy2[2]),
		.joy2_right_i(joy2[3]),
		.joy2_p6_i(joy2[4]),
		.joy2_p9_i(joy2[5]),
		.hsync_n_s(hsref),

		.joy1_o(joy1_o), // -- MXYZ SACB RLDU  Negative Logic
		.joy2_o(joy2_o)  // -- MXYZ SACB RLDU  Negative Logic
	);

endmodule

module sega_joystick_6b
(
	input wire clk,
   input wire clk_en,
	input wire joy_load,
	input wire reset,
	input wire joy1_up_i,
	input wire joy1_down_i,
	input wire joy1_left_i,
	input wire joy1_right_i,
	input wire joy1_p6_i,
	input wire joy1_p9_i,
	input wire joy2_up_i,
	input wire joy2_down_i,
	input wire joy2_left_i,
	input wire joy2_right_i,
	input wire joy2_p6_i,
	input wire joy2_p9_i,
	input wire hsync_n_s,

	output wire [11:0] joy1_o, // -- MXYZ SACB RLDU  Negative Logic
	output wire [11:0] joy2_o  // -- MXYZ SACB RLDU  Negative Logic
);
 
//----   Joystick read with sega 6 button support  ---------------------- 

	//FSM para cada mando
	sega_joystick_fsm fsm_joystick1
	(
		.clk(clk),
      .clk_en( clk_en ),
		.joy_load(joy_load),
		.reset(reset),
		.joy_up_i(joy1_up_i),
		.joy_down_i(joy1_down_i),
		.joy_left_i(joy1_left_i),
		.joy_right_i(joy1_right_i),
		.joy_p6_i(joy1_p6_i),
		.joy_p9_i(joy1_p9_i),
		.vga_hsref(hsync_n_s),
		.joy_o(joy1_o)  // -- MXYZ SACB RLDU  Negative Logic
	);

	sega_joystick_fsm fsm_joystick2
	(
		.clk(clk),
      .clk_en( clk_en ),
		.joy_load(joy_load),
		.reset(reset),
		.joy_up_i(joy2_up_i),
		.joy_down_i(joy2_down_i),
		.joy_left_i(joy2_left_i),
		.joy_right_i(joy2_right_i),
		.joy_p6_i(joy2_p6_i),
		.joy_p9_i(joy2_p9_i),
		.vga_hsref(hsync_n_s),
		.joy_o(joy2_o)  // -- MXYZ SACB RLDU  Negative Logic
	);

endmodule

//FSM para detectar mandos megadrive y pasivos
module sega_joystick_fsm
(
	input wire clk,
   input wire clk_en,   
	input wire joy_load,
	input wire reset,
	input wire joy_up_i,
	input wire joy_down_i,
	input wire joy_left_i,
	input wire joy_right_i,
	input wire joy_p6_i,
	input wire joy_p9_i,
	input wire vga_hsref,

	output wire [11:0] joy_o  // -- MXYZ SACB RLDU  Negative Logic
);

   reg [11:0]joy_s = 12'b111111111111; 	
   reg hs_prev;
	
	wire lrbtzero;
	wire udlrbtzero;

	// Symbolic State declation
	localparam [1:0] s1= 2'd0,
			 s2= 2'd1,
			 //s3= 5'd2,
			 //s4= 5'd3,
			 //s5= 5'd4,
			 //s6= 5'd5,
			 s7= 2'd2,
			 s8= 2'd3;

// S1 - HS=1 - UDLRBC
// S2 - HS=0 - UD00AS
// S3 - HS=1 - UDLRBC =S1
// S4 - HS=0 - UD00AS =S2
// S5 - HS=1 - UDLRBC =S1
// S6 - HS=0 - 0000AS =S2
// S7 - HS=1 - ZXYM--
// S8 - HS=0 - ----AS

	// State declation
	reg [1:0] st_reg = s1, st_next;

	// Next State asign
	always @(posedge clk) 
	begin
	  if (reset) begin
	    st_reg <= s1;
	  end
	  else if ( clk_en ) begin
		 st_reg <= st_next;
	  end
	end
	
   reg joy_load_pre;
  
	// Next State logic joystick 1
	//always @(vga_hsref or udlrbtzero or lrbtzero)
	// el hs de referencia válido es el del hs_prev, que es cuando se hizo la carga del shifter.
	always @(posedge clk) 
	begin
     if ( clk_en ) begin
        joy_load_pre <= joy_load;
        if (!joy_load_pre && joy_load) begin //State changes when joy_load posedge
           hs_prev <= vga_hsref; // Use hsref value always on previous joyload
           
           case (st_reg)
             s1: if (hs_prev) begin //If high continue in state s1
                    st_next <= s1;
                 end
                 else begin
                    st_next <= s2;
                 end
             s2: if (hs_prev) begin
                    if (udlrbtzero) begin // Detect S6 - HS=0 - 0000AS - go to S7
                      st_next <= s7;
                    end
                    else begin //No S2/4/6 go to S1, for pasive joystics
                      st_next <= s1;
                    end
                  end
                  else  //If low continue in state s2
                     st_next <= s2;
             s7: if (hs_prev)		// S7 - HS=1 - ZXYM--
                    st_next <= s7;
                 else
                    st_next <= s8;
             s8: if (hs_prev) begin
                    st_next <= s1;
                  end else
                    st_next <= s8;
             default: st_next <= s1;
           endcase
        end
      end
	end 

	// Output logic joystick 1
	always @(posedge clk)
	begin
		if (reset) begin
			joy_s <= 12'b111111111111;
		end else if ( clk_en ) begin
        if (!joy_load_pre && joy_load) begin
            // 1,3 and 5 Cycles
            if (st_reg == s1) begin 
                joy_s[3:0] <= {joy_right_i, joy_left_i, joy_down_i, joy_up_i}; //-- R, L, D, U
                joy_s[5:4] <= {joy_p9_i, joy_p6_i}; //-- C, B
            end
            // Cycle 2,4,6,8
            if ((st_reg == s2 || st_reg == s8 ) 
                && lrbtzero ) begin //Only reads these cycles for MD joystick
                 joy_s[7:6] <= { joy_p9_i , joy_p6_i }; //-- Start, A
            end				
            if (st_reg == s7) begin // Cycle 7
                 joy_s[11:8] <= { joy_right_i, joy_left_i, joy_down_i, joy_up_i }; //-- Mode, X, Y e Z
            end
        end
      end
	end

	assign lrbtzero = !joy_left_i && !joy_right_i; //LR=00 in cycle 2,4,6,8
	assign udlrbtzero = !joy_up_i && !joy_down_i && !joy_left_i && !joy_right_i; //UDLR=0000 in cycle 6
		
	assign joy_o = joy_s;

endmodule

