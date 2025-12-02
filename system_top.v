`default_nettype none
// system_top.v - PicoRV32 + T-LUT por PCPI
module system_top (
    input  wire clk,
    input  wire resetn,
    output wire led_out
);

    // -----------------------------
    // 1) Interfaz de memoria PicoRV32 (dummy ROM/RAM)
    // -----------------------------
    wire         mem_valid;
    wire         mem_instr;
    wire         mem_ready;
    wire [31:0]  mem_addr;
    wire [31:0]  mem_wdata;
    wire [ 3:0]  mem_wstrb;
    wire [31:0]  mem_rdata;

    // -----------------------------
    // 2) Interfaz PCPI
    // -----------------------------
    wire         pcpi_valid;
    wire [31:0]  pcpi_insn;
    wire [31:0]  pcpi_rs1;
    wire [31:0]  pcpi_rs2;
    wire         pcpi_wr;
    wire [31:0]  pcpi_rd;
    wire         pcpi_wait;
    wire         pcpi_ready;

    // -----------------------------
    // 3) Estado CPU
    // -----------------------------
    wire trap;

    // -----------------------------
    // 4) Núcleo PicoRV32
    // -----------------------------
    picorv32 #(
        .ENABLE_COUNTERS        (1),
        .ENABLE_COUNTERS64      (1),
        .ENABLE_REGS_16_31      (1),
        .ENABLE_REGS_DUALPORT   (1),
        .LATCHED_MEM_RDATA      (0),
        .TWO_STAGE_SHIFT        (1),
        .BARREL_SHIFTER         (0),
        .TWO_CYCLE_COMPARE      (0),
        .TWO_CYCLE_ALU          (0),
        .COMPRESSED_ISA         (0),
        .CATCH_MISALIGN         (1),
        .CATCH_ILLINSN          (1),
        .ENABLE_PCPI            (1),
        .ENABLE_MUL             (1),
        .ENABLE_FAST_MUL        (0),
        .ENABLE_DIV             (1),
        .ENABLE_IRQ             (0),
        .ENABLE_IRQ_QREGS       (0),
        .ENABLE_IRQ_TIMER       (0),
        .ENABLE_TRACE           (0),
        .REGS_INIT_ZERO         (0),
        .MASKED_IRQ             (0),
        .LATCHED_IRQ            (-1),
        .PROGADDR_RESET         (32'd0),
        .PROGADDR_IRQ           (32'd16),
        .STACKADDR              (32'd12288)
    ) cpu (
        .clk        (clk),
        .resetn     (resetn),

        // Mem IF
        .mem_valid  (mem_valid),
        .mem_instr  (mem_instr),
        .mem_ready  (mem_ready),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (mem_rdata),

        // PCPI IF
        .pcpi_valid (pcpi_valid),
        .pcpi_insn  (pcpi_insn),
        .pcpi_rs1   (pcpi_rs1),
        .pcpi_rs2   (pcpi_rs2),
        .pcpi_wr    (pcpi_wr),
        .pcpi_rd    (pcpi_rd),
        .pcpi_wait  (pcpi_wait),
        .pcpi_ready (pcpi_ready),

        // Estado
        .trap       (trap),

        // sin IRQ/trace
        .irq        (32'b0),
        .eoi        (32'b0)
    );

    // -----------------------------
    // 5) TLUT wrapper (tal como lo pasaste)
    // -----------------------------
    t_lut_wrapper u_tlut_wrapper (
        .clk        (clk),
        .resetn     (resetn),
        .pcpi_valid (pcpi_valid),
        .pcpi_insn  (pcpi_insn),
        .pcpi_rs1   (pcpi_rs1),
        .pcpi_rs2   (pcpi_rs2),
        .pcpi_wr    (pcpi_wr),
        .pcpi_rd    (pcpi_rd),
        .pcpi_wait  (pcpi_wait),
        .pcpi_ready (pcpi_ready)
    );

    // -----------------------------
    // 6) Memoria mínima: responde "siempre listo" con NOP
    // -----------------------------
    assign mem_ready = 1'b1;
    assign mem_rdata = 32'h00000013; // ADDI x0,x0,0

    // -----------------------------
    // 7) Ancla de lógica a un puerto (evita trimming)
    // -----------------------------
    assign led_out = trap;

endmodule
`default_nettype wire
