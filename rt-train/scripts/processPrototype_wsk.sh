
# (c) Coraline Rinn Iordan 07/2017, 10/2017, 10/2019
# Process prototype without skull stripping

# $1: PARAMS.NIFTIDIR
# $2: PARAMS.PROTOTYPE.NIFTIFILE
# $3: PARAMS.TEMPLATEDIR
# $4: PARAMS.CURRENTANAT

/opt/AFNI/5-23-17-openmp/afni_proc.py -script AFNIprocess \
    -out_dir "$1"/PrototypeProcessed \
    -scr_overwrite \
    -dsets "$1"/"$2"+orig \
    -tcat_remove_first_trs 6 \
    -mask_dilate 0 \
    -copy_anat "$3"/"$4"+orig \
    -anat_has_skull yes \
    -volreg_align_e2a \
    -volreg_warp_dxyz 3.0 \
    -blocks tshift align volreg mask \
    -execute
