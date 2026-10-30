// core_top.v - Bomb Jack (Tehkan, 1984) core for Analogue Pocket
// Instantiated by apf_top; uses the APF logical port interface.
//
// papilio/d18c7db Bomb Jack core via MiSTer Arcade-BombJack, bombjack_top.vhd
// instantiated intact. Dual Z80 (T80sed main + audio) + 3x AY-3-8910.
//
// ROM image (0x20000 bytes, loaded via APF data slot 1 at bridge_addr 0x0):
// 16 ROMs in 8K pages demuxed off dn_addr[16:13] (GFX pages in bombjack_top,
// program/audio pages inside BOMB_JACK). 4K ROMs are duplicated to fill their
// page — see pack_rom.py for the page map.
//
// Video: native 15kHz timing, 6 MHz pixel, 256x224 active (vcount 0x110-0x1EF),
// vertical (rotation 90). Syncs are REGENERATED from hblank/vblank with
// hvsync_gen (HS_POS=32, VS_POS=13) exactly as the MiSTer wrapper does — it
// deliberately ignores the core's own VGA_HS/VS.

`default_nettype none

module core_top (

// -- Physical connections ----------------------------------------------------

input  wire        clk_74a,
input  wire        clk_74b,

// Cartridge (unused)
inout  wire [7:0]  cart_tran_bank2,    output wire cart_tran_bank2_dir,
inout  wire [7:0]  cart_tran_bank3,    output wire cart_tran_bank3_dir,
inout  wire [7:0]  cart_tran_bank1,    output wire cart_tran_bank1_dir,
inout  wire [7:4]  cart_tran_bank0,    output wire cart_tran_bank0_dir,
inout  wire        cart_tran_pin30,    output wire cart_tran_pin30_dir,
output wire        cart_pin30_pwroff_reset,
inout  wire        cart_tran_pin31,    output wire cart_tran_pin31_dir,

// IR (unused)
input  wire        port_ir_rx,
output wire        port_ir_tx,
output wire        port_ir_rx_disable,

// Link port (unused)
inout  wire        port_tran_si,       output wire port_tran_si_dir,
inout  wire        port_tran_so,       output wire port_tran_so_dir,
inout  wire        port_tran_sck,      output wire port_tran_sck_dir,
inout  wire        port_tran_sd,       output wire port_tran_sd_dir,

// PSRAM (unused)
output wire [21:16] cram0_a,    inout  wire [15:0] cram0_dq,
input  wire          cram0_wait, output wire        cram0_clk,
output wire          cram0_adv_n, output wire       cram0_cre,
output wire          cram0_ce0_n, output wire       cram0_ce1_n,
output wire          cram0_oe_n,  output wire       cram0_we_n,
output wire          cram0_ub_n,  output wire       cram0_lb_n,

output wire [21:16] cram1_a,    inout  wire [15:0] cram1_dq,
input  wire          cram1_wait, output wire        cram1_clk,
output wire          cram1_adv_n, output wire       cram1_cre,
output wire          cram1_ce0_n, output wire       cram1_ce1_n,
output wire          cram1_oe_n,  output wire       cram1_we_n,
output wire          cram1_ub_n,  output wire       cram1_lb_n,

// SDRAM (unused)
output wire [12:0] dram_a,    output wire [1:0]  dram_ba,
inout  wire [15:0] dram_dq,   output wire [1:0]  dram_dqm,
output wire        dram_clk,  output wire        dram_cke,
output wire        dram_ras_n, output wire       dram_cas_n,
output wire        dram_we_n,

// SRAM (unused)
output wire [16:0] sram_a,    inout  wire [15:0] sram_dq,
output wire        sram_oe_n, output wire        sram_we_n,
output wire        sram_ub_n, output wire        sram_lb_n,

// Misc physical
input  wire        vblank,
output wire        vpll_feed,
output wire        dbg_tx,
input  wire        dbg_rx,
output wire        user1,
input  wire        user2,
inout  wire        aux_sda,
output wire        aux_scl,

// -- Logical connections (to/from apf_top) -----------------------------------

// Video (24-bit RGB + sync, synchronous to video_rgb_clock)
output wire [23:0] video_rgb,
output wire        video_rgb_clock,
output wire        video_rgb_clock_90,
output wire        video_de,
output wire        video_skip,
output wire        video_vs,
output wire        video_hs,

// Audio I2S
output wire        audio_mclk,
input  wire        audio_adc,
output wire        audio_dac,
output wire        audio_lrck,

// APF bridge bus (synchronous to clk_74a)
output wire        bridge_endian_little,
input  wire [31:0] bridge_addr,
input  wire        bridge_rd,
output reg  [31:0] bridge_rd_data,
input  wire        bridge_wr,
input  wire [31:0] bridge_wr_data,

// Controller inputs
input  wire [31:0] cont1_key,
input  wire [31:0] cont2_key,
input  wire [31:0] cont3_key,
input  wire [31:0] cont4_key,
input  wire [31:0] cont1_joy,
input  wire [31:0] cont2_joy,
input  wire [31:0] cont3_joy,
input  wire [31:0] cont4_joy,
input  wire [15:0] cont1_trig,
input  wire [15:0] cont2_trig,
input  wire [15:0] cont3_trig,
input  wire [15:0] cont4_trig

);

// -- Tie off unused physical ports -------------------------------------------
assign port_ir_tx              = 1'b0;
assign port_ir_rx_disable      = 1'b1;

assign cart_tran_bank3         = 8'hZZ;   assign cart_tran_bank3_dir     = 1'b0;
assign cart_tran_bank2         = 8'hZZ;   assign cart_tran_bank2_dir     = 1'b0;
assign cart_tran_bank1         = 8'hZZ;   assign cart_tran_bank1_dir     = 1'b0;
assign cart_tran_bank0         = 4'hF;    assign cart_tran_bank0_dir     = 1'b1;
assign cart_tran_pin30         = 1'b0;    assign cart_tran_pin30_dir     = 1'bZ;
assign cart_pin30_pwroff_reset = 1'b0;
assign cart_tran_pin31         = 1'bZ;    assign cart_tran_pin31_dir     = 1'b0;

assign port_tran_so            = 1'bZ;    assign port_tran_so_dir        = 1'b0;
assign port_tran_si            = 1'bZ;    assign port_tran_si_dir        = 1'b0;
assign port_tran_sck           = 1'bZ;    assign port_tran_sck_dir       = 1'b0;
assign port_tran_sd            = 1'bZ;    assign port_tran_sd_dir        = 1'b0;

assign cram0_a = 6'h0;  assign cram0_dq = 16'hZZZZ; assign cram0_clk = 1'b0;
assign cram0_adv_n = 1'b1; assign cram0_cre = 1'b0;
assign cram0_ce0_n = 1'b1; assign cram0_ce1_n = 1'b1;
assign cram0_oe_n = 1'b1; assign cram0_we_n = 1'b1;
assign cram0_ub_n = 1'b1; assign cram0_lb_n = 1'b1;

assign cram1_a = 6'h0;  assign cram1_dq = 16'hZZZZ; assign cram1_clk = 1'b0;
assign cram1_adv_n = 1'b1; assign cram1_cre = 1'b0;
assign cram1_ce0_n = 1'b1; assign cram1_ce1_n = 1'b1;
assign cram1_oe_n = 1'b1; assign cram1_we_n = 1'b1;
assign cram1_ub_n = 1'b1; assign cram1_lb_n = 1'b1;

assign dram_a = 13'h0; assign dram_ba = 2'h0; assign dram_dq = 16'hZZZZ;
assign dram_dqm = 2'h3; assign dram_clk = 1'b0; assign dram_cke = 1'b0;
assign dram_ras_n = 1'b1; assign dram_cas_n = 1'b1; assign dram_we_n = 1'b1;

assign sram_a = 17'h0; assign sram_dq = 16'hZZZZ;
assign sram_oe_n = 1'b1; assign sram_we_n = 1'b1;
assign sram_ub_n = 1'b1; assign sram_lb_n = 1'b1;

assign vpll_feed = 1'bZ;
assign dbg_tx    = 1'bZ;
assign user1     = 1'bZ;
assign aux_scl   = 1'bZ;

assign bridge_endian_little = 1'b0;  // big-endian

// -- PLL ---------------------------------------------------------------------
// 74.25 MHz in -> 48 MHz (clk_sys / bombjack_top.clk_48M)
//                 6 MHz (clk_vid / pixel clock, native 15kHz timing)
//                 6 MHz 90deg (clk_vid_90 / APF DDR pixel clock)
wire clk_sys;
wire clk_vid;
wire clk_vid_90;
wire pll_locked;
wire pll_locked_s;

mf_pllbase mp1 (
    .refclk   (clk_74a),
    .rst      (1'b0),
    .outclk_0 (clk_sys),
    .outclk_1 (clk_vid),
    .outclk_2 (clk_vid_90),
    .locked   (pll_locked)
);

synch_3 s_pll (pll_locked, pll_locked_s, clk_74a);

// -- APF bridge command handler ----------------------------------------------
wire        reset_n;
wire [31:0] cmd_bridge_rd_data;

wire        status_boot_done  = pll_locked_s;
wire        status_setup_done = rom_loaded_s;
wire        status_running    = 1'b1;

wire        dataslot_requestread;
wire [15:0] dataslot_requestread_id;
wire        dataslot_requestread_ack  = 1'b1;
wire        dataslot_requestread_ok   = 1'b1;

wire        dataslot_requestwrite;
wire [15:0] dataslot_requestwrite_id;
wire [31:0] dataslot_requestwrite_size;
wire        dataslot_requestwrite_ack = 1'b1;
wire        dataslot_requestwrite_ok  = 1'b1;

wire        dataslot_update;
wire [15:0] dataslot_update_id;
wire [31:0] dataslot_update_size;
wire        dataslot_allcomplete;

wire [31:0] rtc_epoch_seconds;
wire [31:0] rtc_date_bcd;
wire [31:0] rtc_time_bcd;
wire        rtc_valid;

wire        savestate_supported   = 1'b0;
wire [31:0] savestate_addr        = 32'h0;
wire [31:0] savestate_size        = 32'h0;
wire [31:0] savestate_maxloadsize = 32'h0;
wire        savestate_start;
wire        savestate_start_ack  = 1'b0;
wire        savestate_start_busy = 1'b0;
wire        savestate_start_ok   = 1'b0;
wire        savestate_start_err  = 1'b0;
wire        savestate_load;
wire        savestate_load_ack  = 1'b0;
wire        savestate_load_busy = 1'b0;
wire        savestate_load_ok   = 1'b0;
wire        savestate_load_err  = 1'b0;
wire        osnotify_inmenu;

reg         target_dataslot_read     = 1'b0;
reg         target_dataslot_write    = 1'b0;
reg         target_dataslot_getfile  = 1'b0;
reg         target_dataslot_openfile = 1'b0;
wire        target_dataslot_ack;
wire        target_dataslot_done;
wire [2:0]  target_dataslot_err;
reg  [15:0] target_dataslot_id         = 16'h0;
reg  [31:0] target_dataslot_slotoffset = 32'h0;
reg  [31:0] target_dataslot_bridgeaddr = 32'h0;
reg  [31:0] target_dataslot_length     = 32'h0;
wire [31:0] target_buffer_param_struct;
wire [31:0] target_buffer_resp_struct;

wire [9:0]  datatable_addr;
wire        datatable_wren;
wire [31:0] datatable_data;
wire [31:0] datatable_q;

core_bridge_cmd icb (
    .clk                       (clk_74a),
    .reset_n                   (reset_n),
    .bridge_endian_little      (bridge_endian_little),
    .bridge_addr               (bridge_addr),
    .bridge_rd                 (bridge_rd),
    .bridge_rd_data            (cmd_bridge_rd_data),
    .bridge_wr                 (bridge_wr),
    .bridge_wr_data            (bridge_wr_data),
    .status_boot_done          (status_boot_done),
    .status_setup_done         (status_setup_done),
    .status_running            (status_running),
    .dataslot_requestread      (dataslot_requestread),
    .dataslot_requestread_id   (dataslot_requestread_id),
    .dataslot_requestread_ack  (dataslot_requestread_ack),
    .dataslot_requestread_ok   (dataslot_requestread_ok),
    .dataslot_requestwrite     (dataslot_requestwrite),
    .dataslot_requestwrite_id  (dataslot_requestwrite_id),
    .dataslot_requestwrite_size(dataslot_requestwrite_size),
    .dataslot_requestwrite_ack (dataslot_requestwrite_ack),
    .dataslot_requestwrite_ok  (dataslot_requestwrite_ok),
    .dataslot_update           (dataslot_update),
    .dataslot_update_id        (dataslot_update_id),
    .dataslot_update_size      (dataslot_update_size),
    .dataslot_allcomplete      (dataslot_allcomplete),
    .rtc_epoch_seconds         (rtc_epoch_seconds),
    .rtc_date_bcd              (rtc_date_bcd),
    .rtc_time_bcd              (rtc_time_bcd),
    .rtc_valid                 (rtc_valid),
    .savestate_supported       (savestate_supported),
    .savestate_addr            (savestate_addr),
    .savestate_size            (savestate_size),
    .savestate_maxloadsize     (savestate_maxloadsize),
    .savestate_start           (savestate_start),
    .savestate_start_ack       (savestate_start_ack),
    .savestate_start_busy      (savestate_start_busy),
    .savestate_start_ok        (savestate_start_ok),
    .savestate_start_err       (savestate_start_err),
    .savestate_load            (savestate_load),
    .savestate_load_ack        (savestate_load_ack),
    .savestate_load_busy       (savestate_load_busy),
    .savestate_load_ok         (savestate_load_ok),
    .savestate_load_err        (savestate_load_err),
    .osnotify_inmenu           (osnotify_inmenu),
    .target_dataslot_read      (target_dataslot_read),
    .target_dataslot_write     (target_dataslot_write),
    .target_dataslot_getfile   (target_dataslot_getfile),
    .target_dataslot_openfile  (target_dataslot_openfile),
    .target_dataslot_ack       (target_dataslot_ack),
    .target_dataslot_done      (target_dataslot_done),
    .target_dataslot_err       (target_dataslot_err),
    .target_dataslot_id        (target_dataslot_id),
    .target_dataslot_slotoffset(target_dataslot_slotoffset),
    .target_dataslot_bridgeaddr(target_dataslot_bridgeaddr),
    .target_dataslot_length    (target_dataslot_length),
    .target_buffer_param_struct(target_buffer_param_struct),
    .target_buffer_resp_struct (target_buffer_resp_struct),
    .datatable_addr            (datatable_addr),
    .datatable_wren            (datatable_wren),
    .datatable_data            (datatable_data),
    .datatable_q               (datatable_q)
);

always @(*) begin
    casex (bridge_addr)
        32'hF8xxxxxx: bridge_rd_data = cmd_bridge_rd_data;
        default:      bridge_rd_data = 32'h0;
    endcase
end

// -- ROM loading via APF bridge -----------------------------------------------
// Image is 0x20000 bytes -> 17-bit dn_addr. bombjack_top + BOMB_JACK demux the
// 8K pages internally off dn_addr[16:13]; we just forward dn_* verbatim.

wire [16:0] dn_addr;
wire [7:0]  dn_data;
wire        dn_wr;
reg         rom_loaded_74 = 1'b0;
wire        rom_loaded;
wire        rom_loaded_s = rom_loaded_74;

synch_3 s_rom_to_sys (rom_loaded_74, rom_loaded, clk_sys);

data_loader #(
    .ADDRESS_MASK_UPPER_4 (4'h0),
    .ADDRESS_SIZE         (16),   // 17-bit dn_addr (covers 0x1FFFF)
    .OUTPUT_WORD_SIZE     (1)
) u_rom_loader (
    .clk_74a              (clk_74a),
    .clk_memory           (clk_sys),
    .bridge_wr            (bridge_wr),
    .bridge_endian_little (bridge_endian_little),
    .bridge_addr          (bridge_addr),
    .bridge_wr_data       (bridge_wr_data),
    .write_en             (dn_wr),
    .write_addr           (dn_addr),
    .write_data           (dn_data)
);

always @(posedge clk_74a) begin
    if (dataslot_allcomplete)
        rom_loaded_74 <= 1'b1;
end

// -- Reset --------------------------------------------------------------------
wire reset_n_sys;
synch_3 s_resetn (reset_n, reset_n_sys, clk_sys);

reg [7:0] reset_ctr = 8'hFF;
wire      game_reset_n = (reset_ctr == 8'h0) && rom_loaded && reset_n_sys;
wire      game_reset = !game_reset_n;

always @(posedge clk_sys) begin
    if (!pll_locked)
        reset_ctr <= 8'hFF;
    else if (reset_ctr != 8'h0)
        reset_ctr <= reset_ctr - 1'd1;
end

// -- Controller mapping ------------------------------------------------------
// cont1_key bit layout (APF standard):
//   [0] dpad_up  [1] dpad_down  [2] dpad_left  [3] dpad_right
//   [4] face_a   [5] face_b     [6] face_x     [7] face_y
//   [14] face_select  [15] face_start
//
// Bomb Jack: 8-way joystick + Jump (single button -> any face button).
wire m_coin   = cont1_key[14] | cont2_key[14];   // SELECT = coin
wire m_start1 = cont1_key[15];                   // START
wire m_start2 = cont2_key[15];                   // START P2

wire m_up     = cont1_key[0] | cont2_key[0];
wire m_down   = cont1_key[1] | cont2_key[1];
wire m_left   = cont1_key[2] | cont2_key[2];
wire m_right  = cont1_key[3] | cont2_key[3];
wire m_jump   = cont1_key[4] | cont1_key[5] | cont1_key[6] | cont1_key[7]
              | cont2_key[4] | cont2_key[5] | cont2_key[6] | cont2_key[7];

// -- Bomb Jack game core (VHDL entity) -----------------------------------------
// DIP presets (factory-style defaults; the entity takes switches as ports):
//   demo sounds on, upright, 3 lives, enemies easy, bird easy, bonus every 30k.
wire [3:0] vid_r, vid_g, vid_b;
wire       vid_hblank, vid_vblank;
wire [7:0] audio_raw;

bombjack_top bombjack_core (
    .clk_48M       (clk_sys),
    .clk_6M        (),
    .reset         (game_reset),

    .p1_start      (m_start1),
    .p1_coin       (m_coin),
    .p1_jump       (m_jump),
    .p1_down       (m_down),
    .p1_up         (m_up),
    .p1_left       (m_left),
    .p1_right      (m_right),

    .p2_start      (m_start2),
    .p2_coin       (1'b0),
    .p2_jump       (m_jump),
    .p2_down       (m_down),
    .p2_up         (m_up),
    .p2_left       (m_left),
    .p2_right      (m_right),

    .SW_DEMOSOUNDS (1'b1),
    .SW_CABINET    (1'b1),
    .SW_LIVES      (2'b00),
    .SW_ENEMIES    (2'b00),
    .SW_BIRDSPEED  (2'b00),
    .SW_BONUS      (3'b010),

    .dn_addr       (dn_addr),
    .dn_data       (dn_data),
    .dn_wr         (dn_wr && rom_loaded == 1'b0),  // accept writes only during load

    .VGA_R         (vid_r),
    .VGA_G         (vid_g),
    .VGA_B         (vid_b),
    .VGA_HS        (),                  // unused: syncs regenerated below
    .VGA_VS        (),
    .O_VBLANK      (vid_vblank),
    .O_HBLANK      (vid_hblank),

    .audio         (audio_raw),

    .pause         (1'b0),

    .hs_address    (16'h0),             // MiSTer hiscore bus: tied off
    .hs_data_out   (),
    .hs_data_in    (8'h0),
    .hs_write      (1'b0),
    .flip_screen   (1'b0)
);

// -- Sync regeneration ---------------------------------------------------------
// The MiSTer wrapper ignores the core's own VGA_HS/VS and rebuilds syncs from
// the blanking signals; do exactly the same (same HS_POS/VS_POS).
reg ce_pix;
reg [2:0] ce_div;
always @(posedge clk_sys) begin
    ce_div <= ce_div + 1'd1;
    ce_pix <= !ce_div;
end

wire vid_hs, vid_vs;
hvsync_gen #(.HS_POS(32), .VS_POS(13)) u_hvsync_gen (
    .clk       (clk_sys),
    .ce_pix    (ce_pix),
    .hblank    (vid_hblank),
    .vblank    (vid_vblank),
    .hs_offset (4'd0),
    .vs_offset (4'd0),
    .hsync_o   (vid_hs),
    .vsync_o   (vid_vs)
);

// -- Video output -------------------------------------------------------------
// bombjack_top outputs 4-4-4 RGB. Expand to 24-bit by replication.
wire [7:0] rgb_r = {vid_r, vid_r};
wire [7:0] rgb_g = {vid_g, vid_g};
wire [7:0] rgb_b = {vid_b, vid_b};

wire [23:0] rgb_out = (vid_hblank | vid_vblank) ? 24'h0 : {rgb_r, rgb_g, rgb_b};

reg [23:0] vid_rgb_r;
reg        vid_hs_r, vid_vs_r, vid_de_r;

always @(posedge clk_vid) begin
    vid_rgb_r <= rgb_out;
    vid_hs_r  <= vid_hs;
    vid_vs_r  <= vid_vs;
    vid_de_r  <= ~(vid_hblank | vid_vblank);
end

assign video_rgb          = vid_rgb_r;
assign video_rgb_clock    = clk_vid;
assign video_rgb_clock_90 = clk_vid_90;
assign video_de           = vid_de_r;
assign video_skip         = 1'b0;
assign video_vs           = vid_vs_r;
assign video_hs           = vid_hs_r;

// -- Audio (8-bit unsigned widened to 16, box-filter decimate to ~47 kHz I2S) --
// bombjack_top drives audio as 8-bit unsigned (MiSTer: AUDIO_L = {audio,audio},
// AUDIO_S = 0). 48 MHz / 1024 = 46.875 kHz.
wire [15:0] audio_l_raw = {audio_raw, audio_raw};
wire [15:0] audio_r_raw = {audio_raw, audio_raw};

reg  [9:0]  aud_div     = 10'd0;
reg  [25:0] aud_accum_l = 26'd0, aud_accum_r = 26'd0;
reg  [15:0] audio_l_s   = 16'd0,  audio_r_s  = 16'd0;

always @(posedge clk_sys) begin
    aud_div <= aud_div + 1'd1;
    if (aud_div == 10'd0) begin
        audio_l_s   <= aud_accum_l[25:10];
        audio_r_s   <= aud_accum_r[25:10];
        aud_accum_l <= {10'd0, audio_l_raw};
        aud_accum_r <= {10'd0, audio_r_raw};
    end else begin
        aud_accum_l <= aud_accum_l + {10'd0, audio_l_raw};
        aud_accum_r <= aud_accum_r + {10'd0, audio_r_raw};
    end
end

sound_i2s #(
    .CHANNEL_WIDTH (16),
    .SIGNED_INPUT  (0)
) u_sound_i2s (
    .clk_74a    (clk_74a),
    .clk_audio  (clk_sys),
    .audio_l    (audio_l_s),
    .audio_r    (audio_r_s),
    .audio_mclk (audio_mclk),
    .audio_dac  (audio_dac),
    .audio_lrck (audio_lrck)
);

endmodule
