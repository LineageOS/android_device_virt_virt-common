#include <string>
#include <vector>

#include <libgrub_editenv.h>

#include <GrubBootControl.h>

using namespace libgrub_editenv;

namespace aidl::android::hardware::boot {

namespace {

const string kVarKeyPrefix = "abootctrl_";
const vector<string> kSlots = {"a", "b"};

}

unsigned int GrubBootControl::getNumberSlots() {
    return kSlots.size();
}

bool GrubBootControl::isSlotValid(unsigned int slot) {
    if (!slot || slot > getNumberSlots()) {
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

}  // namespace aidl::android::hardware::boot
