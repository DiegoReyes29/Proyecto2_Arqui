//==============================================================================
// tb_system.v
// Testbench para sistema completo PicoRV32 + T-LUT
//
// Genera clock, reset y monitorea la ejecución
//==============================================================================

`timescale 1ns / 1ps

module tb_system;

    //==========================================================================
    // Parámetros
    //==========================================================================
    
    parameter CLK_PERIOD = 10;  // 100 MHz
    
    //==========================================================================
    // Señales
    //==========================================================================
    
    reg clk;
    reg resetn;
    
    //==========================================================================
    // Instancia del DUT (Device Under Test)
    //==========================================================================
    
    system_top uut (
        .clk(clk),
        .resetn(resetn)
    );
    
    //==========================================================================
    // Generación de Clock
    //==========================================================================
    
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    //==========================================================================
    // Generación de Reset
    //==========================================================================
    
    initial begin
        resetn = 1'b0;
        #(CLK_PERIOD * 5);  // Hold reset for 5 cycles
        resetn = 1'b1;
        $display("Reset released at time %t", $time);
    end
    
    //==========================================================================
    // Timeout de Simulación
    //==========================================================================
    
    initial begin
        // Timeout después de 100,000 ciclos
        #(CLK_PERIOD * 500000);
        $display("TIMEOUT: Simulation exceeded maximum time");
        $finish;
    end
    
    //==========================================================================
    // Monitor de Ejecución
    //==========================================================================
    
    // Monitorear instrucciones custom
    always @(posedge clk) begin
        if (resetn && uut.pcpi_valid) begin
            if (uut.u_tlut_wrapper.is_sigmoid) begin
                $display("[%t] SIGMOID executed: input=0x%h", 
                         $time, uut.pcpi_rs1[7:0]);
            end
            if (uut.u_tlut_wrapper.is_tanh) begin
                $display("[%t] TANH executed (not functional): input=0x%h", 
                         $time, uut.pcpi_rs1[7:0]);
            end
            if (uut.u_tlut_wrapper.is_exp) begin
                $display("[%t] EXP executed (not functional): input=0x%h", 
                         $time, uut.pcpi_rs1[7:0]);
            end
        end
        
        // Monitorear resultados
        if (resetn && uut.pcpi_ready && uut.pcpi_wr) begin
            $display("[%t] T-LUT result: output=0x%h", 
                     $time, uut.pcpi_rd[7:0]);
        end
    end
    
    //==========================================================================
    // Dump de forma de onda
    //==========================================================================
    
    initial begin
        $dumpfile("tb_system.vcd");
        $dumpvars(0, tb_system);
    end
    
    //==========================================================================
    // Información inicial
    //==========================================================================
    
    initial begin
        $display("========================================");
        $display("  PicoRV32 + T-LUT Integration Test");
        $display("========================================");
        $display("Clock period: %0d ns", CLK_PERIOD);
        $display("Loading firmware from: firmware/firmware.hex");
        $display("========================================");
    end

endmodule
