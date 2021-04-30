# Decoding Results

## Sliced vs. All In

For studying perceptual constancy and discrimination of vowels across orthogonal dimensions, there were two ways of framing the decoding analysis: 

* Decode vowel identity across *all* values of the task-irrelevant dimension (e.g. build a decoder on responses to vowels of all sound levels and test performance on the full range of levels)
* Decode vowel identity *at each* value of the task-irrelevant dimension (e.g. slice the data so that decoders are trained on responses to vowels to sounds at 60 dB SPL and test only for that sound level, then repeat for another sound level.)

## Results files
Results from decoding are stored separately for each unit. Where a single unit could be isolated, that took the site name (e.g. F1201_Florence_C01_-2.150mm.mat) while the residual spikes that could not be sorted were stored in a hash cluster that was decoded separately  (e.g. F1201_Florence_C01_-2.150mm_hash.mat). If no single unit activity could be sorted, the results file took the site name.

Results files contain two variables:

* **$_pCorrect** : decoding results in array with size m-by-n-by-nItertions+1, where m is the number of decoding window durations, n is the number of decoding window start times, and nIterations is the number of shuffles of the data used in permuation testing. The first slice of the matrix (e.g. vowel_pCorrect(:,:,1)) is the observed decoding without shuffling. The variable name is determined by the parameter being decoded (e.g. vowel, voicing etc.)

* **opt**: structure containing metadata and decoding options, including the start time and window durations of decoding windows. These are needed to interpret the decoding results. Also included are the values and sample sizes of the decoded labels. 