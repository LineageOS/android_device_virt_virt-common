#include <string>
#include <vector>

#include <libgrub_editenv.h>

namespace aidl::android::hardware::boot {

class GrubBootControl {
  public:
    GrubBootControl();

    bool isSlotValid(unsigned int slot);

  protected:
    std::string GetVarKeyForGlobal(string item);
    std::string GetItemValueForGlobal(string item);
    bool SetItemValueForGlobal(string item, string value, bool commit = true);

    std::string GetVarKeyForSlot(unsigned int slot, string item);
    std::string GetItemValueForSlot(unsigned int slot, string item);
    bool SetItemValueForSlot(unsigned int slot, string item, string value, bool commit = true);

  private:
    ::libgrub_editenv::GrubEnvMap mMap;
}

}  // namespace aidl::android::hardware::boot
