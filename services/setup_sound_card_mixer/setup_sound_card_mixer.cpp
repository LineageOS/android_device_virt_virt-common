#define LOG_TAG "setup_sound_card_mixer"

#include <android-base/logging.h>
#include <tinyalsa/asoundlib.h>

#include <climits>
#include <string>
#include <unordered_map>
#include <vector>

using std::pair;
using std::string;
using std::to_string;
using std::unordered_map;
using std::vector;

struct MixerControl {
    std::string name;
    enum mixer_ctl_type type;
    int value;
};

constexpr int kAlsaCard = 0;

const unordered_map<string, vector<MixerControl>> kCardMixerMap = {
        {"Ensoniq AudioPCI",
         {{"Master Playback Switch", MIXER_CTL_TYPE_BOOL, 1},
          {"Master Playback Volume", MIXER_CTL_TYPE_INT, INT_MAX},
          {"PCM Playback Switch", MIXER_CTL_TYPE_BOOL, 1},
          {"PCM Playback Volume", MIXER_CTL_TYPE_INT, INT_MAX}}},
};

int setMixerControlPercent(struct mixer_ctl* ctl, int percent) {
    LOG(INFO) << __func__ << ": " << string(mixer_ctl_get_name(ctl)) << " = " << to_string(percent)
              << "%";
    const unsigned int n = mixer_ctl_get_num_values(ctl);
    for (unsigned int id = 0; id < n; id++) {
        if (int error = mixer_ctl_set_percent(ctl, id, percent); error != 0) {
            LOG(ERROR) << __func__ << ": Failed to set " << string(mixer_ctl_get_name(ctl));
            return error;
        }
    }
    return 0;
}

int setMixerControlValue(struct mixer_ctl* ctl, int value) {
    LOG(INFO) << __func__ << ": " << string(mixer_ctl_get_name(ctl)) << " = " << to_string(value);
    const unsigned int n = mixer_ctl_get_num_values(ctl);
    for (unsigned int id = 0; id < n; id++) {
        if (int error = mixer_ctl_set_value(ctl, id, value); error != 0) {
            LOG(ERROR) << __func__ << ": Failed to set " << string(mixer_ctl_get_name(ctl));
            return error;
        }
    }
    return 0;
}

int main() {
    int ret = 0, tmp_ret = 0;
    unsigned int processed_ctls = 0;

    struct mixer* mixer = mixer_open(kAlsaCard);
    if (!mixer) {
        LOG(ERROR) << "Failed to open mixer";
        return 1;
    }

    string mixer_name = string(mixer_get_name(mixer));
    LOG(INFO) << "Mixer name: " << mixer_name;

    for (const auto& [it_name, it_ctl_vec] : kCardMixerMap) {
        if (mixer_name != it_name) continue;
        for (const auto& it_ctl : it_ctl_vec) {
            struct mixer_ctl* ctl = mixer_get_ctl_by_name(mixer, it_ctl.name.c_str());
            if (ctl != nullptr && mixer_ctl_get_type(ctl) == it_ctl.type) {
                if (it_ctl.value == INT_MAX) {
                    tmp_ret = setMixerControlPercent(ctl, 100);
                } else {
                    tmp_ret = setMixerControlValue(ctl, it_ctl.value);
                }
                if (!tmp_ret) processed_ctls++;
                ret |= tmp_ret;
            } else {
                LOG(ERROR) << "Failed to open mixer control " << it_ctl.name;
            }
        }
    }

    LOG(INFO) << "Number of processed mixer controls: " << to_string(processed_ctls);
    mixer_close(mixer);
    return ret;
}
