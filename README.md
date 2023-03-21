# Sound identity is represented robustly in auditory cortex during perceptual constancy

## Introduction

Data and analysis code for investigation into neural activity in auditory cortex of ferrets during perceptual constancy. The best way to use this repository is to read the paper (available [here](https://www.nature.com/articles/s41467-018-07237-3)) and then look at the scripts for details of specific analyses. 

### Requirements

The majority of data analysis was performed in Matlab (version 2014 or later) but the data was collected using GoFerret 1.0 and Matlab 2013b. For advanced analysis with original data held in TDT file types, you will also need to install [OpenDeveloper](https://www.tdt.com/component/opendeveloper/) (Tucker Davis Technologies).

## Review the data analysis scripts

### Data visualization
* Plot sound spectra (script)
* Plot behavioral performance
* Visualize activity of individual neurons

### Decoding stimulus features and future behavior from neural activity
* Start with the <a href="./decoding_neural_activity/ReadMe.md">ReadMe</a> that introduces the motivation and design of decoders for the current study. 
* Decode sounds presented to listeners from individual neuron activity (Script)
* Predict future choices of listeners from individual neuron activity (Script)
* Decode sounds presented to listeners from activity of neural populations (Script)

### Gaining insights into neural processing from decoding performance and hyperparameters
* Compare hyperparameters that best decode different sound features (Script)
* Compare decoding of neural activity in task engaged and passively listening animals (Script)
* Compare decoding of neural activity in animals with and without behavioral training (Script)


## Advanced Steps

For those users who are interested in replicating or extending the study by collecting new data:

* Generate stimuli
* Run behavioral task using [GoFerret](https://github.com/stephentown42/GoFerret/tree/master/timbre_discrimination)
* Run spike extraction pipeline
