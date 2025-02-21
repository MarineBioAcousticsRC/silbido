# silbido

This project implements a tonal contour extractor (detector) designed for dolphin whistles.  It is described in the following publications:

Conant, P., Li, P., Liu, X., Klinck, H., Fleishman, E., Gillespie, D., Nosal, E.-M. and Roch, M. A. (2022). “*Silbido profundo*: An open source package for the use of deep learning to detect odontocete whistles,” J. Acoustical Soc. Am., 152(6), pp. 3800-3808. doi:10.1121/10.0016631.

Li, P., Liu, X., Palmer, K. J., Fleishman, E., Gillespie, D., Nosal, E.-M., Shiu , Y., Klinck, H., Cholewiak, D., Helble, T., and Roch, M. A. (2020). “Learning Deep Models from Synthetic Data for Extracting Dolphin Whistle Contours,” in Intl. Joint Conf. Neural Net. (Glasgow, Scotland, July 19-24), pp. 10. DOI:  10.1109/IJCNN48605.2020.9206992.

M. A. Roch, T.S. Brandes, B. Patel, Y. Barkley, S. Baumann-Pickering, M.S. Soldevilla, “Automated extraction of odontocete whistle contours,” J. Acous. Soc. Am., Vol. 130(4), pp. 2212-2223, 2011. 

The system is designed to extract time-frequency information from tonal signals and has been built with training data and heuristics that are appropriate for the whistles of toothed whales.  In addition, the system provides a tool for annotating whistles manually.  Unlike many bioacousitcs annotation systems, we annotate the time x frequency contour as opposed to a bounding box.  This is done using cubic splines.  A brief movie showing a trivial example of annotating a simple tonal can be found in the documentation directory.

## Obtaining the software
A compiled package is available at the [github site](https://github.com/MarineBioAcousticsRC/silbido).  People interested in using *silbido profundo* should download a release package as opposed to pulling from the repository.  

When pulling directly from the repository, Java and Matlab executable files will need to be compiled.  Instructions on doing this are in the documentation directory, but this requires the availability of build tools such as Java and C++ compilers.  If you do not wish to do this, there is a binary build available for Windows systems that can be simply downloaded.  Other operating systems may choose to download the binary as well.  The compiled Java files are system independent, and you will only need to compile the C++ files for the Matlab executables.  

This software has been tested with MATLAB 2021A/B.  MATLAB toolbox requirements:  Deep Learning, Statistics & Machine Learning, and Signal Processing.  For manual annotations, the Image Processing toolbox is also required.

## Using *silbido*
Documentation for the package is provided in the documentation directory.

## Using the model without *silbido*
The deep-silbido implementation uses a pretrained model that is designed for spectrograms that have a frame advance of 2 ms and duration of 8 ms (*silbido* defaults).  For people interested in using the network without this implementation, the weights are stored in [ONNX](https://onnx.ai/) format in src / matlab / lib / DeepWhistle / Li_et_al_2020_deep_silbido_361x1500.onnx. You will likely need to implement our signal processing chain, either using the original [code](https://bitbucket.org/deepcontext/whistleretrieval) from Li et. al. 2020, or the Matlab implementation in this repository.  See dtDeepWhistle.m for our implementation of the signal processing chain.

