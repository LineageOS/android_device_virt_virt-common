#include <fcntl.h>
#include <string>
#include <vector>

#define LOG_TAG "GrubBootControlUtil"

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/unique_fd.h>
#include <libgrub_editenv.h>

#include <GrubBootControl.h>

using namespace libgrub_editenv;

using android::base::unique_fd;
using std::string;
using std::to_string;
using std::vector;

namespace libgrub_boot_control {

namespace {

const string kGrubenvFilePath = "/mnt/vendor/persist/grubenv_abootctrl";
const string kVarKeyPrefix = "abootctrl_";
const vector<string> kSlots = {"a", "b"};

}

GrubBootControl::GrubBootControl(string grubenv_path_override) {
    string grubenv_path = !grubenv_path_override.empty() ?
                           grubenv_path_override : kGrubenvFilePath;
    mFd = unique_fd(TEMP_FAILURE_RETRY(open(grubenv_path.c_str(),
                                            O_RDWR |
                                            O_CLOEXEC | O_BINARY | O_TRUNC)));
    if (mFd.ok()) {
        CHECK(LoadFdToMap(mFd, &mMap)) << "Failed to parse " << grubenv_path;
    } else {
        mFd = unique_fd(TEMP_FAILURE_RETRY(open(grubenv_path.c_str(),
                                                O_WRONLY | O_CREAT |
                                                O_CLOEXEC | O_BINARY | O_TRUNC)));
        CHECK(mFd.ok()) << "Failed to open or create " << grubenv_path;
        InitGrubVars();
        CHECK(CommitGrubVars());
    }
}

void GrubBootControl::InitGrubVars() {
    // WIP
    SetItemValueForGlobal("meow", "nya", false);
    SetItemValueForAllSlots("nya", "mrrp", false);
}

bool GrubBootControl::CommitGrubVars() {
    if (!TEMP_FAILURE_RETRY(WriteFdFromMap(mFd, mMap))) {
        LOG(ERROR) << "Failed to commit grub vars";
        return false;
    }
    return true;
}

unsigned int GrubBootControl::getNumberSlots() {
    return kSlots.size();
}

bool GrubBootControl::isSlotValid(unsigned int slot) {
    if (!slot || slot > getNumberSlots()) {
        LOG(WARNING) << "Invalid slot: " << to_string(slot);
        return false;
    }
    return true;
}

string GrubBootControl::GetVarKeyForGlobal(string item) {
    return kVarKeyPrefix + "global_" + item;
}

string GrubBootControl::GetItemValueForGlobal(string item) {
    return mMap[GetVarKeyForGlobal(item)];
}

bool GrubBootControl::SetItemValueForGlobal(string item, string value, bool commit) {
    mMap.insert_or_assign(GetVarKeyForSlot(item), value);
    if (commit && !CommitGrubVars()) return false;
    return true;
}

string GrubBootControl::GetVarKeyForSlot(unsigned int slot, string item) {
    string slot_str;
    if (isSlotValid(slot)) {
        slot_str = kSlots[slot];
    } else {
        slot_str = "UNKNOWN";
    }
    return kVarKeyPrefix + "slot_" + slot_str + "_" + item;
}

string GrubBootControl::GetItemValueForSlot(unsigned int slot, string item) {
    return mMap[GetVarKeyForSlot(slot, item)];
}

bool GrubBootControl::SetItemValueForSlot(unsigned int slot, string item, string value, bool commit) {
    mMap.insert_or_assign(GetVarKeyForSlot(slot, item), value);
    if (commit && !CommitGrubVars()) return false;
    return true;
}

bool GrubBootControl::SetItemValueForAllSlots(string item, string value, bool commit) {
    int ret = true;
    for (int i = 1; i <= getNumberSlots(); i++) {
        ret &= SetItemValueForSlot(i, item, value, false);
    }
    if (commit && !CommitGrubVars()) return false;
    return ret;
}

}  // namespace libgrub_boot_control
