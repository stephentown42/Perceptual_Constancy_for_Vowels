# Spike Extraction

Pipeline to extract single / multi-unit activity from signals recorded from single tungsten microelectrodes during behavior.

Because we're working with moving animals, there are a lot of movement artefacts in the data. To minimise the influence of these artefacts on the signal quality, we use a decorrelation function developed by [Musial et al. (2002)](https://europepmc.org/article/MED/11897361). The function works on high-pass filtered data and relies upon the idea that motion artefacts should be present on all channels of in an array of electrodes (here, we use arrays of 16 tungsten electrodes, separated by > 1 mm from each other).

When using the decorrelation function to minimise motion artefacts (signal cleaning), it is important to use a short period of time (i.e. several seconds, rather than minutes of recording). This requires that the recorded signal is thus split up into manageable segments (which we call *trial traces*) of a few seconds. Signal cleaning has some strange edge effects and so it's important that these segments are centered on key events such as stimulus presentation. This ensures that the edges of each segment are unlikely to contain neural activity of interest, and that activity in critical time windows is best preserved.

## 1. Get Trial Traces
get_trial_traces.m


## 2. Clean Trial Traces
Note that cleaning is performed separately on data recorded from each different array (e.g. left and right auditory cortex). This is because each array is considered to be independent, as it has a separate connection to the TDT system.


## 3. Event Detection

