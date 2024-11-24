#define LOG_TAG "setup_sound_card"

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/properties.h>
#include <android-base/strings.h>
#include <tinyalsa/mixer.h>
#include <tinyalsa/pcm.h>

#include <cerrno>
#include <climits>
#include <fstream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

using android::base::ReadFileToString;
using android::base::SetProperty;
using android::base::Split;
using std::string;
using std::to_string;
using std::unordered_map;
using std::vector;

unsigned g_alsaCard = 0;

constexpr char kAlsaCardProp[] = "persist.vendor.audio.primary.alsa_card";
constexpr char kAlsaDeviceProp[] = "persist.vendor.audio.primary.alsa_device";
constexpr char kEnableMasterMixerControlProp[] =
        "persist.vendor.audio.primary.enable_master_mixer_control";
constexpr char kLatencyMsProp[] = "persist.vendor.audio.primary.latency_ms";

constexpr char kProcAsoundCardsPath[] = "/proc/asound/cards";

struct MixerControl {
    std::string name;
    enum mixer_ctl_type type;
    vector<int> values;
};

struct SoundCardSettings {
    unsigned alsaDevice;
    const vector<MixerControl>* mixerControlVec;
    bool enableMasterMixerControlInAudioHal;
    int32_t latencyMs;  // 0 - Unset, Positive - Set, Negative - Calculate
};

using SoundCardSettingsMapType = unordered_map<string, SoundCardSettings>;

const vector<MixerControl> kMixerControlVec_ENS1370 = {
        {"Master Playback Switch", MIXER_CTL_TYPE_BOOL, {1, 1}},
        {"Master Playback Volume", MIXER_CTL_TYPE_INT, {INT_MAX, INT_MAX}},
        {"Mono Playback Switch", MIXER_CTL_TYPE_BOOL, {1}},
        {"PCM Playback Switch", MIXER_CTL_TYPE_BOOL, {1, 1}},
        {"PCM Switch", MIXER_CTL_TYPE_BOOL, {1, 1}},
        {"PCM Volume", MIXER_CTL_TYPE_INT, {INT_MAX, INT_MAX}}};

const vector<MixerControl> kMixerControlVec_ENS1371 = {
        {"Master Playback Switch", MIXER_CTL_TYPE_BOOL, {1, 1}},
        {"Master Playback Volume", MIXER_CTL_TYPE_INT, {INT_MAX, INT_MAX}},
        {"PCM Playback Switch", MIXER_CTL_TYPE_BOOL, {1, 1}},
        {"PCM Playback Volume", MIXER_CTL_TYPE_INT, {INT_MAX, INT_MAX}}};

SoundCardSettingsMapType kSoundCardSettingsMap = {
        {"ENS1370 - Ensoniq AudioPCI", {0, &kMixerControlVec_ENS1370, true, -1}}, // broken
        {"ENS1371 - Ensoniq AudioPCI", {0, &kMixerControlVec_ENS1371, true, 200}},
        {"ICH - Intel 82801AA-ICH", {0, nullptr, false, 0}},
};

int setMixerControlValue(struct mixer_ctl* ctl, const vector<int>& values) {
    const unsigned int n = mixer_ctl_get_num_values(ctl);
    for (unsigned int id = 0; id < n; id++) {
        int value = id < values.size() ? values[id] : 0;
        if (value == INT_MAX) {
            if (int percent_error = mixer_ctl_set_percent(ctl, id, 100); percent_error != 0) {
                LOG(ERROR) << __func__ << ": Failed to set " << string(mixer_ctl_get_name(ctl));
                return percent_error;
            }
            continue;
        }
        if (int error = mixer_ctl_set_value(ctl, id, value); error != 0) {
            LOG(ERROR) << __func__ << ": Failed to set " << string(mixer_ctl_get_name(ctl));
            return error;
        }
    }
    return 0;
}

int applyMixerControlVec(const vector<MixerControl>* in_vec) {
    int ret = 0, tmp_ret = 0;
    unsigned int processed_ctls = 0;

    struct mixer* mixer = mixer_open(g_alsaCard);
    if (!mixer) {
        LOG(ERROR) << "Failed to open mixer";
        return -EPERM;
    }

    string mixer_name = string(mixer_get_name(mixer));
    LOG(INFO) << "Mixer name: " << mixer_name;

    for (const auto& it_ctl : *in_vec) {
        struct mixer_ctl* ctl = mixer_get_ctl_by_name(mixer, it_ctl.name.c_str());
        if (ctl != nullptr && mixer_ctl_get_type(ctl) == it_ctl.type) {
            tmp_ret = setMixerControlValue(ctl, it_ctl.values);
            if (!tmp_ret) processed_ctls++;
            ret |= tmp_ret;
        } else {
            LOG(ERROR) << "Failed to open mixer control: " << it_ctl.name;
            ret |= -ENOENT;
        }
    }

    LOG(INFO) << "Number of processed mixer controls: " << to_string(processed_ctls);
    mixer_close(mixer);
    return ret;
}

bool calculateAndSetLatencyMs(unsigned in_device) {
    auto pcm_params = pcm_params_get(g_alsaCard, in_device, PCM_OUT);
    if (pcm_params == NULL) {
        LOG(ERROR) << "Failed to get pcm params";
        return false;
    }

    unsigned int sample_rate = pcm_params_get_max(pcm_params, PCM_PARAM_RATE);

    /*
        unsigned int period_size = pcm_params_get_min(pcm_params, PCM_PARAM_PERIOD_SIZE);
        unsigned int period_count = pcm_params_get_min(pcm_params, PCM_PARAM_PERIODS);
        int32_t bufferSizeFrames = period_size * period_count;
    */
    static constexpr int32_t bufferSizeFrames = 4096;  // or 1024?

    int32_t nominalLatencyMs =
            static_cast<int32_t>(static_cast<double>(bufferSizeFrames) / sample_rate * 1000);
    LOG(INFO) << __func__ << ": " << to_string(bufferSizeFrames) << " / " << to_string(sample_rate)
              << " * 1000 = " << to_string(nominalLatencyMs);

    pcm_params_free(pcm_params);

    if (nominalLatencyMs <= 0) {
        LOG(ERROR) << "nominalLatencyMs <= 0";
        return false;
    }

    return SetProperty(kLatencyMsProp, to_string(nominalLatencyMs));
}

SoundCardSettingsMapType::const_iterator findSoundCard() {
    string cards_content_str;
    if (!ReadFileToString(kProcAsoundCardsPath, &cards_content_str)) {
        LOG(ERROR) << "Failed to read " << kProcAsoundCardsPath;
        return kSoundCardSettingsMap.end();
    }

    auto cards_content_vec = Split(cards_content_str, "\n");
    bool line_num_is_odd_number = false;
    for (auto& line : cards_content_vec) {
        line_num_is_odd_number = !line_num_is_odd_number;
        if (line.empty()) break;

        // Trim leading space
        line.erase(0, line.find_first_not_of(' '));

        if (line_num_is_odd_number) {
            // Card number is now at the beginning, Extract and Parse it
            string card_num_str = line.substr(0, line.find_first_of(' '));
            int card_num = std::stoi(card_num_str);
            LOG(DEBUG) << "Iterating sound card number: " << card_num_str;
            // Sound card name is everything after "]: "
            auto card_name_start_pos = line.find("]: ") + 3;
            string card_name = line.substr(card_name_start_pos);
            LOG(DEBUG) << "Iterating sound card name: " << card_name;
            // Find the sound card name in map
            auto map_find = kSoundCardSettingsMap.find(card_name);
            if (map_find == kSoundCardSettingsMap.end()) {
                continue;
            } else {
                LOG(INFO) << "Found sound card from map: " << card_name;
                g_alsaCard = card_num;
                return map_find;
            }
        } else {
            LOG(DEBUG) << "Iterating sound card description: " << line;
        }
    }

    return kSoundCardSettingsMap.end();
}

int main() {
    bool success = true;

    auto it_card = findSoundCard();
    if (it_card == kSoundCardSettingsMap.end()) {
        LOG(INFO) << "No recognized sound card found, Exiting.";
        return EXIT_FAILURE;
    }

    success &= SetProperty(kAlsaCardProp, to_string(g_alsaCard));
    success &= SetProperty(kAlsaDeviceProp, to_string(it_card->second.alsaDevice));

    if (it_card->second.mixerControlVec != nullptr &&
        applyMixerControlVec(it_card->second.mixerControlVec))
        success = false;

    if (it_card->second.enableMasterMixerControlInAudioHal) {
        success &= SetProperty(kEnableMasterMixerControlProp, "true");
    }

    if (it_card->second.latencyMs > 0) {
        success &= SetProperty(kLatencyMsProp, to_string(it_card->second.latencyMs));
    } else if (it_card->second.latencyMs < 0) {
        success &= calculateAndSetLatencyMs(it_card->second.alsaDevice);
    }

    return success ? 0 : EXIT_FAILURE;
}
