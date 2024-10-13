#include <string>
#include <vector>

#define LOG_TAG "GrubBootControlUtil"

#include <android-base/logging.h>

#include <GrubBootControl.h>

#if defined(__ANDROID_VENDOR__) || defined(__ANDROID_RECOVERY__)
#include <android-base/properties.h>
using android::base::GetProperty;
#endif

using std::string;

namespace libgrub_boot_control {

namespace {

const int INVALID_SLOT = -1;
const int COMMAND_FAILED = -2;

// Unused for GRUB by default
const string kKeyGlobalSnapshotMergeStatus = "snapshot_merge_status"; // whatever string, boot control HAL should take care of validity
const string kKeySlotIsSuccessful = "is_successful"; // default is false

// Read-only for GRUB by default
const string kKeyGlobalActiveSlot = "active_slot"; // e.g. "a"

// Should be set by GRUB prior to booting entry
const string kKeyGlobalCurrentSlot = "current_slot"; // e.g. "a"
const string kKeySlotBootCount = "boot_count"; // default is empty. length of its value = times that GRUB tried to boot the slot
const string kKeySlotIsBootable = "is_bootable" // default is true. `if [ "$boot_count" = "XXXXXXX" ]; then is_bootable=false; fi`

/* TODO: Move to boot control HAL
string ConvertMergeStatusToString(MergeStatus merge_status) {
    switch (merge_status) {
        case MergeStatus::NONE: return "none";
        case MergeStatus::UNKNOWN: return "unknown";
        case MergeStatus::SNAPSHOTTED: return "snapshotted";
        case MergeStatus::MERGING: return "merging";
        case MergeStatus::CANCELLED: return "cancelled";
        default: return "invalid_merge_status"
    }
}

MergeStatus ConvertStringToMergeStatus(string str) {
    if (str == "none") return MergeStatus::NONE;
    if (str == "unknown") return MergeStatus::UNKNOWN;
    if (str == "snapshotted") return MergeStatus::SNAPSHOTTED;
    if (str == "merging") return MergeStatus::MERGING;
    if (str == "cancelled") return MergeStatus::CANCELLED;
    return MergeStatus::UNKNOWN;
}
*/

}

void GrubBootControl::InitGrubVars() {
    // Global
    SetItemValueForGlobal(kKeyGlobalSnapshotMergeStatus, "unknown");

    // Global: Active slot and Current slot
    string current_slot;
#if defined(__ANDROID_VENDOR__) || defined(__ANDROID_RECOVERY__)
    current_slot = GetProperty("ro.boot.slot_suffix", "")[1];
#endif
    if (current_slot.empty()) current_slot = mSlots.front();
    SetItemValueForGlobal(kKeyGlobalActiveSlot, current_slot, false);
    SetItemValueForGlobal(kKeyGlobalCurrentSlot, current_slot, false);

    // Slot
    SetItemValueForAllSlots(kKeySlotBootCount, "", false);
    SetItemValueForAllSlots(kKeySlotIsBootable, "true", false);
    SetItemValueForAllSlots(kKeySlotIsSuccessful, "false", false);
}

// android.hardware.boot

// Here we use `unsigned int` instead of `int` for slot parameter
// because negative values should be handled by the caller (boot control HAL)

int GrubBootControl::getActiveBootSlot() {
    string active_slot_str = GetItemValueForGlobal(kKeyGlobalActiveSlot);
    int ret = GetSlotNumberFromString(active_slot_str);
    return ret == INVALID_SLOT ? COMMAND_FAILED : ret;
}

int GrubBootControl::getCurrentSlot() {
    string current_slot_str = GetItemValueForGlobal(kKeyGlobalCurrentSlot);
    int ret = GetSlotNumberFromString(current_slot_str);
    return ret == INVALID_SLOT ? COMMAND_FAILED : ret;
}

unsigned int GrubBootControl::getNumberSlots() {
    return mSlots.size();
}

string GrubBootControl::getSnapshotMergeStatus() {
    return GetItemValueForGlobal(kKeyGlobalSnapshotMergeStatus);
}

string GrubBootControl::getSuffix(unsigned int slot) {
    if (!isSlotValid(slot)) return "";

    return "_" + GetStringFromSlotNumber(slot);
}

int GrubBootControl::isSlotBootable(unsigned int slot) {
    if (!isSlotValid(slot)) return INVALID_SLOT;

    string val = GetItemValueForSlot(slot, kKeySlotIsBootable);
    if (val == "false") return 0;
    return 1;
}

int GrubBootControl::isSlotMarkedSuccessful(unsigned int slot) {
    if (!isSlotValid(slot)) return INVALID_SLOT;

    string val = GetItemValueForSlot(slot, kKeySlotIsSuccessful);
    if (val = "true") return 1;
    return 0;
}

int GrubBootControl::markBootSuccessful() {
    // getCurrentSlot() may return invalid slot number (on error)
    int slot = getCurrentSlot();
    if (!isSlotValid(slot)) return COMMAND_FAILED;
    if (!SetItemValueForSlot(slot, kKeySlotIsSuccessful, "true"))
        return COMMAND_FAILED;

    return 0;
}

int GrubBootControl::setActiveBootSlot(unsigned int slot) {
    if (!isSlotValid(slot)) return INVALID_SLOT;

    if (!SetItemValueForGlobal(kKeyGlobalActiveSlot,
                               GetStringFromSlotNumber(slot)))
        return COMMAND_FAILED;

    return 0;
}

int GrubBootControl::setSlotAsUnbootable(unsigned int slot) {
    if (!isSlotValid(slot)) return INVALID_SLOT;

    if (!SetItemValueForSlot(slot, kKeySlotIsBootable, "false"))
        return COMMAND_FAILED;

    return 0;
}

int setSnapshotMergeStatus(string status) {
    if (!SetItemValueForGlobal(kKeyGlobalSnapshotMergeStatus, status))
        return COMMAND_FAILED;

    return 0;
}

}  // namespace libgrub_boot_control
