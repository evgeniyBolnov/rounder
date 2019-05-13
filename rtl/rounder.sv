module rounder #(
  parameter INPUT_WIDTH  = 54  ,
  parameter OUTPUT_WIDTH = 32  ,
  parameter DEPTH        = 1024,
  parameter COMPLEX      = 1
) (
  input                     clk      ,
  input                     rst      ,
  input  [ INPUT_WIDTH-1:0] avi_data ,
  input                     avi_sop  ,
  input                     avi_eop  ,
  input                     avi_valid,
  output [OUTPUT_WIDTH-1:0] avo_data ,
  output                    avo_sop  ,
  output                    avo_eop  ,
  output                    avo_valid
);

  localparam ADDR_SIZE    = $clog2(DEPTH)                            ;
  localparam ACTUAL_WIDTH = (COMPLEX) ? INPUT_WIDTH / 2 : INPUT_WIDTH;
  localparam IN_SIZE      = $clog2(ACTUAL_WIDTH)                     ;


  enum logic[2:0]{
    IDLE,
    FIND_MAX,
    FIND_BIT,
    OUT
  } state;

  logic avi_eop_dl;

  logic [INPUT_WIDTH-1:0] ram[DEPTH-1:0];

  logic [ADDR_SIZE:0] cnt_wr, cnt_rd;

  logic [OUTPUT_WIDTH-1:0] avo_data_rg ;
  logic                    avo_sop_rg  ;
  logic                    avo_eop_rg  ;
  logic                    avo_valid_rg;

  logic [ACTUAL_WIDTH-1:0] max      ;
  logic [     IN_SIZE-1:0] msb      ;
  logic [   ADDR_SIZE-1:0] cnt_rd_sl;
  logic [ACTUAL_WIDTH-1:0] abs_val  ;

  int i;

  assign cnt_rd_sl = cnt_rd[ADDR_SIZE-1:0];

  assign avo_data = avo_data_rg ,
    avo_sop   = avo_sop_rg  ,
    avo_eop   = avo_eop_rg  ,
    avo_valid = avo_valid_rg;

  // Запись входного потока в память
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      cnt_wr <= '0;
    else
      if (avi_valid) begin
        ram[cnt_wr] <= avi_data;
        cnt_wr      <= cnt_wr + 1'b1;
      end
  end

generate 

    if (COMPLEX) begin
      logic [ACTUAL_WIDTH-1:0] abs_re, abs_im;

      assign abs_val = (abs_re > abs_im) ? abs_re : abs_im;

      always_ff @(posedge clk or posedge rst)
        if (rst) begin
          abs_re <= '0;
          abs_im <= '0;
        end
        else begin
          abs_re <= (avi_data[ACTUAL_WIDTH*2-1]) ? -avi_data[ACTUAL_WIDTH +: ACTUAL_WIDTH]: avi_data[ACTUAL_WIDTH +: ACTUAL_WIDTH];
          abs_im <= (avi_data[ACTUAL_WIDTH-1])   ? -avi_data[           0 +: ACTUAL_WIDTH]: avi_data[           0 +: ACTUAL_WIDTH];
        end

    end
    else begin

      always_ff @(posedge clk or posedge rst)
        if (rst)
          abs_val <= '0;
        else
          abs_val <= (avi_data[ACTUAL_WIDTH-1]) ? -avi_data : avi_data;

    end

endgenerate

  // Выходное "обрезание"
  always_ff @(posedge clk)
    if (state == OUT && cnt_rd < DEPTH)
      avo_data_rg <= ram[cnt_rd_sl][msb+1'b1 -: OUTPUT_WIDTH];

  // Поиск значащего разряда TODO: подумать над улучшением
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      msb <= OUTPUT_WIDTH;
    else
      if (state == FIND_BIT)
        for (i = OUTPUT_WIDTH; i < ACTUAL_WIDTH; i = i + 1)
          if (max[i])
            msb <= i;
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE :
          if (avi_sop) state <= FIND_MAX;
        FIND_MAX :
          if (avi_eop_dl) state <= FIND_BIT;
        FIND_BIT :
          state <= OUT;
        OUT :
          if (avo_eop) state <= IDLE;
        default :
          state <= IDLE;
      endcase
    end
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      cnt_rd       <= '0;
      avo_sop_rg   <= 0;
      avo_eop_rg   <= 0;
      avo_valid_rg <= 0;
      max          <= '0;
    end else begin
      case (state)
        IDLE : begin
          cnt_rd       <= '0;
          avo_sop_rg   <= 0;
          avo_eop_rg   <= 0;
          avo_valid_rg <= 0;
          max          <= '0;
        end
        FIND_MAX : begin
          cnt_rd <= '0;
          if (abs_val > max)
            max <= abs_val;
        end
        FIND_BIT : begin
          max    <= '0;
          cnt_rd <= '0;
        end
        OUT : begin
          max    <= '0;
          cnt_rd <= cnt_rd + 1'b1;
          if (cnt_rd == 0) begin
            avo_sop_rg   <= 1'b1;
            avo_valid_rg <= 1'b1;
            avo_eop_rg   <= 1'b0;
          end
          else
            avo_sop_rg <= 1'b0;
          if (cnt_rd == DEPTH-1)
            avo_eop_rg <= 1'b1;
          if (cnt_rd == DEPTH) begin
            avo_eop_rg   <= 1'b0;
            avo_valid_rg <= 1'b0;
          end
        end
        default :
          ;
      endcase
    end
  end

  delay #(1,2) i_delay (
    .clk   (clk       ),
    .rst   (rst       ),
    .data_i(avi_eop   ),
    .data_o(avi_eop_dl)
  );

endmodule
