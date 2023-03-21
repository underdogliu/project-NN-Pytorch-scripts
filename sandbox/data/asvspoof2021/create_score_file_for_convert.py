import os
import sys


if __name__ == "__main__":
    input_score = "ASVspoof2021.LA.asv.eval.gi.trl.scores.txt"
    eval_protocol = "protocol.txt"

    score_pairs = {}
    with open(input_score, "r") as inps:
        for line in inps:
            full_spk, full_utt, score = line.split()
            utt = full_utt.split("-")[1]
            score_pairs[utt] = score

    with open(eval_protocol, "r") as evp, open("asv_scores.txt", "w") as ass:
        for line in evp:
            _, utt, _, attack, decision = line.split()
            score = score_pairs[utt]
            ass.write("{0} {1} {2}\n".format(attack, decision, score))
