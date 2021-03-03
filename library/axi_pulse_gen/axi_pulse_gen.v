// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2019 (c) Analog Devices, Inc. All rights reserved.
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

module axi_pulse_gen #(

  parameter       ID = 0,
  parameter [0:0] ASYNC_CLK_EN = 1,
  parameter       N_PULSES = 1,
  parameter       PULSE_0_EXT_SYNC = 0,
  parameter [0:0] EXT_ASYNC_SYNC = 0,
  parameter       PULSE_0_WIDTH = 7,
  parameter       PULSE_1_WIDTH = 7,
  parameter       PULSE_2_WIDTH = 7,
  parameter       PULSE_3_WIDTH = 7,
  parameter       PULSE_0_PERIOD = 10,
  parameter       PULSE_1_PERIOD = 10,
  parameter       PULSE_2_PERIOD = 10,
  parameter       PULSE_3_PERIOD = 10,
  parameter       PULSE_1_OFFSET = 0,
  parameter       PULSE_2_OFFSET = 0,
  parameter       PULSE_3_OFFSET = 0)(

  // axi interface

  input                   s_axi_aclk,
  input                   s_axi_aresetn,
  input                   s_axi_awvalid,
  input       [15:0]      s_axi_awaddr,
  input       [ 2:0]      s_axi_awprot,
  output                  s_axi_awready,
  input                   s_axi_wvalid,
  input       [31:0]      s_axi_wdata,
  input       [ 3:0]      s_axi_wstrb,
  output                  s_axi_wready,
  output                  s_axi_bvalid,
  output      [ 1:0]      s_axi_bresp,
  input                   s_axi_bready,
  input                   s_axi_arvalid,
  input       [15:0]      s_axi_araddr,
  input       [ 2:0]      s_axi_arprot,
  output                  s_axi_arready,
  output                  s_axi_rvalid,
  output      [ 1:0]      s_axi_rresp,
  output      [31:0]      s_axi_rdata,
  input                   s_axi_rready,
  input                   ext_clk,
  input                   external_sync,

  output                  pulse_0,
  output                  pulse_1,
  output                  pulse_2,
  output                  pulse_3);

  // local parameters

  localparam [31:0] CORE_VERSION = {16'h0001,     /* MAJOR */
                                     8'h01,       /* MINOR */
                                     8'h00};      /* PATCH */ // 0.01.0
  localparam [31:0] CORE_MAGIC = 32'h504c5347;    // PLSG

  // internal registers

  reg             sync_0;
  reg             sync_1;
  reg             sync_2;
  reg             sync_3;
  reg             sync_active_1;
  reg             sync_active_2;
  reg             sync_active_3;

  // internal signals

  wire            clk;
  wire            up_clk;
  wire            up_rstn;
  wire            up_rreq_s;
  wire            up_wack_s;
  wire            up_rack_s;
  wire    [13:0]  up_raddr_s;
  wire    [31:0]  up_rdata_s;
  wire            up_wreq_s;
  wire    [13:0]  up_waddr_s;
  wire    [31:0]  up_wdata_s;
  wire   [127:0]  pulse_width_s;
  wire   [127:0]  pulse_period_s;
  wire   [127:0]  pulse_offset_s;
  wire    [31:0]  pulse_counter[0:N_PULSES-1];
  wire            load_config_s;
  wire            pulse_gen_resetn;
  wire            external_sync_s;

  assign up_clk = s_axi_aclk;
  assign up_rstn = s_axi_aresetn;

  axi_pulse_gen_regmap #(
    .ID (ID),
    .ASYNC_CLK_EN (ASYNC_CLK_EN),
    .CORE_MAGIC (CORE_MAGIC),
    .CORE_VERSION (CORE_VERSION),
    .N_PULSES (N_PULSES),
    .PULSE_0_WIDTH (PULSE_0_WIDTH),
    .PULSE_1_WIDTH (PULSE_1_WIDTH),
    .PULSE_2_WIDTH (PULSE_2_WIDTH),
    .PULSE_3_WIDTH (PULSE_3_WIDTH),
    .PULSE_0_PERIOD (PULSE_0_PERIOD),
    .PULSE_1_PERIOD (PULSE_1_PERIOD),
    .PULSE_2_PERIOD (PULSE_2_PERIOD),
    .PULSE_3_PERIOD (PULSE_3_PERIOD),
    .PULSE_1_OFFSET (PULSE_1_OFFSET),
    .PULSE_2_OFFSET (PULSE_2_OFFSET),
    .PULSE_3_OFFSET (PULSE_3_OFFSET))
  i_regmap (
    .ext_clk (ext_clk),
    .clk_out (clk),
    .pulse_gen_resetn (pulse_gen_resetn),
    .pulse_width (pulse_width_s),
    .pulse_period (pulse_period_s),
    .pulse_offset (pulse_offset_s),
    .load_config (load_config_s),
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s),
    .up_rack (up_rack_s));

    util_pulse_gen  #(
      .PULSE_WIDTH (PULSE_0_WIDTH),
      .PULSE_PERIOD (PULSE_0_PERIOD))
    util_pulse_gen_i0(
      .clk (clk),
      .rstn (pulse_gen_resetn),
      .pulse_width (pulse_width_s[31:0]),
      .pulse_period (pulse_period_s[31:0]),
      .load_config (load_config_s),
      .sync (sync_0),
      .pulse (pulse_0),
      .pulse_counter (pulse_counter[0]));

    always @(posedge clk) begin
      if (pulse_gen_resetn == 1'b0) begin
        sync_0 <= 1'b0;
      end else begin
        sync_0 <= PULSE_0_EXT_SYNC == 1 ? external_sync : 1'b0;
      end
    end

  generate

    reg external_sync_m0 = 1'b0;
    reg external_sync_m1 = 1'b0;

    if (EXT_ASYNC_SYNC) begin
      always @(posedge clk) begin
        if (pulse_gen_resetn == 1'b0) begin
          external_sync_m0 <=  1'b0;
          external_sync_m1 <=  1'b0;
        end else begin
          external_sync_m0 <= external_sync;
          external_sync_m1 <= external_sync_m0;
        end
      end
      assign external_sync_s = external_sync_m1;
    end else begin
      assign external_sync_s = external_sync;
    end

    if (N_PULSES >= 2) begin
      util_pulse_gen  #(
        .PULSE_WIDTH (PULSE_1_WIDTH),
        .PULSE_PERIOD (PULSE_1_PERIOD))
      util_pulse_gen_i1(
        .clk (clk),
        .rstn (pulse_gen_resetn),
        .pulse_width (pulse_width_s[63:32]),
        .pulse_period (pulse_period_s[63:32]),
        .load_config (load_config_s),
        .sync (sync_1),
        .pulse (pulse_1),
        .pulse_counter (pulse_counter[1]));

      always @(posedge clk) begin
        if (pulse_gen_resetn == 1'b0) begin
          sync_active_1 <= 1'b0;
          sync_1 <= 1'b0;
        end else begin
          sync_active_1 <= |pulse_offset_s[63:32];
          if (sync_active_1) begin
            sync_1 <= (pulse_counter[0] == pulse_offset_s[63:32]) ? 1'b0 : 1'b1;
          end else begin
            sync_1 <= 1'b0;
          end
        end
      end
    end else begin
      assign pulse_1 = 1'b0;
    end

    if (N_PULSES >= 3) begin
      util_pulse_gen  #(
        .PULSE_WIDTH (PULSE_2_WIDTH),
        .PULSE_PERIOD (PULSE_2_PERIOD))
      util_pulse_gen_i2(
        .clk (clk),
        .rstn (pulse_gen_resetn),
        .pulse_width (pulse_width_s[95:64]),
        .pulse_period (pulse_period_s[95:64]),
        .load_config (load_config_s),
        .sync (sync_2),
        .pulse (pulse_2),
        .pulse_counter (pulse_counter[2]));

      always @(posedge clk) begin
        if (pulse_gen_resetn == 1'b0) begin
          sync_active_2 <= 1'b0;
          sync_2 <= 1'b0;
        end else begin
          sync_active_2 <= |pulse_offset_s[95:64];
          if (sync_active_2) begin
            sync_2 <= (pulse_counter[0] == pulse_offset_s[95:64]) ? 1'b0 : 1'b1;
          end else begin
            sync_2 <= 1'b0;
          end
        end
      end
    end else begin
      assign pulse_2 = 1'b0;
    end

    if (N_PULSES >= 4) begin
      util_pulse_gen  #(
        .PULSE_WIDTH (PULSE_3_WIDTH),
        .PULSE_PERIOD (PULSE_3_PERIOD))
      util_pulse_gen_i3(
        .clk (clk),
        .rstn (pulse_gen_resetn),
        .pulse_width (pulse_width_s[127:96]),
        .pulse_period (pulse_period_s[127:96]),
        .load_config (load_config_s),
        .sync (sync_3),
        .pulse (pulse_3),
        .pulse_counter (pulse_counter[3]));

      always @(posedge clk) begin
        if (pulse_gen_resetn == 1'b0) begin
          sync_active_3 <= 1'b0;
          sync_3 <= 1'b0;
        end else begin
          sync_active_3 <= |pulse_offset_s[127:96];
          if (sync_active_3) begin
            sync_3 <= (pulse_counter[0] == pulse_offset_s[127:96]) ? 1'b0 : 1'b1;
          end else begin
            sync_3 <= 1'b0;
          end
        end
      end
    end else begin
      assign pulse_3 = 1'b0;
    end
  endgenerate

  up_axi #(
    .AXI_ADDRESS_WIDTH(16))
  i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s),
    .up_rack (up_rack_s));

endmodule
