interface fa_if (input logic clk);
  logic a, b, cin;
  logic sum, cout;
  logic valid;           
endinterface


class transaction;
  rand bit a, b, cin;
  bit      sum, cout;     

  function void display(string tag);
    $display("[%0t] %-4s a=%b b=%b cin=%b | sum=%b cout=%b", $time, tag, a, b, cin, sum, cout);
  endfunction
endclass


class generator;
  mailbox #(transaction) gen2drv;
  int unsigned num_random = 20;
  int unsigned total;    
  event done;

  function new(mailbox #(transaction) gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  task run();
    transaction t;

    for (int i = 0; i < 8; i++) begin
      t = new();
      {t.a, t.b, t.cin} = i[2:0];
      gen2drv.put(t);
      total++;
    end

    repeat (num_random) begin
      t = new();
      if (!t.randomize()) $fatal(1, "Randomization failed");
      gen2drv.put(t);
      total++;
    end
    -> done;
  endtask
endclass


class driver;
  virtual fa_if vif;
  mailbox #(transaction) gen2drv;

  function new(virtual fa_if vif, mailbox #(transaction) gen2drv);
    this.vif = vif;
    this.gen2drv = gen2drv;
  endfunction

  task run();
    transaction t;
    vif.valid = 0;
    forever begin
      gen2drv.get(t);
      @(posedge vif.clk);
      vif.a     <= t.a;
      vif.b     <= t.b;
      vif.cin   <= t.cin;
      vif.valid <= 1;
      t.display("DRV");
      @(posedge vif.clk);
      vif.valid <= 0;
    end
  endtask
endclass


class monitor;
  virtual fa_if vif;
  mailbox #(transaction) mon2scb;

  function new(virtual fa_if vif, mailbox #(transaction) mon2scb);
    this.vif = vif;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction t;
    forever begin
      @(negedge vif.clk);        
      if (vif.valid) begin
        t = new();
        t.a = vif.a;  t.b = vif.b;  t.cin = vif.cin;
        t.sum = vif.sum;  t.cout = vif.cout;
        t.display("MON");
        mon2scb.put(t);
      end
    end
  endtask
endclass


class scoreboard;
  mailbox #(transaction) mon2scb;
  int unsigned checked, errors;

  function new(mailbox #(transaction) mon2scb);
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction t;
    bit exp_sum, exp_cout;
    logic [1:0] ref_result;
    forever begin
      mon2scb.get(t);
      ref_result = t.a + t.b + t.cin;  
      exp_sum  = ref_result[0];
      exp_cout = ref_result[1];
      checked++;
      if (t.sum !== exp_sum || t.cout !== exp_cout) begin
        errors++;
        $error("[SCB] MISMATCH a=%b b=%b cin=%b | got sum=%b cout=%b, exp sum=%b cout=%b",
               t.a, t.b, t.cin, t.sum, t.cout, exp_sum, exp_cout);
      end else
        $display("[%0t] SCB  PASS a=%b b=%b cin=%b", $time, t.a, t.b, t.cin);
    end
  endtask
endclass


class environment;
  generator  gen;
  driver     drv;
  monitor    mon;
  scoreboard scb;
  mailbox #(transaction) gen2drv, mon2scb;
  virtual fa_if vif;

  function new(virtual fa_if vif);
    this.vif = vif;
    gen2drv = new();
    mon2scb = new();
    gen = new(gen2drv);
    drv = new(vif, gen2drv);
    mon = new(vif, mon2scb);
    scb = new(mon2scb);
  endfunction

  task run();
    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
    join_none
    wait (gen.total != 0);
    @(gen.done);
    wait (scb.checked == gen.total);  
    #10;
    report();
  endtask

  function void report();
    $display("=========================================");
    $display(" Checked: %0d   Errors: %0d", scb.checked, scb.errors);
    $display(" %s", (scb.errors == 0) ? "TEST PASSED" : "TEST FAILED");
    $display("=========================================");
  endfunction
endclass


program test (fa_if vif);
  environment env;
  initial begin
    env = new(vif);
    env.gen.num_random = 20;
    env.run();
    $finish;
  end
endprogram


module tb_top;
  logic clk = 0;
  always #5 clk = ~clk;

  fa_if intf (clk);

  full_adder dut (
    .a(intf.a), .b(intf.b), .cin(intf.cin),
    .sum(intf.sum), .cout(intf.cout)
  );

  test t (intf);

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
endmodule
