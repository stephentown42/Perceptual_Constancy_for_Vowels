# Spike Extraction

Pipeline to extract single / multi-unit activity from signals recorded from single tungsten microelectrodes during behavior.

Because we're working with moving animals, there are a lot of movement artefacts in the data. To minimise the influence of these artefacts on the signal quality, we use a decorrelation function developed by [Musial et al. (2002)](https://europepmc.org/article/MED/11897361). The function works on high-pass filtered data and relies upon the idea that motion artefacts should be present on all channels of in an array of electrodes (here, we use arrays of 16 tungsten electrodes, separated by > 1 mm from each other).

When using the decorrelation function to minimise motion artefacts (signal cleaning), it is important to use a short period of time (i.e. several seconds, rather than minutes of recording). This requires that the recorded signal is thus split up into manageable segments (which we call *trial traces*) of a few seconds. Signal cleaning has some strange edge effects and so it's important that these segments are centered on key events such as stimulus presentation. This ensures that the edges of each segment are unlikely to contain neural activity of interest, and that activity in critical time windows is best preserved.

## 1. Get Trial Traces

Use a set of timestamps to sample chunks of neural activity around critical events (stimulus presentation and responses) via [*get_trial_traces.m*](cleanTrialTraces.m)

### Input Data
An example block, it's original (propriatary) format can be found on [FigShare](https://figshare.com/articles/dataset/Example_TDT_block_containing_original_data_from_perceptual_constancy_project/19948013). Blocks contain a variety of stream data, which can be loaded into Matlab using either the OpenDeveloper libraries (used here) or the [TDT toolbox for Matlab](https://www.tdt.com/docs/sdk/offline-data-analysis/offline-data-matlab/overview/) (which didn't exist at the time this project was conducted). Streams include:

| Store | Description |
| ---- | ----------------------------------------------------------------------------------------------------------- |
| BB_2 | Raw electrode data without filtering, 16 chans, recorded from left auditory cortex |
| BB_3 | Raw electrode data without filtering, 16 chans, recorded from right auditory cortex |
| SU_2 | High-pass filtered data for single / multi-unit activity, 16 chans, recorded from left auditory cortex |
| SU_3 | High-pass filtered data for single / multi-unit activity, 16 chans, recorded from right auditory cortex |
| Sens | Downsampled records of IR sensors used in center, left and right response ports |
| Sond | Downsampled records of output to left and right speakers |
| Valv | Downsampled records of output to solenoids for water delivery from center, left and right response ports |

### Rationale

The cartoon below shows how chunks are timed around trials. Operating on the principle that shorter chunks are better for cleaning, we try not to include long periods of activity between a response and the next trial, but we do try to keep all the activity from just before stimulus onset until just after a response is made (as this is when we expect any neural computation to be most relevant)

<img src="../img/get_trial_traces.png" alt="Chunks around critical events in the session">


The image below shows real chunks (grey zones) taken from the sample data availble in the links.

<img src="../img/SU2_trial_trace_example.png" alt="Example chunks from sample data">


### Output data

An example file containing chunked neural data, ahead of cleaning can be found [here](https://figshare.com/articles/dataset/Example_of_chunked_neural_data_from_perceptual_constancy_project/19947965). It contains:

| Variable     | Description |
| ------------ | -------------------------------------------------------------------------------------------------------|
| bdata        | struct containing the original behavioral data used to generate timestamps |
| M            | an *n-by-2* array containing the start and end times of each chunk, where *n* is the number of chunks |
| trial_traces | an *n-by-m* cell array containing the high-pass signal in each of *n* chunks, on each of *m* electrodes* |

 *Note that electrodes in left auditory cortex are numbered 1-16 and electrodes in right auditory cortex are numbered 17-32

<br>

## 2. Clean Trial Traces
Note that cleaning is performed separately on data recorded from each different array (e.g. left and right auditory cortex). This is because each array is considered to be independent, as it has a separate connection to the TDT system.


An example file can be downloaded from [FigShare](https://figshare.com/articles/dataset/Example_of_cleaned_neural_data_from_perceptual_constancy_project/19947944)

## 3. Event Detection

Sample times can be found on [FigShare](https://figshare.com/articles/dataset/Example_of_spike_times_extracted_from_clean_data_in_perceptual_constancy_project/19947977)


## 4. Spike Sorting in MClust

[MClust](https://github.com/adredish/MClust-Spike-Sorting-Toolbox) is a separate application, designed by the Redish lab; however the version (v.3.5)  used in this project on perceptual constancy predates the version of MClust available on GitHub, and used a custom loading function ([loadTDT_PerceptualConstancy.m](spike_extraction\MClust_LoadingFcns\loadTDT_PerceptualConstancy.m)) designed specifically for the data format currently used. Most of the custom functions are listed in "MClust_mods", where some code has been adapted. 

One important consideration is that MClust is designed to work with tetrode data, and so to get single channel data into MClust, we replicate the signal on each channel. The default settings for MCLust are also overriden so that features are only calculated on a single channel. The screenshot below shows MClust on startup, illustrating the functionality:

<img src="../img/MClust_startup_2.png" alt="MClust after loading data from a sample channel">


MClust has a variety of features to manually sort spikes; however most of these are overkill for the signals recorded on single tungsten microelectrodes, where it's very rare to record more than one neuron or multi-unit cluster. The *feature space* can be used to look for clusters, which can then be manually labelled or subject to an algorithm (e.g. KlustaKwik). There are several quality inspection features such as the *waveform shape* and *inter-spike interval (ISI) histogram*. Usually we distinguish a single unit as that with less than 1% of spikes with ISIs below 1 ms. In the example below, you can see a clear multi-unit recording, where many spikes occur below the 1 ms threshold.

<img src="../img/MClust_Sort1.png" alt="MClust tools for analysing spikes"> <br>


A particularly useful tool for noisy data is the *waveform cutter*, which allows you to filter out large amplitude events from around a candidate spike. This is essentially a form of manual template formation, but generally works well to remove noise that doesn't fit the patter of the spike, especially when there is only one unit on the electrode.

<img src="../img/MClust_cutter0.png" alt="The waveform cutter allows for noise removal when there is only one unit on the electrode">


Below is the same unit after some quick cleaning to remove large noisy events... note that clustering approaches will just split the data into multiple parts that include both noise and signal and, at least in my experience, don't do well at sorting single electrode data.

<img src="../img/MClust_Sort2.png" alt="The same unit above, but after using the waveform cutter"> <br>