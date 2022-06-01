# Spike Extraction

Pipeline to extract single / multi-unit activity from signals recorded from single tungsten microelectrodes during behavior.

Because we're working with moving animals, there are a lot of movement artefacts in the data. To minimise the influence of these artefacts on the signal quality, we use a decorrelation function developed by [Musial et al. (2002)](https://europepmc.org/article/MED/11897361). The function works on high-pass filtered data and relies upon the idea that motion artefacts should be present on all channels of in an array of electrodes (here, we use arrays of 16 tungsten electrodes, separated by > 1 mm from each other).

When using the decorrelation function to minimise motion artefacts (signal cleaning), it is important to use a short period of time (i.e. several seconds, rather than minutes of recording). This requires that the recorded signal is thus split up into manageable segments (which we call *trial traces*) of a few seconds. Signal cleaning has some strange edge effects and so it's important that these segments are centered on key events such as stimulus presentation. This ensures that the edges of each segment are unlikely to contain neural activity of interest, and that activity in critical time windows is best preserved.

## 1. Get Trial Traces
get_trial_traces.m

An example block, it's original (propriatary) format can be found on [FigShare](https://figshare.com/articles/dataset/Example_TDT_block_containing_original_data_from_perceptual_constancy_project/19948013)

An example file containing chunked neural data, ahead of cleaning can be found [here](https://figshare.com/articles/dataset/Example_of_chunked_neural_data_from_perceptual_constancy_project/19947965)


## 2. Clean Trial Traces
Note that cleaning is performed separately on data recorded from each different array (e.g. left and right auditory cortex). This is because each array is considered to be independent, as it has a separate connection to the TDT system.


An example file can be downloaded from [FigShare](https://figshare.com/articles/dataset/Example_of_cleaned_neural_data_from_perceptual_constancy_project/19947944)

## 3. Event Detection

Sample times can be found on [FigShare](https://figshare.com/articles/dataset/Example_of_spike_times_extracted_from_clean_data_in_perceptual_constancy_project/19947977)


## 4. Spike Sorting in MClust

[MClust](https://github.com/adredish/MClust-Spike-Sorting-Toolbox) is a separate application, designed by the Redish lab; however the version used in this project on perceptual constancy predates the version of MClust available on GitHub, and used a custom loading function ([loadTDT_PerceptualConstancy.m](spike_extraction\MClust_LoadingFcns\loadTDT_PerceptualConstancy.m)) designed specifically for the data format currently used. 

One important consideration is that MClust is designed to work with tetrode data, and so to get single channel data into MClust, we replicate the signal on each channel. The default settings for MCLust are also overriden so that features are only calculated on a single channel. The screenshot below shows MClust on startup, illustrating the functionality:

<img src="../img/MClust_startup_2.png" alt="MClust after loading data from a sample channel">


MClust has a variety of features to manually sort spikes; however most of these are overkill for the signals recorded on single tungsten microelectrodes, where it's very rare to record more than one neuron or multi-unit cluster. The *feature space* can be used to look for clusters, which can then be manually labelled or subject to an algorithm (e.g. KlustaKwik). There are several quality inspection features such as the *waveform shape* and *inter-spike interval (ISI) histogram*. Usually we distinguish a single unit as that with less than 1% of spikes with ISIs below 1 ms. In the example below, you can see a clear multi-unit recording, where many spikes occur below the 1 ms threshold.

<img src="../img/MClust_Sort1.png" alt="MClust tools for analysing spikes"> <br>


A particularly useful tool for noisy data is the *waveform cutter*, which allows you to filter out large amplitude events from around a candidate spike. This is essentially a form of manual template formation, but generally works well to remove noise that doesn't fit the patter of the spike, especially when there is only one unit on the electrode.

<img src="../img/MClust_cutter0.png" alt="The waveform cutter allows for noise removal when there is only one unit on the electrode">


Below is the same unit after some quick cleaning to remove large noisy events... note that clustering approaches will just split the data into multiple parts that include both noise and signal and, at least in my experience, don't do well at sorting single electrode data.

<img src="../img/MClust_Sort2.png" alt="The same unit above, but after using the waveform cutter"> <br>