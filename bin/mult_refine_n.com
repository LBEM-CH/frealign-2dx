#!/bin/csh -f
#unlimit
limit coredumpsize 0

# set PGI_TERM = trace

set working_directory	= `pwd -L`
set SCRATCH		= `grep scratch_dir mparameters | awk '{print $2}'`
if ( $status || $SCRATCH == "" ) then
  set SCRATCH		= ${working_directory}/scratch
endif
if ( ! -d $SCRATCH ) then
  mkdir $SCRATCH
endif
cd $SCRATCH
echo FREALIGN_refinement_ is starting now `date` at `hostname`... r${4}.log_${1}_${2} >> stderr
set bin_dir		= `grep frealign_bin_dir mparameters_run | awk '{print $2}'`
if ( $status || $bin_dir == "" ) then
  set bin_dir		= `which frealign_v9.exe`
  set bin_dir		= ${bin_dir:h}
endif
#
set start = $3
set data_input	= `grep data_input mparameters_run | awk '{print $2}'`
#echo 'FREALIGN is starting now..' >> ${data_input}_mult_refine_n_r${4}.log_${1}_${2}
set raw_images	= `grep raw_images_ref mparameters_run | awk '{print $2}'`
if ( $raw_images == "" ) set raw_images = `grep raw_images mparameters_run | awk '{print $2}'`
set raw_images	= `echo ${raw_images:r}`
set extension	= `ls $raw_images.* | head -1`
if ( $extension == "" ) then
  set raw_images = ${working_directory}/${raw_images}
  set extension	= `ls $raw_images.* | head -1`
endif
set extension	= `echo ${extension:e}`
set mem_per_cpu = `grep mem_per_cpu mparameters_run | awk '{print $2}'`
if ( $status || $mem_per_cpu == "" ) then
  set mem_per_cpu	= 4096
endif
set DMASK	= `grep focus_mask mparameters_run | awk -F\" '{print $2}'`
if ( $status || `echo $DMASK | awk '{print $1}'` == "" ) then
  set DMASK	= ""
endif
set target	= `grep thresh_refine mparameters_run | awk '{print $2}'`
set pbc		= `grep PBC mparameters_run | awk '{print $2}'`
# set boff	= `grep BOFF mparameters_run | awk '{print $2}'`
set dang	= `grep DANG mparameters_run | awk '{print $2}'`
set itmax	= `grep ITMAX mparameters_run | awk '{print $2}'`
set mode	= `grep MODE mparameters_run | awk '{print $2}'`
set FMAG	= `grep FMAG mparameters_run | awk '{print $2}'`
set FDEF	= `grep FDEF mparameters_run | awk '{print $2}'`
set FASTIG	= `grep FASTIG mparameters_run | awk '{print $2}'`
set FPART	= `grep FPART mparameters_run | awk '{print $2}'`
set DFSTD = `grep DFSTD mparameters_run | awk '{print $2}'`
if ( ${DFSTD} == "" ) then
  set DFSTD = 100.0
endif
set FMATCH	= `grep FMATCH mparameters_run | awk '{print $2}'`
set FBOOST	= `grep FBOOST mparameters_run | awk '{print $2}'`
set rref	= `grep res_high_refinement mparameters_run | awk '{print $2}'`
set rclas	= `grep res_high_class mparameters_run | awk '{print $2}'`
set rlowref	= `grep res_low_refinement mparameters_run | awk '{print $2}'`
set rbf		= `grep RBfactor mparameters_run | awk '{print $2}'`
set sym		= `grep Symmetry mparameters_run | awk '{print $2}'`
set pix		= `grep pix_size mparameters_run | awk '{print $2}'`
set kV		= `grep Voltage mparameters_run | awk '{print $2}'`
set AmpC	= `grep Amp_contrast mparameters_run | awk '{print $2}'`
set ImC		= `grep image_contrast mparameters_run | awk '{print $2}'`
if ( ! $status ) then
  if ( $ImC == "P" ) set AmpC = `echo -$AmpC`
endif
set XSTD	= `grep XSTD mparameters_run | awk '{print $2}'`
set SIGANG  = `grep sigma_angles mparameters_run | awk '{print $2}'`
set SIGSHF  = `grep sigma_shifts mparameters_run | awk '{print $2}'`
set FRAC  = `grep frac_dataset mparameters_run | awk '{print $2}'`
if ( ${FRAC} == "" ) then
  set FRAC = 1.0
endif
set dstep	= `grep dstep mparameters_run | awk '{print $2}'`
set ro		= `grep outer_radius mparameters_run | awk '{print $2}'`
set ri		= `grep inner_radius mparameters_run | awk '{print $2}'`
set dang = `echo $dang $rref $ro | awk '{if ($1+0.0 == 0.0) {print 180*$2/3.1415/$3} else {print $1} }'`
set rlowref = `echo $rlowref $ro | awk '{if ($1+0.0 == 0.0) {print 2.5*$2} else {print $1} }'`
set rlowref = `echo $rlowref | awk '{if ($1+0.0 > 1000.0) {print 1000.0} else {print $1} }'`
set MW		= `grep mol_mass mparameters_run | awk '{print $2}'`
set cs		= `grep Aberration mparameters_run | awk '{print $2}'`
set tx		= `grep beam_tilt_x mparameters_run | awk '{print $2}'`
if ( $status || $tx == "" ) then
  set tx	= 0.0
endif
set ty		= `grep beam_tilt_y mparameters_run | awk '{print $2}'`
if ( $status || $ty == "" ) then
  set ty	= 0.0
endif
set mode	= ${5}
set psi		= ${6}
set theta	= ${7}
set phi		= ${8}
set shx		= ${9}
set shy		= ${10}
#
set form = `${bin_dir}/fheader.exe ${raw_images}.${extension} | grep --binary-files=text Opening | awk '{print $2}'`
set fm = "M"
if ( $form == "SPIDER" ) set fm = "S"
if ( $form == "IMAGIC" ) set fm = "I"
#
set NODE_SCRATCH   = `grep node_scratch mparameters_run | awk '{print $2}'`
# echo "NODE SCRATCH FILE IS: ${NODE_SCRATCH}/${raw_images:t}.${extension}" >> stderr
if ( -e ${NODE_SCRATCH}/${raw_images:t}.${extension} ) then
  set raw_images_file = ${NODE_SCRATCH}/${raw_images:t}.${extension}
else
  echo "File ${NODE_SCRATCH}/${raw_images:t}.${extension} not found at `hostname`. Falling back to using the file at the current working directory." >> stderr
  set raw_images_file = ${raw_images}.${extension}
endif

# sleep 10

set imem = 3
set nx = `${bin_dir}/fheader.exe ${raw_images}.${extension} | grep --binary-files=text NX | awk '{print $4}'`
set mem_big = `echo $nx | awk '{print int(10 * $1^3 * 4 * 66 /1024^3 + 1)/10}'`
if ( `echo $mem_big | awk '{print int(1024 * $1)}'` > $mem_per_cpu ) then
  set imem = 0
endif           

if (${mode} == "") set mode = 1

### check for shift & angle refinement
if (${psi} == "") set psi = 1
if (${theta} == "") set theta = 1
if (${phi} == "") set phi = 1
if (${shx} == "") set shx = 1
if (${shy} == "") set shy = 1

set ifsc = 0
if ( $FBOOST == "T" ) set ifsc = -1

@ prev = $start - 1
#
\rm ${data_input}_${start}_r${4}.par_${1}_${2} >& /dev/null
#
#echo 'FREALIGN is starting now..' >> ${data_input}_mult_refine_n_r${4}.log_${1}_${2}
time ${bin_dir}/frealign_v9.exe << eot >>& ${data_input}_mult_refine_n_r${4}.log_${1}_${2}
${fm},${mode},${FMAG},${FDEF},${FASTIG},${FPART},0,F,F,F,${FMATCH},${ifsc},F,${imem},1	!CFORM,IFLAG,FMAG,FDEF,FASTIG,FPART,IEWALD,FBEAUT,FFILT,FBFACT,FMATCH,IFSC,FDUMP,IMEM,INTERP
${ro},${ri},${pix},${MW},${AmpC},${XSTD},${pbc},0.0,${dang},${itmax},20,${SIGANG},${SIGSHF},${FRAC}	!RO,RI,PSIZE,WGH,XSTD,PBC,BOFF,DANG,ITMAX,IPMAX,SIGANG,SIGSHF,FRAC
${psi},${theta},${phi},${shx},${shy},${DMASK}				!MASK
${1},${2}								!IFIRST,ILAST
${sym}									!ASYM symmetry card (I=icosahedral)
1.0,${dstep},${target},0.0,${cs},${kV},${tx},${ty}			!RELMAG,DSTEP,TARGET,THRESH,CS,AKV,TX,TY
${rref},   ${rlowref},   ${rref}, ${rclas}, ${DFSTD}, ${rbf}		!RREC,RMIN,RMAX,RCLAS,DFSTD,RBFACT
${NODE_SCRATCH}/${raw_images:t}.${extension}
${data_input}_reproject_r${4}.${extension}_${1}_${2}
${working_directory}/${data_input}_${prev}_r${4}.par
${data_input}_${start}_r${4}.par_${1}_${2}
${data_input}_${start}_r${4}.shft_${1}_${2}
-100., 0., 0., 0., 0., 0., 0., 0.					! terminator with RELMAG=0.0
${data_input}_${prev}_r${4}.${extension}
${data_input}_${start}_r${4}_weights
${data_input}_${start}_r${4}_map1.${extension}
${data_input}_${start}_r${4}_map2.${extension}
${data_input}_${start}_r${4}_phasediffs
${data_input}_${start}_r${4}_pointspread
eot
#
echo Job on $HOST finished >> stderr
#
