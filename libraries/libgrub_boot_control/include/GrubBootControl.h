#include <string>

#include <android-base/unique_fd.h>

#include <libgrub_editenv.h>

namespace libgrub_boot_control {

class GrubBootControl {
  public:
    GrubBootControl(std::vector<std::string> slots = std::vector<std::string>{"a", "b"},
                    std::string grubenv_path = "/mnt/vendor/persist/grubenv_abootctrl"),
                    std::string var_key_prefix = "abootctrl_";
    ~GrubBootControl();

    bool isSlotValid(unsigned int slot);
    void PrintGrubVars();

    // android.hardware.boot
    unsigned int getNumberSlots();

  protected:
    std::string GetVarKeyForGlobal(string item);
    std::string GetItemValueForGlobal(string item);
    bool SetItemValueForGlobal(string item, string value, bool commit = true);

    std::string GetVarKeyForSlot(unsigned int slot, string item);
    std::string GetItemValueForSlot(unsigned int slot, string item);
    bool SetItemValueForSlot(unsigned int slot, string item, string value, bool commit = true);
    bool SetItemValueForAllSlots(string item, string value, bool commit = true);

    std::string GetStringFromSlotNumber(unsigned int slot);
    int GetSlotNumberFromString(std::string str);

  private:
    std::vector<std::string> mSlots;
    std::string mVarKeyPrefix;

    ::android::base::unique_fd mFd;
    ::libgrub_editenv::GrubEnvMap mMap;

    void InitGrubVars();
    bool CommitGrubVars();
}

}  // namespace libgrub_boot_control
