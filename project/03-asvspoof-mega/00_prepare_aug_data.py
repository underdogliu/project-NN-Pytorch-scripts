# Prepare the data directories for augmentation experiment
# Just split the annotated wav files into different sub-directories
import glob
import os
import sys

from shutil import copyfile


if __name__ == "__main__":
    src_augdata_dir = "20230327_aug_data/data"
    tar_augdata_dir = "DATA/asvspoof2019_LA"
    aug_sources = ["reverb", "noise", "mp3"]

    for aug_src in aug_sources:
        with open(tar_augdata_dir + "/scp/train_{0}.lst".format(aug_src), "w") as tar_trial:
            # prepare wav files
            aug_src_files = glob.glob(src_augdata_dir + "/*-{0}.flac".format(aug_src))
            os.makedirs(tar_augdata_dir + "/train_dev_{0}".format(aug_src), exist_ok=True)
            for item in aug_src_files:
                utt_name = os.path.basename(item).split("-")[0]
                # copy the aug data
                copyfile(
                    item,
                    tar_augdata_dir
                    + "/train_dev_{0}/{1}-{0}.flac".format(aug_src, utt_name),
                )
                # then copy the original data
                copyfile(
                    src_augdata_dir + "/{0}-none.flac".format(utt_name),
                    tar_augdata_dir
                    + "/train_dev_{0}/{1}.flac".format(aug_src, utt_name),
                )
                # prepare trial files
                tar_trial.write("{0}-{1}\n".format(utt_name, aug_src))

        # create new trial file via concatenation
        os.system("grep T '{0}/scp/train_{1}.lst' | cat - {0}/scp/train.lst | sort -u > {0}/scp/train_aug_{1}.lst".format(tar_augdata_dir, aug_src))

