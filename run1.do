

vlib work
vdel -all
vlib work


vlog  no_pipeline.sv
vlog  pipeline_non_forward.sv
vlog  pipeline_with_forward.sv
vlog  top.sv

vsim  -c -voptargs=+acc work.top
add wave -r *
run -all
