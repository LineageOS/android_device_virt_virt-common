#include <fcntl.h>
#include <mutex>
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
using std::mutex;
using std::string;
using std::to_string;
using std::vector;

namespace libgrub_boot_control {

namespace {

const int INVALID_SLOT = -1;
const int COMMAND_FAILED = -2;

}

GrubBootControl::GrubBootControl(vector<string> slots, string grubenv_path, string var_key_prefix)
    : mSlots(slots), mVarKeyPrefix(var_key_prefix) {
    CHECK(!mSlots.empty()) << "No slot";

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

GrubBootControl::~GrubBootControl() {
    CommitGrubVars();
    close(mFd);
}

bool GrubBootControl::CommitGrubVars() {
    mMapMutex.lock();
    if (!TEMP_FAILURE_RETRY(WriteFdFromMap(mFd, mMap))) {
        RemoveUnusedElementsFromMap();
        if (!TEMP_FAILURE_RETRY(WriteFdFromMap(mFd, mMap))) {
            mMapMutex.unlock();
            LOG(ERROR) << "Failed to commit grub vars";
            return false;
        }
    }
    mMapMutex.unlock();
    return true;
}

void GrubBootControl::PrintGrubVars() {
    mMapMutex.lock();
    LOG(DEBUG) << "Print GRUB variables:"
    for (const auto& [key, value] : mMap) {
        LOG(DEBUG) << key << "=" << value;
    }
    mMapMutex.unlock();
}

bool GrubBootControl::isSlotValid(unsigned int slot) {
    if (slot < 0 || slot > getNumberSlots() - 1) {
        LOG(WARNING) << "Invalid slot: " << to_string(slot);
        return false;
    }
    return true;
}

string GrubBootControl::GetItemKeyForGlobal(string item) {
    return mVarKeyPrefix + "global_" + item;
}

string GrubBootControl::GetItemValueForGlobal(string item) {
    mMapMutex.lock();
    string ret = mMap[GetItemKeyForGlobal(item)];
    mMapMutex.unlock();
    return ret;
}

bool GrubBootControl::SetItemValueForGlobal(string item, string value, bool commit) {
    mMapMutex.lock();
    mMap.insert_or_assign(GetItemKeyForSlot(item), value);
    mMapMutex.unlock();
    if (commit && !CommitGrubVars()) return false;
    return true;
}

string GrubBootControl::GetItemKeyForSlot(unsigned int slot, string item) {
    string slot_str;
    if (isSlotValid(slot)) {
        slot_str = GetStringFromSlotNumber(slot);
    } else {
        slot_str = "UNKNOWN";
    }
    return mVarKeyPrefix + "slot_" + slot_str + "_" + item;
}

string GrubBootControl::GetItemValueForSlot(unsigned int slot, string item) {
    mMapMutex.lock();
    string ret = mMap[GetItemKeyForSlot(slot, item)];
    mMapMutex.unlock();
    return ret;
}

bool GrubBootControl::SetItemValueForSlot(unsigned int slot, string item, string value, bool commit) {
    mMapMutex.lock();
    mMap.insert_or_assign(GetItemKeyForSlot(slot, item), value);
    mMapMutex.unlock();
    if (commit && !CommitGrubVars()) return false;
    return true;
}

bool GrubBootControl::SetItemValueForAllSlots(string item, string value, bool commit) {
    int ret = true;
    for (int i = 0; i < getNumberSlots(); i++) {
        ret &= SetItemValueForSlot(i, item, value, false);
    }
    if (commit && !CommitGrubVars()) return false;
    return ret;
}

string GrubBootControl::GetStringFromSlotNumber(unsigned int slot) {
    return mSlots[i];
}

int GrubBootControl::GetSlotNumberFromString(string str) {
    for (int i = 0; i < getNumberSlots(); i++) {
        if (GetStringFromSlotNumber(i) == str) {
            return i;
        }
    }
    return INVALID_SLOT;
}

}  // namespace libgrub_boot_control
