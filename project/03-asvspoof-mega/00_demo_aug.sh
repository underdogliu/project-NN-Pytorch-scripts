#!/bin/bash
######################################################
#__author__ = "Xin Wang"
#__email__ = "wangxin@nii.ac.jp"
#
# Demonstration script
# Please read README first
#
# Usage:
#   $: bash 00_demo.sh MODEL/RUN
#   where MODEL is the name of the model, and RUN is the 
#   index of the training round.
#
# For example:
#   $: bash 00_demo.sh lfcc-lcnn-lstmsum-p2s/01
#
# You may also run this script in background
#   $: bash 00_demo.sh lfcc-lcnn-lstmsum-p2s/01 > log_batch 2>$1 &
#   Then you can quit the terminal ($: exit) and let the job run
#   You will find the results in file log_batch
#
# This script will
#  0. download pre-trained models and pre-generated scores
#     by Xin (if they are not available)
#  1. compute EER on scores generated by Xin 
#     (using the same pre-trained model on NII's server)
#  2. run pre-trained model on ASVspoof2019 LA evalset,
#     calculate EER
#  3. train a new model, run evaluation, and compute EER
#
# Step3 requires 16GB GPU memory for model training
# If it is too much for your GPU, please reduce --batch-size 
# in */*/00_train.sh before running this script
######################################################

RED='\033[0;32m'
NC='\033[0m'

##############
# Configurations
#  environment config file in github repo
#  You may need to load conda environment in this env.sh
ENVFILE=$PWD/../../env.sh

# a wrapper to run EER and min-tDCF, given scores by the model
EVALSCRIPT=$PWD/02_evaluate.py

# script of main.py (used by all the models)
MAINSCRIPT=$PWD/01_main.py
MAINSCRIPT_RAWNET=$PWD/01_main_rawnet.py
# configuration to run the model (shared by all the models)

AUG_TYPE=noise
CONFIGSCRIPT=$PWD/01_config_aug_${AUG_TYPE}.py
CONFIGSCRIPT_RAWNET=$PWD/01_config_rawnet.py

# for convenience, trial length are logged into these binary files
#  They will be automatically generated if not available. 
#  Make them available save the time to scan files
CONVDIR=$PWD/conv

# download link for pre-trained models
#  don't change these
MODELNAME=project-03-asvspoof-mega-pretrained.tar.gz
MODELLINK=https://zenodo.org/record/6456692/files/${MODELNAME}
MD5SUMVAL=ff1ce800fb14b3ed0f5af170925dfbbc
########

#############
# step 0. download files if necessary
if [[ -e "./${MODELNAME}" ]];then
    TMP=`md5sum ${MODELNAME} | awk '{print $1}'`
    if [ ${TMP} != ${MD5SUMVAL} ]; then
	rm ${MODELNAME}
	echo -e "Re-download ${MODELNAME}"
    else
	echo -e "Found ${MODELNAME}"
    fi
fi

if [[ ! -e "./${MODELNAME}" ]];then
    echo -e "${RED}Downloading pre-trained model (~1G)${NC}"
    wget -q --show-progress ${MODELLINK}
fi

if [ -e "./${MODELNAME}" ];then	
    echo -e "${RED}Untar pre-trained models${NC}"
    tar -xzf ${MODELNAME}
else
    echo "Cannot download ${MODELLINK}. Please contact the author"
    exit
fi


if [ ! -e "${CONVDIR}/project-03-asvspoof-mega-conv.tar" ];
then
    cd ${CONVDIR}
    echo "${RED}Downloading some cached files${NC}"
    echo "They are not necessary. But having them will reduce the time to load data for the 1st time"
    wget -q --show-progress https://zenodo.org/record/6456692/files/project-03-asvspoof-mega-conv.tar
    tar -xvf project-03-asvspoof-mega-conv.tar
    cd -
fi

#############
# setup PYTHONPATH and conda
#  this ENVFILE must be accessed inside a folder
mkdir __tmp
cd __tmp
source ${ENVFILE}
cd ..
rm -r __tmp

# go to the model directory
MODEL=$1

if [ -z $MODEL ];
then
    echo -e "\n${RED}Please specify model directory, for example: ${NC}"
    echo -e "$: bash 00_demo.sh lfcc-lcnn-lstmsum-p2s/01 \n"
    exit
else
    if [ ! -d ${MODEL} ]; 
    then
	echo -e "\n${RED}Cannot find ${MODEL} ${NC}"
	exit
    else
	echo -e "\n${RED}Use model ${MODEL}${NC}"
	cd ${MODEL}
	if [[ ${MODEL} == "rawnet2"* ]]; then
	    # rawnet requires a different config
	    cp ${MAINSCRIPT_RAWNET} ./main.py
	    cp ${CONFIGSCRIPT_RAWNET} ./config.py
	    # not copy cached durations files. they are not available
	else
	    cp ${MAINSCRIPT} ./main.py
	    cp ${CONFIGSCRIPT} ./config.py
	    # Copy cached files that logs utterance duration. This saves time
	    # It is also OK to skip this step, and the code will generate them
	    cp ${CONVDIR}/* ./
	fi
    fi
fi

#############
# step 1. EER on scores produced by Xin
echo -e "\n${RED}=======================================================${NC}"
echo -e "${RED}Step1. computing EER on pre-produced scores${NC}"
echo -e "(Scores were produced by pre-trained ${MODEL} on NII's server)" 
LOGFILE=__pretrained/log_output_testset
python ${EVALSCRIPT} ${LOGFILE}

#############
# step 2. run pre-trained model by Xin and compute EER
# echo -e "\n${RED}=======================================================${NC}"
# echo -e "${RED}Step2. run pre-trained ${MODEL} on eval set using your GPU server${NC}"
# echo -e "The job will run in background for ~20 minutes. Please wait."
# echo -e "(Model ${MODEL} was trained on NII's server.)"

# LOGFILE=log_output_testset_pretrained
# python main.py --inference --model-forward-with-file-name --trained-model __pretrained/trained_network.pt > ${LOGFILE} 2>${LOGFILE}_err

# echo -e "\n${RED}Please check the following log files \n\t${LOGFILE}\n\t${LOGFILE}_err${NC}"

# echo -e "\n${RED}This is the result using pre-trained model on your GPU ${NC}"
# python ${EVALSCRIPT} ${LOGFILE}

#############
# step 3. train new model, and run evaluation
echo -e "\n${RED}=======================================================${NC}"
echo -e "${RED}Step3. train a new model ${MODEL} using your GPU server${NC}"
echo -e "Current training recipe requires 16GB GPU memory."
echo -e "If it is too much for your GPU, please reduce --batch-size in */*/00_train.sh before running this step"
echo -e "The job will run in backgroun for a few hours. Please wait."
echo -e "You can also run this script in background. See README of this script"

train using prepared script 
(notice that random seed is different from different RUN)
bash 00_train.sh
echo -e "\n${RED}Please check log_train and log_err{NC}"

echo -e "\n${RED}Evaluating the trained model ${NC}"
echo -e "The job will run in backgroun for ~20 minutes. Please wait."

LOGFILE=log_output_testset_aug_${AUG_TYPE}
python main.py --inference --model-forward-with-file-name > ${LOGFILE} 2>${LOGFILE}_err

echo -e "\n${RED}Please check the following log files \n\t${LOGFILE}\n\t${LOGFILE}_err${NC}"

echo -e "\n${RED}This is the result produced by your trained model  ${NC}"
python ${EVALSCRIPT} ${LOGFILE}

echo -e "\nThe result may be different from pre-trained models due to GPU type, Pytorch ver, and so on"

exit 


