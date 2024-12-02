
Behavioral data, fMRI metadata, and experiment code accompanying:

Coraline Rinn Iordan, Victoria J.H. Ritvo, Kenneth A. Norman, Nicholas B. Turk-Browne, Jonathan D. Cohen. Sculpting new visual categories into the human brain. Proceedings of the National Academy of Sciences (in press).

Abstract:

Learning requires changing the brain. This typically occurs through experience, study, or instruction. We report a proof-of-concept for a new way for humans to acquire visual knowledge by directly sculpting activity patterns in the human brain that mirror those expected to arise through learning. We used a non-invasive technique (closed-loop real-time functional magnetic resonance imaging neurofeedback) to create new categories of visual objects in the brain, without the participants’ explicit awareness. After neural sculpting, participants exhibited behavioral and neural biases for the sculpted, but not for the control categories. The ability to sculpt new perceptual distinctions in the human brain offers a new paradigm for human fMRI research that allows for non-invasive, causal testing of the link between neural representations and behavior. As such, beyond its current application to perception, our work potentially has broad relevance to other domains of cognition such as decision-making, memory, and motor control.

Brief Description of Methods:

Ten healthy adults participated in a 10-day fMRI neurofeedback experiment designed to provide a proof of concept that new visual categories can be induced in perception via neurofeedback manipulation of neural patterns of activity in the human brain. Stimuli comprised complex visual shapes parametrically defined by varying two of seven radial frequency components (RFCs). The components were added together and the resulting wave was wrapped around a circle to obtain a closed contour which was then filled in to create a shape. First, participants underwent a 2AFC behavioral pre-test on Day 1 for six fixed, equally spaced radial dimensions in the shape space to establish a baseline for their categorical perception of the shape stimulus space. Second, participants were scanned on two consecutive days (2-3) while viewing shapes spanning the stimulus space. The data from the localizer scans was used to generate target neurofeedback ROIs for each participant and to train Gaussian models of the neural representation of the shape space in these ROIs. Then, a random split of the stimulus space into two separate, arbitrary categories along one of the six radial dimensions from Day 1 was performed for each subject, unbeknownst to them. Subsequently, participants underwent 5-6 real-time fMRI neurofeedback training sessions on separate days (4-8 or 4-9), whose goal was to scuplt neural categories corresponding to the chosen (trained) categories. During each training trial, participants were shown a shape from one of the target categories that oscillated in parameter space around a fixed point (which resulted in a visual oscillation on the screen), and were told to "Generate a mental state that would make the shape oscillate less." Progress on this task was determined by whether the neural model built during the localizer runs (Days 2-3) estimated that the real-time neural representation of the current shape on the screen had a high log-likelihood ratio for its target category vs. the other target category. After training (Day 9 or 10), participants performed an identical behavioral post-test to Day 1 to establish if their perception of the shape space had changed according to the categories that were neurally sculpted in their brain during training. We found that (1) we were able to successfully create new neural categories for the trained categories, compared to control, untrained categories; (2) participants perceived the trained categories more categorically than control categories, when comparing the behavioral pre- and post-tests; and (3) the magnitude of the neural changes and the behavioral changes were correlated across our cohort.

Participant IDs: 107, 110, 117, 118, 119, 121, 124, 126, 129, 130
Two participants underwent 5 training sessions (107, 117) and eight participants underwent 6 training sessions (110, 118, 119, 121, 124, 126, 129, 130)

Study structure:
Day 1		behavioral pre-test (2AFC)
Days 2-3	2 fMRI localizer scans for generating neurofeedback ROIs and shape space models
Days 4-9	6 real-time fMRI neurofeedback training sessions (1-7 runs per day) (Days 4-8 for participants 107 & 117)
Day 10          behavioral post-test (2AFC) (Day 9 for participants 107 & 117)

Directory structure:

behavior/experiment	Experiment code	for 2AFC behavioral pre-test and post-test
behavior/data		Behavioral data for 2AFC behavioral pre-test and post-test for each participant
localizer/experiment	Experiment code for stimulus display during fMRI localizer sessions (12--15 scanner runs per participant total)
localizer/scripts	Bash/AFNI scripts for preprocessing fMRI data collected during localizer sessions
localizer/metadata	Metadata collected during localizer scanning sessions
rt-train/experiment	Experiment code for stimulus display and real-time preprocessing & analysis during fMRI neurofeedback training sessions
rt-train/scripts	Bash/AFNI scripts for preprocessing real-time fMRI neurofeedback data
rt-train/metadata	Metadata collected during real-time fMRI neurofeedback training sessions
rt-train/movies		Example movies of real-time fMRI neurofeedback training trials, with and without details about the neural model estimation

Due to in-scanner hardware issues, three participants had to skip one training day each (participant 107: session 2; participant 110: session 1; participant 118: session 1). This is reflected in the inconsistent numbering for training sessions metadata for these participants in rt-train/metadata (e.g., metadata is included for the 6 training sessions of participant 118, which are numbered 2-7, corresponding to the days for which the participant reported to the lab for scanning).

fMRI data for all 78 scanning sessions of the study (localizer and rt-train) is publicly available in BIDS format in the following NIH repository: https://nda.nih.gov/study.html?id=1098

The code in this repository is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0). You should have received a copy of the license along with this work. If not, see <https://creativecommons.org/licenses/by-nc/4.0/>.
