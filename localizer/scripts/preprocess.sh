
# (c) Coraline Rinn Iordan 07/2017, 10/2017, 10/2019
# call from ./107/fmri as ./scripts/preprocess.sh

afni_proc.py -script AFNIprocess            \
    -out_dir ./processed                    \
    -scr_overwrite                          \
    -dsets ./raw/run??.nii.gz               \
    -tcat_remove_first_trs 6                \
    -mask_dilate 0                          \
    -copy_anat ./anatLocalizer+orig         \
    -anat_has_skull yes                     \
    -volreg_align_e2a                       \
    -volreg_warp_dxyz 3.0                   \
    -blocks tshift align volreg mask        \
    -execute

