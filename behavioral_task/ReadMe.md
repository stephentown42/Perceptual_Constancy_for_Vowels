# Behavioral Task

**GoFerret** 1.0.0 is the user interface used to control stimulus generation and presentation, as well as monitor animal behavior and log task responses. 

The task works by setting / reading values on the Tucker Davis Technologies Open Ex system using Open Developer libaries.

### Tasks:
Task folders are held within the GoFerret main directory and represent the initial branching point to allow testing for different projects through the same system. [**ST_TimbreDiscrimination**](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/tree/main/behavioral_task/GoFerret/ST_TimbreDiscrimination) represents one example for this project; however others will likely be made available in future in other repositories soon.

### Levels:

Much of the code for each level follows the same basic logic in which the program is in one of four states:

* *PrepareStim* : Generating stimuli, assigning and reseting relevant variables for next trial
* *WaitForStart*: Checking the circuit to determine when the subject has initiated a trial by holding at the centre spout for a minimum amount of time
* *WaitForResponse*: Checking the circuit to determine if a response has been made at a peripheral location, or abort trial if too much time has elapsed
* *Timeout*: Waiting for a set period following an error, before allowing the next trial

#### Training levels:


###




* Level 09: Voiceless (whispered) vowels
* 


### Compatibility:
Note that this code was designed for Matlab before the 2014 changes to the graphics system. We've encountered problems since then running version 1.0.0 on versions of Matlab after 2013b, as well as on Windows 10. A revised version (GoFerret 2.0.0) has been implemented for Windows 10 and can run on Matlab 2014 or later, but this was not used for this project - please contact @stephentown42 if you need more recent versions.
