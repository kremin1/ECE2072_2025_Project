transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/ECE2072/Project {C:/ECE2072/Project/components_tb.v}
vlog -vlog01compat -work work +incdir+C:/ECE2072/Project {C:/ECE2072/Project/components.v}

