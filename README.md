# custom-asic

This repository contains different and independent projects created using **verilog**, that are combined using the **user_proj_example** file from the caravel project. you can learn more about caravel project [here](https://github.com/efabless/caravel_user_project).

There are 8 differnt folders that can be found here, below is a small discription for each of them. Verilog test bench is also included with each project to verify the working of the module. "vvp" file is also present to see the waveform for each of the module.

## 1. FIFO
This module is to create a **Fifo** inside the project. The Fifo's data size and depth can be adjusted using the parameters, **"DATA_SIZE"** and **"FIFO_SIZE"** respectively.

## 2. Hack_Computer
This module is for the **HACK computer**. Here **CPU**, **data memory** and **instruction memory** are integrated. Different clocks are provided to memory and the CPU to have data integrity. Here modules from **SRAM** are also used.
For more information on the design and working, you can follow the link [here](https://www.nand2tetris.org/).

## 3. RAM_2R2W
This module is to create a RAM inside the project. The RAM have variable data size depth that can be adjusted using the parameters **"DATA_SIZE"** and **"RAM_DEPTH_LOG2"** respectively. It is **2R2W RAM**. Both operations can work parallely but take care of data coherency. Both RW use same clock.

## 4. RISC_V
This module is for the **RISC V CORE**. Here all the core parts like **CPU**, **data memory**, **instruction memory** and **register memory** are integrated. Different clocks are provided to memory and the CPU to have data integrity. Here modules from **SRAM** and **RAM_2R2W** are also used.

##  
