import os
import sys


if __name__ == "__main__":
    input_score = "score.txt"
    eval_protocol = "trial_metadata.txt"
    target_score_file = "ASVspoof2021.LA.asv.eval.gi.trl.scores.txt"

    score_pairs = {}
    with open(input_score, "r") as inps:
        for line in inps:
            full_spk, full_utt, score = line.split()
            score_pairs[(full_spk, full_utt)] = score

    with open(eval_protocol, "r") as evp, open(target_score_file, "w") as ass:
        for line in evp:
            # LA_0007-alaw-ita_tx LA_E_5013670-alaw-ita_tx alaw ita_tx bonafide nontarget notrim eval
            full_spk, full_utt, _, _, attack, decision, _, type_set = line.split()
            if type_set == "progress":
                continue
            score = score_pairs[(full_spk, full_utt)]
            ass.write("{0} {1} {2}\n".format(attack, decision, score))
