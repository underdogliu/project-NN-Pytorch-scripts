# Prepare the data directories for augmentation experiment
# Just split the annotated wav files into different sub-directories
import glob
import os
import sys

from shutil import copyfile


if __name__ == "__main__":
    src_augdata_dir = "20230327_aug_data/data"
    tar_augdata_dir = "DATA/asvspoof2019_LA"
    aug_sources = ["none", "reverb", "noise", "mp3"]

    for aug_src in aug_sources:
        aug_src_files = glob.glob(src_augdata_dir + "/*-{0}.flac".format(aug_src))
        os.makedirs(tar_augdata_dir + "/train_dev_{0}".format(aug_src))
        for item in aug_src_files:
            utt_name = os.path.basename(item).split("-")[0]
            copyfile(
                item,
                tar_augdata_dir + "/train_dev_{0}/{1}.flac".format(aug_src, utt_name),
            )
