.text
.globl main

main:
    li t0, 0x1000            # Dirección base para resultados
    
    # Test 1: sigmoid(2.0)
    li a0, 0x20              # Entrada
    nop                      # ← Lo reemplazaremos por SIGMOID
    sw a1, 0(t0)             # Guardar resultado
    
    # Test 2: sigmoid(0.0)
    li a0, 0x00
    nop                      # ← SIGMOID
    sw a1, 4(t0)
    
    # Test 3: sigmoid(-2.0)
    li a0, 0xE0
    nop                      # ← SIGMOID
    sw a1, 8(t0)
    
    # Test 4: sigmoid(4.0)
    li a0, 0x40
    nop                      # ← SIGMOID
    sw a1, 12(t0)
    
    # Test 5: sigmoid(-4.0)
    li a0, 0xC0
    nop                      # ← SIGMOID
    sw a1, 16(t0)
    
    # Test 6: TANH (no funcional)
    li a0, 0x10
    nop                      # ← TANH
    sw a2, 20(t0)
    
    # Test 7: EXP (no funcional)
    li a0, 0x10
    nop                      # ← EXP
    sw a3, 24(t0)
    
    # Señal de éxito
    li t1, 0x20000000
    sw zero, 0(t1)
    
loop:
    j loop
