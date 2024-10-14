#include <iostream>
#include <map>
#include <string>

#include <GrubBootControl.h>

#define CHECK_AND_PROVIDE_SLOT_NUMBER                             \
    if (argc != 4) {                                              \
        cout << "Please specify slot" << endl;                    \
        return 1;                                                 \
    }                                                             \
    int slot = stoi(string(argv[3]));                             \
    if (slot < 0) {                                               \
        cout << "Invalid slot number " << to_string(slot) << endl; \
        return 1;                                                 \
    }

using namespace libgrub_boot_control;

using std::cout;
using std::endl;
using std::map;
using std::stoi;
using std::string;
using std::to_string;

const int INVALID_SLOT = -1;
const int COMMAND_FAILED = -2;
const string kHelpText = "Usage: grub_boot_control <path> [command] [parameters ...]\n";

GrubBootControl* g;

int PrintIntRetValue(int ret, bool zero_is_ok = false) {
    switch (ret) {
        case INVALID_SLOT:
            cout << "Invalid slot";
            break;
        case COMMAND_FAILED:
            cout << "Command failed";
            break;
        default:
            if (ret < 0)
                cout << "Unhandled error";
            else if (ret == 0 && zero_is_ok)
                cout << "OK";
            else
                cout << to_string(ret);
            break;
    }
    cout << endl;
    return (ret < 0) ? 1 : 0;
}

int cmd_getActiveBootSlot(int, char**) {
    return PrintIntRetValue(g->getActiveBootSlot());
}

int cmd_getCurrentSlot(int, char**) {
    return PrintIntRetValue(g->getCurrentSlot());
}

int cmd_getNumberSlots(int, char**) {
    return PrintIntRetValue(g->getNumberSlots());
}

int cmd_getSnapshotMergeStatus(int, char**) {
    cout << g->getSnapshotMergeStatus() << endl;
    return 0;
}

int cmd_getSuffix(int argc, char** argv) {
    CHECK_AND_PROVIDE_SLOT_NUMBER
    cout << g->getSuffix(slot) << endl;
    return 0;
}

int cmd_isSlotBootable(int argc, char** argv) {
    CHECK_AND_PROVIDE_SLOT_NUMBER
    return PrintIntRetValue(g->isSlotBootable(slot));
}

int cmd_isSlotMarkedSuccessful(int argc, char** argv) {
    CHECK_AND_PROVIDE_SLOT_NUMBER
    return PrintIntRetValue(g->isSlotMarkedSuccessful(slot));
}

int cmd_markBootSuccessful(int, char**) {
    return PrintIntRetValue(g->markBootSuccessful(), true);
}

int cmd_setActiveBootSlot(int argc, char** argv) {
    CHECK_AND_PROVIDE_SLOT_NUMBER
    return PrintIntRetValue(g->setActiveBootSlot(slot), true);
}

int cmd_setSlotAsUnbootable(int argc, char** argv) {
    CHECK_AND_PROVIDE_SLOT_NUMBER
    return PrintIntRetValue(g->setSlotAsUnbootable(slot), true);
}

int cmd_setSnapshotMergeStatus(int argc, char** argv) {
    if (argc != 4) {
        cout << "Please specify merge status string" << endl;
        return 1;
    }
    return PrintIntRetValue(g->setSnapshotMergeStatus(string(argv[3])), true);
}

const map<string, int (*)(int, char**)> kCommandMap = {
        {"getActiveBootSlot", &cmd_getActiveBootSlot},
        {"getCurrentSlot", &cmd_getCurrentSlot},
        {"getNumberSlots", &cmd_getNumberSlots},
        {"getSnapshotMergeStatus", &cmd_getSnapshotMergeStatus},
        {"getSuffix", &cmd_getSuffix},
        {"isSlotBootable", &cmd_isSlotBootable},
        {"isSlotMarkedSuccessful", &cmd_isSlotMarkedSuccessful},
        {"markBootSuccessful", &cmd_markBootSuccessful},
        {"setActiveBootSlot", &cmd_setActiveBootSlot},
        {"setSlotAsUnbootable", &cmd_setSlotAsUnbootable},
        {"setSnapshotMergeStatus", &cmd_setSnapshotMergeStatus},
};

int main(int argc, char** argv) {
    bool show_commands = false;
    int ret = 0;

    if (argc < 2) {
        cout << kHelpText;
        return 1;
    }

    g = new GrubBootControl(string(argv[1]));

    if (argc == 2) {
        g->PrintGrubVars();
        goto out;
    }

    show_commands = string(argv[2]) == "help";
    if (show_commands) cout << "Available commands:" << endl;
    for (const auto& [cmd_name, cmd_func] : kCommandMap) {
        if (show_commands) {
            cout << "  " << cmd_name << endl;
            continue;
        }
        if (!strcmp(argv[2], cmd_name.c_str())) {
            ret = cmd_func(argc, argv);
            goto out;
        }
    }
    if (!show_commands) {
        cout << "subcommand not found" << endl;
        ret = 1;
    }

out:
    delete g;
    return ret;
}
