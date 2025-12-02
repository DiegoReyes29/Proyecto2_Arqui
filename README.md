# PicoRV32 - Proyecto de Procesador RISC-V

Este proyecto implementa un sistema basado en el procesador **PicoRV32** (diseñado por Claire Xenia Wolf / YosysHQ) junto con un programa de prueba que procesa vectores de 1024 elementos en formato de punto fijo Q4.4.

## Créditos

Este proyecto utiliza el núcleo del procesador **PicoRV32** desarrollado por Claire Xenia Wolf:
- Repositorio original: https://github.com/YosysHQ/picorv32
- Licencia: ISC License
- Copyright (C) 2015 Claire Xenia Wolf

El procesador PicoRV32 es una implementación completa de la arquitectura RISC-V RV32I/RV32E, diseñada para ser compacta y sintetizable en FPGAs.

## Descripción del Proyecto

### Componentes principales:

1. **Procesador PicoRV32**: Core RISC-V RV32I configurado con:
   - Multiplicación habilitada (`ENABLE_MUL = 1`)
   - División habilitada (`ENABLE_DIV = 1`)
   - Interrupciones habilitadas (`ENABLE_IRQ = 1`)
   - Dirección de reset: `0x00000000`

2. **Programa de prueba**: Procesa 1024 elementos almacenados en memoria, realizando operaciones matemáticas en formato Q4.4.

### Formato Q4.4

- **4 bits parte entera con signo**: Rango [-6, +6]
- **4 bits fraccionarios**: Resolución 1/16 = 0.0625
- **Total**: 8 bits por valor
- **Rango efectivo**: [-6.0, +6.9375]

### Mapa de Memoria

```bash
0x00000000 - 0x000007FF : Código del programa (.text)
0x00001000 - 0x000013FF : Vector de entrada (1024 bytes)
0x00001400 - 0x000017FF : Vector de salida (1024 bytes)
0x00003000              : Stack pointer inicial
0x20000000              : Dirección de señal de éxito (testbench)
```
## Requisitos

### Para simulación:
- Vivado Simulator

### Para generar firmware - Opción 1 (RARS):
- RARS (RISC-V Assembler and Runtime Simulator)
- Disponible en: https://github.com/TheThirdOne/rars

### Para generar firmware - Opción 2 (Toolchain):
- RISC-V GNU Toolchain: `riscv32-unknown-elf-gcc`
- Python 3.x
- Script `makehex.py` (incluido en repositorio PicoRV32)

## Cómo Ejecutar el Procesador

### Simulación con Vivado:
- Crear proyecto en Vivado
- Agregar archivos: `picorv32.v`, `testbench.v`
- Agregar `firmware.hex` a la carpeta firmware ubicada en la carpeta de simulación de Vivado
- Run Simulation
- Restart
- Run all

### Salida esperada
```bash
TRAP after XXXX clock cycles
ALL TESTS PASSED.
```

## Generación del `firmware.hex`

### Método 1: Usando RARS (Recomendado para Assembly)

#### Paso 1: Configurar RARS
-Abrir RARS
-Ir a Settings → Memory Configuration
-Seleccionar "Compact, Text at Address 0"
-Click en "Apply and Close"
Esto debido a que el procesador inicia la ejecución en `PROGADDR_RESET = 0x00000000`

#### Paso 2: Escribir o cargar el código Assembly

#### Paso 3: Ensamblar en RARS

- File → Open → Seleccionar tu archivo `.asm`
- Presionar F3 o click en Assemble
- Verificar que no hay errores en la consola

#### Paso 4: Exportar a .hex

- File → Dump Memory → Hexadecimal Text
- Guardar como `firmware.hex`

### Método 2: Usando RISC-V Toolchain (Para código en C)

#### Paso 1: Escribir código en C
- Crear código en C (como ejemplo se usará uno llamado hello.c)

#### Paso 2: Compilar a .elf
```bash
riscv32-unknown-elf-gcc -march=rv32imfd -mabi=ilp32d -Os -ffreestanding -nostdlib \
    -o hello.elf start.S hello.c irq.c sieve.c multest.c stats.c print.c \
    -Wl,-Bstatic,-T,riscv.ld,--strip-debug -lgcc
```
##### Archivos necesarios del repositorio PicoRV32 
- `Start.S`- código de inicio
- `riscv.ld`- Linker script (fue modificado para que generará el texto en address 0)
- Otros archivos auxiliares según necesidad

#### Paso 3: Convertir a binario
```bash
riscv32-unknown-elf-objcopy -O binary hello.elf hello.bin
```

#### Paso 4: Generar .hex con makehex.py
```bash
python3 makehex.py hello.bin 32768 > firmware.hex
```

### Parámetros
- `hello.bin` - Archivo binario de entrada
- 32768 - Tamaño en palabras de 32 bits (128 KB = 32768 palabras)
- `firmware.hex` - Archivo de salida
- Nota: El script makehex.py está incluido en el repositorio de PicoRV32 en `/firmware/makehex.py`

## Referencias

- PicoRV32: https://github.com/YosysHQ/picorv32
- RARS Simulator: https://github.com/TheThirdOne/rars
- RISC-V GNU Toolchain: https://github.com/riscv-collab/riscv-gnu-toolchain

## Autor
- Cordero Zuñiga Gerson Adrian
- Loasiga Tellez Keilin Tatiana
- Miranda Gonzalez David Alberto
- Reyes Vargas Luis Diego
- Instituto Tecnológico de Costa Rica Campus San Carlos
- 08/11/2025
