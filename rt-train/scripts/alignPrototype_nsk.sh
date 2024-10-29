
# (c) Coraline Rinn Iordan 07/2017, 10/2017, 10/2019
# Align prototype after skull stripping

# $1 : PARAMS.TEMPLATEDIR
# $2 : PARAMS.LOCALIZERANAT
# $3 : PARAMS.CURRENTANAT
# $4 : PARAMS.LOCALIZERTEMPLATE
# $5 : PARAMS.NIFTIDIR
# $6 : PARAMS.PROTOTYPE.FINALFILE

3dSkullstrip -input "$1"/"$3"+orig -prefix "$1"/"$3"_stripped+orig

\@Align_Centers -base "$1"/"$2"_stripped+orig -dset "$1"/"$3"_stripped+orig -child "$5"/PrototypeProcessed/pb02.SUBJ.r01.volreg+orig
3dvolreg -wtrim -clipit -twopass -zpad 8 -rotcom -verbose -prefix "$1"/"$3"_stripped_shft_aligned+orig -base "$1"/"$2"_stripped+orig -1Dmatrix_save Current_to_Localizer "$1"/"$3"_stripped_shft+orig

3dAllineate -base "$1"/"$2"_stripped+orig -source "$5"/PrototypeProcessed/pb02.SUBJ.r01.volreg_shft+orig -1Dmatrix_apply Current_to_Localizer.aff12.1D -master "$1"/"$4"+orig -prefix "$5"/"$6"+orig -final NN
