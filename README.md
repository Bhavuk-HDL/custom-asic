# custom-asic

This repository contains different and independent projects created using **verilog**.

There are 8 differnt folders that can be found here, below is a small discription for each of them. Verilog test bench is also included with each project to verify the working of the module. "vvp" file is also present to see the waveform for each of the module.

## 1. [FIFO](https://github.com/Bhavuk-HDL/custom-asic/tree/main/Fifo)
This project is to create a **Fifo**. The Fifo's data size and depth can be adjusted using the parameters, **"DATA_SIZE"** and **"FIFO_SIZE"** respectively.

## 2. [SRAM](https://github.com/Bhavuk-HDL/custom-asic/tree/main/SRAM)
This project is to create a **SRAM**. The SRAM have variable data size depth that can be adjusted using the parameters **"DATA_SIZE"** and **"SRAM_DEPTH_LOG2"** respectively. It is **1R1W** SRAM. Both operations can work parallely but take care of data coherency.

## 3. [RAM_2R2W](https://github.com/Bhavuk-HDL/custom-asic/tree/main/RAM_2R2W)
This project is to create a RAM. The RAM have variable data size depth that can be adjusted using the parameters **"DATA_SIZE"** and **"RAM_DEPTH_LOG2"** respectively. It is **2R2W RAM**. Both operations can work parallely but take care of data coherency. Both RW use same clock.

## 4. [SPI](https://github.com/Bhavuk-HDL/custom-asic/tree/main/SPI)
This project is to create the upper level control and the logic of the **SPI** module. Here the parameters of the module are set and also **FIFO** module is attached the to it. FIFO is used to collect the data from user and to save it before forwarding to the SPI. SPI parameters are adjused using, **DATA_BITS**, **ADDR_BITS** and **CLK_RATIO**.

## 5. [UART](https://github.com/Bhavuk-HDL/custom-asic/tree/main/UART)
This project is to create a upper level control and logic of the **UART** module. Here the parameters of the module are set and also **FIFO** module is attached the to it. FIFO is used to collect the data from user and to save it before forwarding to the UART. Similarly, another FIFO is used to save data from UART before forwarding to user. UART parameters are adjusted using **"RATIO_REG_SIZE"** and **"DATA_BITS"**.

## 6. [Hack_Computer](https://github.com/Bhavuk-HDL/custom-asic/tree/main/Hack_Computer)
This project is for the **HACK computer**. Here **CPU**, **data memory** and **instruction memory** are integrated. Different clocks are provided to memory and the CPU to have data integrity. Here modules from **SRAM** are also used.
For more information on the design and working, you can follow the link [here](https://www.nand2tetris.org/).

## 7. [RISC_V](https://github.com/Bhavuk-HDL/custom-asic/tree/main/RISC_V)
This project is for the **RISC V CORE**. Here all the core parts like **CPU**, **data memory**, **instruction memory** and **register memory** are integrated. Different clocks are provided to memory and the CPU to have data integrity. Here modules from **SRAM** and **RAM_2R2W** are also used.
For more information on the design and working, you can follow the link [here](https://www.edx.org/course/building-a-risc-v-cpu-core).

## 8. [Final](https://github.com/Bhavuk-HDL/custom-asic/tree/main/Final)
All the previous projects from 1 to 7 are combined here together to create a single, big module. Here we have 4 main designs namely, **HACK_Computer**, **RISC_V**, **SPI**, and **UART**. Other modules are used to make these four work. Modules are combined using the **user_proj_example** file from the caravel project. 
You can learn more about caravel project [here](https://github.com/efabless/caravel_user_project).
