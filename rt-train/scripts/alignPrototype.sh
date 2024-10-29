
# (c) Coraline Rinn Iordan 07/2017, 10/2017, 10/2019
# Align prototype

# $1 : PARAMS.TEMPLATEDIR
# $2 : PARAMS.LOCALIZERANAT
# $3 : PARAMS.CURRENTANAT
# $4 : PARAMS.LOCALIZERTEMPLATE
# $5 : PARAMS.NIFTIDIR
# $6 : PARAMS.PROTOTYPE.FINALFILE

\@Align_Centers -base "$1"/"$2"+orig -dset "$1"/"$3"+orig -child "$5"/PrototypeProcessed/pb02.SUBJ.r01.volreg+orig
3dvolreg -wtrim -clipit -twopass -zpad 8 -rotcom -verbose -prefix "$1"/"$3"_shft_aligned+orig -base "$1"/"$2"+orig -1Dmatrix_save Current_to_Localizer "$1"/"$3"_shft+orig

3dAllineate -base "$1"/"$2"+orig -source "$5"/PrototypeProcessed/pb02.SUBJ.r01.volreg_shft+orig -1Dmatrix_apply Current_to_Localizer.aff12.1D -master "$1"/"$4"+orig -prefix "$5"/"$6"+orig -final NN
