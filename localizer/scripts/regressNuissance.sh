
# (c) Coraline Rinn Iordan 07/2017, 10/2017, 10/2019
# call from ./107/fmri as ./scripts/regressNuissance.sh

3dDeconvolve -input ./processed/pb02.SUBJ.r??.volreg+orig.HEAD                   \
    -polort 6                                                                    \
    -mask ./processed/full_mask.SUBJ+orig                                        \
    -nfirst 0                                                                    \
    -num_stimts 6                                                                \
    -stim_file 1 ./processed/dfile_rall.1D'[0]' -stim_base 1 -stim_label 1 roll  \
    -stim_file 2 ./processed/dfile_rall.1D'[1]' -stim_base 2 -stim_label 2 pitch \
    -stim_file 3 ./processed/dfile_rall.1D'[2]' -stim_base 3 -stim_label 3 yaw   \
    -stim_file 4 ./processed/dfile_rall.1D'[3]' -stim_base 4 -stim_label 4 dS    \
    -stim_file 5 ./processed/dfile_rall.1D'[4]' -stim_base 5 -stim_label 5 dL    \
    -stim_file 6 ./processed/dfile_rall.1D'[5]' -stim_base 6 -stim_label 6 dP    \
    -errts ./epiFinal                                                            \
    -nobucket

