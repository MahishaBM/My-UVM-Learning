`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  rand bit [3:0] a;
  rand bit [3:0]b;
  rand bit [3:0]c;
  rand bit [3:0]d;
rand bit [1:0] sel;
bit [3:0] y;
function new(string path ="transaction");
super.new(path);
endfunction
`uvm_object_utils_begin(transaction)
  `uvm_field_int(a, UVM_DEFAULT)
  `uvm_field_int(b,UVM_DEFAULT)
  `uvm_field_int(c,UVM_DEFAULT)
  `uvm_field_int(d,UVM_DEFAULT)
  `uvm_field_int(y,UVM_DEFAULT)
  `uvm_field_int(sel,UVM_DEFAULT)
`uvm_object_utils_end
endclass

class sequence1 extends uvm_sequence#(transaction);

  `uvm_object_utils(sequence1)
  transaction t;
function new(string path="sequence");
super.new(path);
endfunction
virtual task body();
  t=transaction::type_id::create("t");
  repeat(5) begin
    start_item(t);
  t.randomize();
  `uvm_info("seq1",$sformatf("a:%0d, b:%0d, c:%0d, d:%0d, sel:%0d", t.a,t.b,t.c,t.d,t.sel),UVM_NONE);
    finish_item(t);  
end
endtask
endclass

class driver extends uvm_driver#(transaction);
`uvm_component_utils(driver)
transaction t;
virtual mux_if mif;
  function new(string path ="driver", uvm_component parent);
super.new(path,parent);
endfunction
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
t=transaction::type_id::create("t");
  if(!uvm_config_db#(virtual mux_if)::get(this,"","mif",mif))
`uvm_error("drv","access cannot be made");
endfunction
virtual task run_phase(uvm_phase phase);
forever begin
  //phase.raise_objection(this);  
seq_item_port.get_next_item(t);
mif.a <= t.a;
mif.b <=t.b;
mif.c <= t.c;
mif.d <= t.d;
  mif.sel<=t.sel;
  `uvm_info("drv",$sformatf("a:%0d, b:%0d, c:%0d, d:%0d", t.a,t.b,t.c,t.d),UVM_NONE);
seq_item_port.item_done();
  #10;
  //phase.drop_objection(this);
  
end
endtask
endclass

class monitor extends uvm_monitor;
`uvm_component_utils(monitor)
transaction t;
virtual mux_if mif;
  uvm_analysis_port#(transaction) port;
  function new(string path="monitor",uvm_component parent);
super.new(path,parent);
port=new("port",this);
endfunction
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
t=transaction::type_id::create("t");
  if(!uvm_config_db#(virtual mux_if)::get(this,"","mif",mif))
   `uvm_error("mon", "access cannot be made");
endfunction
virtual task run_phase(uvm_phase phase);
forever begin
#10;
t.a=mif.a;
t.b=mif.b;
t.c=mif.c;
t.d=mif.d;
t.y=mif.y;
  t.sel=mif.sel;
  `uvm_info("mon",$sformatf("a:%0d, b:%0d, c:%0d, d:%0d, y:%0d, sel:%0d", t.a,t.b,t.c,t.d,t.y,t.sel),UVM_NONE);
port.write(t);
end
endtask
endclass

class scoreboard extends uvm_scoreboard;
`uvm_component_utils(scoreboard)

  uvm_analysis_imp#(transaction, scoreboard) rec;
  transaction tr;
function new(string path="scoreboard", uvm_component parent);
super.new(path,parent);
rec=new("rec",this);
endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
tr=transaction::type_id::create("tr");
endfunction
  virtual function void write(input transaction tr);
this.tr= tr;
    `uvm_info("sco",$sformatf("a:%0d, b:%0d, c:%0d, d:%0d, y:%0d, sel:%0d", tr.a,tr.b,tr.c,tr.d, tr.y, tr.sel),UVM_NONE)

if((tr.sel==2'b00 && tr.y==tr.a)||(tr.sel==2'b01 && tr.y==tr.b)||(tr.sel==2'b10 && tr.y==tr.c)||(tr.sel==2'b11 && tr.y==tr.d))
`uvm_info("sco","4:1 mux is successfully implemented", UVM_NONE)
else
`uvm_error("sco", "error as occured in DUT");

endfunction
endclass

class agent extends uvm_agent;
`uvm_component_utils(agent)
driver d;
monitor m;
uvm_sequencer#(transaction) seqr;

function new(string path="agent", uvm_component parent);
super.new(path,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
d=driver::type_id::create("d",this);
m=monitor::type_id::create("m",this);
seqr=uvm_sequencer#(transaction)::type_id::create("seqr",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
  d.seq_item_port.connect(seqr.seq_item_export);
endfunction
endclass

class env extends uvm_env;
`uvm_component_utils(env)
agent a;
scoreboard sc;
function new(string path="env", uvm_component parent);
super.new(path,parent);
endfunction
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
a=agent::type_id::create("a",this);
sc=scoreboard::type_id::create("sc",this);
endfunction
virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
a.m.port.connect(sc.rec);
endfunction
endclass

class test extends uvm_test;
`uvm_component_utils(test)
  env e;
sequence1 seq;
  function new(string path="test", uvm_component parent);
super.new(path,parent);
endfunction
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
e=env::type_id::create("e",this);
seq=sequence1::type_id::create("seq");
endfunction 
virtual task run_phase(uvm_phase phase);
phase.raise_objection(this);
seq.start(e.a.seqr);
#50;
phase.drop_objection(this);
endtask
endclass

module tb;
mux_if mif();
  mux dut(.a(mif.a),.b(mif.b),.c(mif.c),.d(mif.d),.y(mif.y),.sel(mif.sel));
initial begin
uvm_config_db#(virtual mux_if)::set(null,"uvm_test_top.e.a*","mif",mif);
  run_test("test");
end
endmodule

