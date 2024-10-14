#include <iostream>
#include <string>

#include <GrubBootControl.h>

using namespace libgrub_boot_control;

using std::cout;
using std::string;

const string kHelpText =
    "Usage: grub_boot_control_init <path>\n"

int main(int argc, char** argv) {
    if (argc != 2) {
        cout << kHelpText;
        return 1;
    }

    GrubBootControl* g = new GrubBootControl(string(argv[1]));
    g->PrintGrubVars();
    delete g;
    return 0;
}
