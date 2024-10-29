
# (c) Coraline Rinn Iordan 07/2017, 10/2017, 10/2019
# call from ./107/fmri as ./scripts/extractData.sh $roi
# $roi = region to extract, e.g., Greymatter, LO, localizer

3dmaskdump -mask ./$1+orig ./epiFinal+orig > ../analysis/raw/$1.txt

