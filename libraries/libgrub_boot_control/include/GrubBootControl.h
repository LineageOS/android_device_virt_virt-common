#include <string>

#include <android-base/unique_fd.h>

#include <libgrub_editenv.h>

namespace libgrub_boot_control {

class GrubBootControl {
  public:
    GrubBootControl();

    // android.hardware.boot
    unsigned int getNumberSlots();

    // Util
    bool isSlotValid(unsigned int slot);

  protected:
    std::string GetVarKeyForGlobal(string item);
    std::string GetItemValueForGlobal(string item);
    bool SetItemValueForGlobal(string item, string value, bool commit = true);

    std::string GetVarKeyForSlot(unsigned int slot, string item);
    std::string GetItemValueForSlot(unsigned int slot, string item);
    bool SetItemValueForSlot(unsigned int slot, string item, string value, bool commit = true);

  private:
    ::android::base::unique_fd mFd;
    ::libgrub_editenv::GrubEnvMap mMap;

    void InitGrubVars();
    bool CommitGrubVars();
}

}  // namespace libgrub_boot_control
