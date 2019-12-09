# Surrogate Radar Waveform Generator
<!-- TOC -->

- [3.5 GHz Waveform Generation for Testing and Development of ESC Detectors](#35-ghz-waveform-generation-for-testing-and-development-of-esc-detectors)
- [1. Legal Disclaimers](#1-legal-disclaimers)
    - [1.1. Software Disclaimer](#11-software-disclaimer)
    - [1.2. Commercial Disclaimer](#12-commercial-disclaimer)
- [2. Project Summary](#2-project-summary)
    - [2.1. Design Methodology](#21-design-methodology)
        - [2.1.1. Framework](#211-framework)
        - [2.1.2. GUI](#212-gui)
- [3. Development Details](#3-development-details)
- [4. How to run](#4-how-to-run)
    - [4.1. Run in MATLAB](#41-run-in-matlab)
    - [4.2. Run from Deployed executable](#42-run-from-deployed-executable)
        - [4.2.1. Compile from source](#421-compile-from-source)
        - [4.2.2. Precompiled Executable](#422-precompiled-executable)
- [5. Prerequisites:](#5-prerequisites)

<!-- /TOC -->

# 1. Legal Disclaimers
## 1.1. Software Disclaimer
 NIST-developed software is provided by NIST as a public service. 
 You may use, copy and distribute copies of the software in any medium,
 provided that you keep intact this entire notice. You may improve,
 modify and create derivative works of the software or any portion of
 the software, and you may copy and distribute such modifications or
 works. Modified works should carry a notice stating that you changed
 the software and should note the date and nature of any such change.
 Please explicitly acknowledge the National Institute of Standards and
 Technology as the source of the software.
 
 NIST-developed software is expressly provided "AS IS." NIST MAKES NO
 WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR ARISING BY
 OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT
 AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR WARRANTS THAT THE
 OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE, OR
 THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY 
 REPRESENTATIONS REGARDING THE USE OF THE SOFTWARE OR THE RESULTS 
 THEREOF, INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY,
 RELIABILITY, OR USEFULNESS OF THE SOFTWARE.
 
 You are solely responsible for determining the appropriateness of
 using and distributing the software and you assume all risks
 associated with its use, including but not limited to the risks and
 costs of program errors, compliance with applicable laws, damage to 
 or loss of data, programs or equipment, and the unavailability or
 interruption of operation. This software is not intended to be used in
 any situation where a failure could cause risk of injury or damage to
 property. The software developed by NIST employees is not subject to
 copyright protection within the United States.

 See [NIST Software Disclaimer](https://www.nist.gov/disclaimer) for more details.

## 1.2. Commercial Disclaimer
 Certain commercial equipment, instruments, or materials are identified in this paper to foster understanding. Such identification does not imply recommendation or endorsement by the National Institute of Standards and Technology, nor does it imply that the materials or equipment identified are necessarily the best available for the purpose.
 
# 2. Project Summary

Environmental Sensing Capability (ESC) sensors will be used in the 3.5 GHz Citizens Broadband Radio Service (CBRS) to detect and report the presence of federal incumbent radar signals in 100 MHz of spectrum. Unlike traditional radar detection schemes, ESC sensors will not have full knowledge of radar waveform parameters such as pulse repetition, pulse duration and center frequency of the incumbent radar. Furthermore, ESC sensors are expected to detect incumbent radar and identify its operational channel in the presence of interference from CBRS devices and adjacent-band emissions. This paper presents signal processing procedures and a software tool for generating ESC test waveforms. These waveforms cover multiple testing scenarios in which one or more radars operate in the presence of interference signals such as LTE TDD signals and adjacent-band radar emissions. We utilize field-measured radar waveforms acquired by the National Advanced Spectrum and Communications Test Network (NASCTN) in the 3.5 GHz band with a 225 MHz sampling rate. Field-measured waveforms include channel propagation effects such as time-varying multipath fading and pulse dispersion, similar to what an actual ESC sensor will observe. We present the signal processing blocks for decimating the measured waveforms and mixing them with interference signals at specified frequency offsets. Gains are adjusted to achieve a desired signal-to-interference ratio (SIR), defined as the ratio of the peak power of the measured radar waveform to the peak or average power of the interference. In addition, we provide an open-source software tool with a graphical user interface (GUI) to visualize the resulting waveforms and to automate the process of generating the waveforms. The tool can randomize signal parameters such as start time, frequency, SIR. The generated waveforms are saved as 90 second, 25 MHz sampled in-phase/quadrature (IQ) data files, and their parameters are saved in JavaScript Object Notation (JSON) format. The waveforms and their parameters can be used by ESC applicants and developers for training and testing incumbent radar detection algorithms.

For more information about the project see [WInnComm Presentation](docs/3.5_GHz_Waveform_Generation_for_Testing_and_Development_of_ESC_Detectors_WInnComm2017.pdf)

## 2.1. Design Methodology
This project consists of a framework and a GUI, both developed in MATLAB, see the [Development Details](#3-development-details) section for more details.

### 2.1.1. Framework
This project is built off a simple MATLAB framework that:
1. Reads/Write large files in smaller and more manageable segments.
2. Manage the state of the system (eg: time, filter) as to not introduce discontinuity resulting from the segmented read-write.
3. Automate the generation of multiple waveform files, using MATLAB's parallel toolbox for parallelism.

This framework allows for many other tools to be created building on this framework, such as the included decimator.

### 2.1.2. GUI
A GUI was built upon the framework to improve user experience. It can preview segments of the waveform via software spectrum/spectrogram analyzer and time scope  before the generation process. This requires adding the following signal (25 MHz sampling rate) sources:
* 2 two radar one files
* 2 LTE signals
* 1 ABI signal (e.g., radar three file)

However these signals can be turned Of/Off interactively.
After previewing the waveform, the parameters can be loaded to the generation panel and further adjusting the parameters if required. The generation panel allows single file generation with fixed parameters, or multiple file generation with either fixed, intervals, or random parameters. In the multiple file generation the signal sources are still randomized even if the other parameters are fixed.  
* To make use of Power levels/SIR setting and estimation, radar peaks and thier location must be estimated and saved to samefilename_pks.mat files before hand.

* By default, the GUI tool expects an *.xlsx file that contains each *.dat file name (IQ 16-bit integers) for radar files along with a parameter ADCScaleFactor for floating point conversion.

* TDD LTE signals can be generated via MATLAB LTE toolbox or captured from an RF device. In addition, channel effect can be applied in the GUI for the simulated LTE signals.

# 3. Development Details
- Current development using MATLAB 2017b
- The Generation tool can be compiled and deployed. See the section [How to run](#4-how-to-run) for more details

 # 4. How to run
## 4.1. Run in MATLAB

* Add the required libraries to MATLAB path by adding the following folders:
    * \src\dsp\
    * \src\util\
* To use the GUI tool as intended with field-measured waveforms, some pre-processing on waveforms is required, i.e., decimation and radar peak estimation, see examples at \src\tests\

* At the MATLAB command prompt  change to dir \src\app\ and run appdesigner('ESCWaveformGenerator.mlapp')

* Requires the following toolboxes to run all the functionalities:
    * Signal Processing Toolbox
    * 'DSP System Toolbox'
    * 'Communications System Toolbox'
    * 'Parallel Computing Toolbox'
    * 'MATLAB Distributed Computing Server'

Running directly in MATLAB script requires further development to make use of the framework similar to that used in the GUI.

## 4.2. Run from Deployed executable

### 4.2.1. Compile from source 
To generate executable for the GUI tool.

    * Use either mcc see CompileESCGenerator.m, or use MATLAB deploytool.
    * all necessary toolboxes are required during compilation in addition to MATLAB Compiler
    * see [Prerequisites:](#5-prerequisites) for more details

### 4.2.2. Precompiled Executable
    If precompiled executable is needed, please contact us.
    
# 5. Prerequisites:
MATLAB prerequisites for deployment can be found in [Matlab Prerequisites](docs/Matlab_Prerequisites.txt)
