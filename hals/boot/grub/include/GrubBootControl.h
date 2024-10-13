#include <string>
#include <vector>

#include <libgrub_editenv.h>

namespace aidl::android::hardware::boot {

class GrubBootControl {
  public:
    GrubBootControl();

    isSlotValid(unsigned int slot);

  protected:
    GetVarKeyForGlobal(string item);
    GetItemValueForGlobal(string item);
    SetItemValueForGlobal(string item, string value, bool commit = true);

    GetVarKeyForSlot(unsigned int slot, string item);
    GetItemValueForSlot(unsigned int slot, string item);
    SetItemValueForSlot(unsigned int slot, string item, string value, bool commit = true);

  private:
    ::libgrub_editenv::GrubEnvMap mMap;
}

}  // namespace aidl::android::hardware::boot
