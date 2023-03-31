# Prepare the data directories for VCC DF ablation experiment
# The general gist is to select half of the speakers from the
#   VCC part of 2021 DF datasets for training. Then we perform
#   evaluation on the 21 DF datasets, with corresponding data
#   (speakers) removed.
import glob
import os
import random
import sys

import time

from shutil import copyfile
from pydub import AudioSegment


def wav2flac(src_wav_path, tar_flac_path):
    song = AudioSegment.from_wav(src_wav_path)
    song.export(tar_flac_path, format="flac")


if __name__ == "__main__":
    src_21DF_dir = "DATA/asvspoof2021_DF"
    tar_21DF_dir = "DATA/asvspoof2021_DF_vcc"

    src_19LA_dir = "DATA/asvspoof2019_LA"
    tar_19LA_dir = "DATA/asvspoof2019_LA_vcc"

    # fetch the VCC lists from te 2021 DF
    asvspoof_lists = {}
    vcc2018_lists = {}
    vcc2020_lists = {}
    with open(src_21DF_dir + "/protocol.txt", "r") as srcd:
        for line in srcd:
            spk, utt, dataset, type_attack, decision = line.split()
            if dataset == "asvspoof":
                continue
            elif dataset == "vcc2018":
                if spk not in vcc2018_lists.keys():
                    vcc2018_lists[spk] = [utt]
                else:
                    vcc2018_lists[spk].append(utt)
            else:
                if spk not in vcc2020_lists.keys():
                    vcc2020_lists[spk] = [utt]
                else:
                    vcc2020_lists[spk].append(utt)
    vcc_lists = {**vcc2018_lists, **vcc2020_lists}

    # select the speakers to:
    # 1. Bonafide utterances go to training side
    # 2. All utterances (bonafide+spoof) removed from testing side
    spks_vcc2018 = list(vcc2018_lists.keys())
    spks_vcc2020 = list(vcc2020_lists.keys())
    random.shuffle(spks_vcc2018)
    random.shuffle(spks_vcc2020)
    selected_spks_vcc2018 = spks_vcc2018[: int(len(spks_vcc2018) / 2)]
    selected_spks_vcc2020 = spks_vcc2020[: int(len(spks_vcc2020) / 2)]
    selected_spks = selected_spks_vcc2018 + selected_spks_vcc2020
    print("selected spks: {0}".format(selected_spks))

    # Write the protocol.txt and scp for 2021 DF
    with open(src_21DF_dir + "/protocol.txt", "r") as srcd, open(
        tar_21DF_dir + "/protocol.txt", "w"
    ) as tard:
        for line in srcd:
            spk, utt, dataset, type_attack, decision = line.split()
            if spk in selected_spks:
                continue
            else:
                tard.write(line + "\n")
    os.makedirs(tar_21DF_dir + "/scp", exist_ok=True)
    os.system(
        "cat {0} | cut -d' ' -f3 | sort -u > {1}".format(
            tar_21DF_dir + "/protocol.txt", tar_21DF_dir + "/scp/test.lst"
        )
    )

    # Write the ASVspoof 2019 LA new training data
    os.system("cp {0} {1}".format(src_19LA_dir + "/protocol.txt", tar_19LA_dir))
    os.system(
        "mkdir -p {0} {1} && cp {2} {0}".format(
            tar_19LA_dir + "/scp",
            tar_19LA_dir + "/eval",
            src_19LA_dir + "/scp/train.lst",
        )
    )
    with open(src_21DF_dir + "/protocol.txt", "r") as srcd, open(
        tar_19LA_dir + "/protocol.txt", "a+"
    ) as tarp:
        for line in srcd:
            spk, utt, dataset, type_attack, decision = line.split()
            if spk not in selected_spks:
                tarp.write(line + "\n")
            else:
                continue

    with open(tar_19LA_dir + "/scp/train.lst", "a+") as tard:
        for spks_list in [spks_vcc2018, spks_vcc2020]:
            for spk in spks_list:
                if spk in selected_spks:
                    continue
                else:
                    utterances = vcc_lists[spk]
                    for item in utterances:
                        src_wav_path = src_21DF_dir + "/eval/{0}.wav".format(item)
                        tar_flac_path = tar_19LA_dir + "/train_dev/{0}.flac".format(
                            item
                        )
                        # convert_cmd = "ffmpeg -hide_banner -loglevel error -i {0} -af aformat=s16:16000 {1}".format(
                        #     src_wav_path, tar_flac_path
                        # )
                        # os.system(convert_cmd)
                        wav2flac(src_wav_path, tar_flac_path)
                        tard.write(item + "\n")
