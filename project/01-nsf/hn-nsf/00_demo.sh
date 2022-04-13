#!/bin/sh

DATALINK=https://zenodo.org/record/6456704/files/project-01-train-data-set.tar
PACKNAME=project-01-train-data-set
FILENAME=cmu-arctic-data-set
ENVFILE=../../../env.sh

RED='\033[0;32m'
NC='\033[0m'

# download CMU-arctic data
if [ ! -e "../DATA/${FILENAME}" ];then
    echo -e "${RED}Downloading data${NC}"
    wget ${DATALINK}

    if [ -e "./${PACKNAME}.tar" ];then	
	tar -xf ${PACKNAME}.tar
	cd ${FILENAME}
	sh 00_get_wav.sh
	cd ../
	mv ${FILENAME} ../DATA/${FILENAME}
	rm ${PACKNAME}.tar
    else
	echo "Cannot download ${DATALINK}. Please contact the author"
    	exit
    fi
fi

# try pre-trained model
if [ -e "../DATA/${FILENAME}" ];then
    echo -e "${RED}Try pre-trained model${NC}"
    source ${ENVFILE}
    python main.py --inference --trained-model __pre_trained/trained_network.pt --output-dir __pre_trained/output
    echo -e "${RED}Please check generated waveforms from pre-trained model in ./__pre_trained/output"
    echo -e "----"

else
    echo "Cannot find ../DATA/${FILENAME}. Please contact the author"
fi


# train the model
if [ -e "../DATA/${FILENAME}" ];then
    echo -e "${RED}Train a new model${NC}"
    echo -e "${RED}Training will take several hours. Please don't quit this job. ${NC}"
    echo -e "${RED}Please check log_train and log_err for monitoring the training process.${NC}"
    source ${ENVFILE}
    python main.py --epochs 100 --num-workers 10 > log_train 2>log_err
else
    echo "Cannot find ../DATA/${FILENAME}. Please contact the author"
fi

# generate using trained model
if [ -e "../DATA/${FILENAME}" ];then
    echo -e "${RED}Model is trained${NC}"
    echo -e "${RED}Generate waveform${NC}"
    python main.py --inference --trained-model trained_network.pt --output-dir output
else
    echo "Cannot find ../DATA/${FILENAME}. Please contact the author"
fi
