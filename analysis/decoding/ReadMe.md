# Decoding

## Pattern Classification

The decoder is a simple nearest-centroid classifier that holds template responses for all unique labels (e.g. vowels) built from training data (time-varying firing rates averaged across multiple trials), and assigns an estimated label to held out data (time varying firing rates on single trials) based on euclidean distance. The process is visualized below:

<p align="center">
  <img src="assets/Fig_DecoderOrganization_A_intro.jpg" alt="drawing" width="450"/>
</p>

Template formation and label estimation are performed using leave-out-out cross validation. Although slower, this allows the templates to be built from as many responses as possible; this can be important where units are tested on few trials, or where the number of labels is more than two (e.g. for sound level and fundamental frequency).

## Temporal Optimization

<p align="center">
  <img src="assets/Fig_DecoderOrganization_B_timing.jpg" alt="drawing" width="450"/>
</p>
