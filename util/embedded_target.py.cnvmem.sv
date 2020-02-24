`define vstrt 32'h0
`define vsiz 32'h10000
`define vstop (`vstrt+`vsiz)

module cnvmem;

   integer i, j, fd, first, last, words;
   
   reg [7:0] byt, mem[`vstrt:`vstop];
   reg [31:0] mem2[0:'hfff];
   reg [1023:0] cnvmem_mem;
   
   initial
     begin
        if (!$value$plusargs("VLOG=%s", cnvmem_mem))
          $error;
        $readmemh(cnvmem_mem, mem);
        i = `vstrt;
	while ((i < `vstop) && (1'bx === ^mem[i]))
	  i=i+4;
        first = i;
        i = `vstop;
	while ((i >= `vstrt) && (1'bx === ^mem[i]))
	  i=i-4;
        last = (i+4);
        for (i = i+1; i < last; i=i+1)
          mem[i] = 0;
        $display("First = %X, Last = %X", first, last-1);
        for (i = first; i < last; i=i+1)
          if (1'bx === ^mem[i]) mem[i] = 0;
        
        for (i = first; i < last; i=i+4)
          begin
             mem2[(i-first)/4] = {mem[i+3],mem[i+2],mem[i+1],mem[i+0]};
          end
        if (!$value$plusargs("MEM=%s", cnvmem_mem))
          $error;
        words = (last-first)/4;
        fd = $fopen(cnvmem_mem, "w");
        for (i = 0; i < words; i=i+1)
          $fdisplay(fd, "%8x", mem2[i]);
        $fclose(fd);
        if (!$value$plusargs("SV=%s", cnvmem_mem))
          $error;
        fd = $fopen(cnvmem_mem, "w");
        $fdisplay(fd, "// Copyright lowRISC contributors.");
        $fdisplay(fd, "// Licensed under the Apache License, Version 2.0, see LICENSE for details.");
        $fdisplay(fd, "// SPDX-License-Identifier: Apache-2.0");
        $fdisplay(fd, "");
        $fdisplay(fd, "/**");
        $fdisplay(fd, " * Implementation of a Read-Only Memory (ROM) primitive for Xilinx FPGAs");
        $fdisplay(fd, " *");
        $fdisplay(fd, " * This implementation of a ROM primitive is coded as outlined in UG 901 to");
        $fdisplay(fd, " * enable Xilinx Vivado infer Block RAM (BRAM) or LUT RAM from it. No mapping");
        $fdisplay(fd, " * target is forced; depending on the Width, Depth and other factors Vivado");
        $fdisplay(fd, " * chooses a mapping target.");
        $fdisplay(fd, " *");
        $fdisplay(fd, " * It is possible to force the mapping to BRAM or distributed RAM by using the");
        $fdisplay(fd, " * ROM_STYLE directive in an XDC file.");
        $fdisplay(fd, " */");
        $fdisplay(fd, "");
        $fdisplay(fd, "`include \"prim_assert.sv\"");
        $fdisplay(fd, "");
        $fdisplay(fd, "module prim_xilinx_rom #(");
        $fdisplay(fd, "  parameter  int Width     = 32,");
        $fdisplay(fd, "  parameter  int Depth     = 2048, // 8kB default");
        $fdisplay(fd, "  parameter  int Aw        = $clog2(Depth)");
        $fdisplay(fd, ") (");
        $fdisplay(fd, "  input                        clk_i,");
        $fdisplay(fd, "  input        [Aw-1:0]        addr_i,");
        $fdisplay(fd, "  input                        cs_i,");
        $fdisplay(fd, "  output logic [Width-1:0]     dout_o,");
        $fdisplay(fd, "  output logic                 dvalid_o");
        $fdisplay(fd, "");
        $fdisplay(fd, ");");
        $fdisplay(fd, "");
        $fdisplay(fd, "   logic [Width-1:0] mem [0: Depth-1] = {");
        for (i = 0; i < words; i=i+1)
        $fdisplay(fd, "32'h%8x%s /* %d */", mem2[i], i < (words-1) ? "," : "", i[11:0]);
        $fdisplay(fd, "    };");
        $fdisplay(fd, "");
        $fdisplay(fd, "");
        $fdisplay(fd, "  always_ff @(posedge clk_i) begin");
        $fdisplay(fd, "    if (cs_i) begin");
        $fdisplay(fd, "      dout_o <= mem[addr_i];");
        $fdisplay(fd, "    end");
        $fdisplay(fd, "  end");
        $fdisplay(fd, "");
        $fdisplay(fd, "  always_ff @(posedge clk_i) begin");
        $fdisplay(fd, "    dvalid_o <= cs_i;");
        $fdisplay(fd, "  end");
        $fdisplay(fd, "");
        $fdisplay(fd, "");
        $fdisplay(fd, "  ////////////////");
        $fdisplay(fd, "  // ASSERTIONS //");
        $fdisplay(fd, "  ////////////////");
        $fdisplay(fd, "");
        $fdisplay(fd, "  // Control Signals should never be X");
        $fdisplay(fd, "  `ASSERT(noXOnCsI, !$isunknown(cs_i), clk_i, '0)");
        $fdisplay(fd, "");
        $fdisplay(fd, "endmodule");
        $fclose(fd);
     end
   
endmodule // cnvmem
