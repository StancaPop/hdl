// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2018 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module axi_pulse_gen_tb ();

  // internal registers

  reg                     clk = 1'b0;
  reg                     rstn = 1'b1;

  // clocks

  always #1 clk = ~clk;

  initial begin

  #100;  
  rstn = 1'b0;
  #300;
  rstn = 1'b1;
  #4000;
  $finish;
  end

  axi_pulse_gen #(
    .ASYNC_CLK_EN(1'b0),
    .N_PULSES (2),
    .PULSE_0_EXT_SYNC (0),
    .PULSE_0_WIDTH (2),
    .PULSE_1_WIDTH (4),
    .PULSE_2_WIDTH (5),
    .PULSE_3_WIDTH (5),
    .PULSE_0_PERIOD (8),
    .PULSE_1_PERIOD (8),
    .PULSE_2_PERIOD (10),
    .PULSE_3_PERIOD (10),
    .PULSE_1_OFFSET (6),
    .PULSE_2_OFFSET (8),
    .PULSE_3_OFFSET (6))
  i_pulse_gen (

    .s_axi_aclk (clk),
    .s_axi_aresetn (rstn),
    .s_axi_awvalid (0),
    .s_axi_awaddr (0),
    .s_axi_awprot (),
    .s_axi_awready (),
    .s_axi_wvalid (0),
    .s_axi_wdata (0),
    .s_axi_wstrb (0),
    .s_axi_wready (),
    .s_axi_bvalid (),
    .s_axi_bresp (),
    .s_axi_bready (0),
    .s_axi_arvalid (0),
    .s_axi_araddr (0),
    .s_axi_arprot (0),
    .s_axi_arready (),
    .s_axi_rvalid (),
    .s_axi_rresp (),
    .s_axi_rdata (),
    .s_axi_rready (0),
    .ext_clk (clk),
    .pulse_0 (),
    .pulse_1 (),
    .pulse_2 (),
    .pulse_3 ());

endmodule

// ***************************************************************************
// ***************************************************************************
