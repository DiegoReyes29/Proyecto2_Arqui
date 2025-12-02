//==============================================================================
// t_lut_wrapper.v
// Wrapper para integrar T-LUT con PicoRV32 via interfaz PCPI
// 
// Instrucciones custom implementadas:
//   SIGMOID rd, rs1  (opcode=0x0B, funct3=0x0)
//   TANH    rd, rs1  (opcode=0x0B, funct3=0x1) - preparado para futuro
//   EXP     rd, rs1  (opcode=0x0B, funct3=0x2) - preparado para futuro
//
// Formato entrada:  Q4.4 (8 bits con signo)
// Formato salida:   Q1.7 (8 bits con signo)
//==============================================================================

module t_lut_wrapper (
    input wire clk,
    input wire resetn,
    
    // PCPI Interface (PicoRV32 Co-Processor Interface)
    input  wire        pcpi_valid,      // Instrucción válida
    input  wire [31:0] pcpi_insn,       // Código de instrucción
    input  wire [31:0] pcpi_rs1,        // Operando rs1
    input  wire [31:0] pcpi_rs2,        // Operando rs2 (no usado)
    
    output reg         pcpi_wr,         // Escribir resultado
    output reg  [31:0] pcpi_rd,         // Resultado
    output reg         pcpi_wait,       // Coprocessor ocupado
    output reg         pcpi_ready       // Operación completada
);

    //==========================================================================
    // Decodificación de Instrucción
    //==========================================================================
    
    wire [6:0] opcode = pcpi_insn[6:0];
    wire [2:0] funct3 = pcpi_insn[14:12];
    wire [4:0] rs1_addr = pcpi_insn[19:15];
    wire [4:0] rd_addr  = pcpi_insn[11:7];
    
    // Detectar instrucciones custom T-LUT
    wire is_custom_tlut = (opcode == 7'b0001011);  // custom-0
    
    // Identificar operación específica
    wire is_sigmoid = is_custom_tlut && (funct3 == 3'b000);
    wire is_tanh    = is_custom_tlut && (funct3 == 3'b001);
    wire is_exp     = is_custom_tlut && (funct3 == 3'b010);
    wire is_any_op  = is_sigmoid || is_tanh || is_exp;
    
    // Selección de función (para cuando T-LUT sea reconfigurable)
    reg [1:0] func_sel;
    always @(*) begin
        case (funct3)
            3'b000:  func_sel = 2'b00;  // SIGMOID
            3'b001:  func_sel = 2'b01;  // TANH (futuro)
            3'b010:  func_sel = 2'b10;  // EXP (futuro)
            default: func_sel = 2'b00;
        endcase
    end
    
    //==========================================================================
    // Interfaz con T-LUT
    //==========================================================================
    
    reg  [7:0] tlut_x;           // Entrada a T-LUT (Q4.4)
    wire [7:0] tlut_y;           // Salida de T-LUT (Q1.7)
    reg        tlut_start;
    wire       tlut_valid;       // Señal de T-LUT válida
    wire       tlut_ready;       // T-LUT listo
    
    // Instancia del T-LUT
    t_lut_top u_tlut (
        .clk(clk),
        .rst_n(resetn),          // Reset activo bajo
        .x_in(tlut_x),           // Entrada Q4.4
        .sigmoid_out(tlut_y),    // Salida Q1.7
        .valid_out(tlut_valid)   // Señal de válido
        // .func_sel(func_sel)   // Descomentar cuando T-LUT sea reconfigurable
    );
    
    // Asumimos que T-LUT es combinacional o toma 1 ciclo
    assign tlut_ready = tlut_valid;
    
    //==========================================================================
    // FSM de Control
    //==========================================================================
    
    localparam STATE_IDLE    = 2'b00;
    localparam STATE_COMPUTE = 2'b01;
    localparam STATE_DONE    = 2'b10;
    
    // ✅ CORREGIDO: Solo UNA declaración de state y next_state
    reg [1:0] state, next_state;
     
    // Registro de estado
    always @(posedge clk) begin
        if (!resetn) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Lógica de siguiente estado
    always @(*) begin
        next_state = state;
        
        case (state)
            STATE_IDLE: begin
                if (pcpi_valid && is_any_op) begin
                    next_state = STATE_COMPUTE;
                end
            end
            
            STATE_COMPUTE: begin
                // Esperar a que T-LUT indique que el resultado es válido
                if (tlut_valid) begin
                    next_state = STATE_DONE;
                end
            end
            
            STATE_DONE: begin
                next_state = STATE_IDLE;
            end
            
            default: next_state = STATE_IDLE;
        endcase
    end
    
    // Lógica de salida
    always @(posedge clk) begin
        if (!resetn) begin
            pcpi_wr      <= 1'b0;
            pcpi_rd      <= 32'b0;
            pcpi_wait    <= 1'b0;
            pcpi_ready   <= 1'b0;
            tlut_x       <= 8'b0;
            tlut_start   <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    pcpi_wr      <= 1'b0;
                    pcpi_ready   <= 1'b0;
                    pcpi_wait    <= 1'b0;
                    tlut_start   <= 1'b0;
                    
                    if (pcpi_valid && is_any_op) begin
                        tlut_x       <= pcpi_rs1[7:0];
                        pcpi_wait    <= 1'b1;
                    end
                end
                
                STATE_COMPUTE: begin
                    pcpi_wait    <= 1'b1;
                    // Esperar a tlut_valid
                end
                
                STATE_DONE: begin
                    // Extender signo de 8 bits a 32 bits
                    pcpi_rd      <= {{24{tlut_y[7]}}, tlut_y};
                    pcpi_wr      <= 1'b1;
                    pcpi_ready   <= 1'b1;
                    pcpi_wait    <= 1'b0;
                end
                
                default: begin
                    pcpi_wr    <= 1'b0;
                    pcpi_ready <= 1'b0;
                    pcpi_wait  <= 1'b0;
                end
            endcase
        end
    end

endmodule