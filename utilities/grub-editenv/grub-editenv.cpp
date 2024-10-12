#include <cstring>
#include <iostream>
#include <map>
#include <string>

#include <libgrub_editenv.h>

using namespace libgrub_editenv;

using std::cout;
using std::endl;
using std::map;
using std::string;

const string kHelpText =
        "Usage: grub-editenv <filename> <command> [parameters ...]\n"
        "\n"
        "Commands:\n"
        "  create\n"
        "  list\n"
        "  set [key=value ...]\n"
        "  unset [key ...]\n";

int cmd_create(int, char** argv) {
    GrubEnvMap empty_grub_env_map;
    string path = string(argv[1]);

    if (!WriteFileFromMap(path, empty_grub_env_map)) {
        cout << "failed to create " << path << endl;
        return 1;
    }

    return 0;
}

int cmd_list(int, char** argv) {
    GrubEnvMap loaded_map;
    string path = string(argv[1]);

    if (!LoadFileToMap(path, &loaded_map)) {
        cout << "failed to load " << path << endl;
        return 1;
    }

    for (const auto& [key, value] : loaded_map) {
        cout << key << "=" << value << endl;
    }

    return 0;
}

int cmd_set(int argc, char** argv) {
    GrubEnvMap loaded_map;
    string path = string(argv[1]);
    int vars_count = argc - 3;

    if (vars_count <= 0) {
        cout << "no vars to set" << endl;
        return 1;
    }

    if (!LoadFileToMap(path, &loaded_map)) {
        cout << "failed to load " << path << endl;
        return 1;
    }

    for (int i = 1; i <= vars_count; i++) {
        string variable = string(argv[i + 2]);

        size_t equal_sign_position = variable.find('=');
        if (equal_sign_position == string::npos) {
            cout << "invalid variable " << variable << endl;
            continue;
        }

        string key = variable.substr(0, equal_sign_position);
        string value = variable.substr(equal_sign_position + 1);

        loaded_map.insert_or_assign(key, value);
    }

    if (!WriteFileFromMap(path, loaded_map)) {
        cout << "failed to write to " << path << endl;
        return 1;
    }

    return 0;
}

int cmd_unset(int argc, char** argv) {
    GrubEnvMap loaded_map;
    string path = string(argv[1]);
    int vars_count = argc - 3;

    if (vars_count <= 0) {
        cout << "no vars to unset" << endl;
        return 1;
    }

    if (!LoadFileToMap(path, &loaded_map)) {
        cout << "failed to load " << path << endl;
        return 1;
    }

    for (int i = 1; i <= vars_count; i++) {
        string key, value;
        string variable = string(argv[i + 2]);

        size_t equal_sign_position = variable.find('=');
        if (equal_sign_position == string::npos) {
            key = variable;
        } else {
            key = variable.substr(0, equal_sign_position);
            value = variable.substr(equal_sign_position + 1);
        }

        auto search = loaded_map.find(key);
        if (search != loaded_map.end()) {
            if (!value.empty() && search->second != value) {
                cout << "value mismatches for key " << key << endl;
                continue;
            }
            loaded_map.erase(search);
        } else {
            cout << "key " << key << " not found" << endl;
            continue;
        }
    }

    if (!WriteFileFromMap(path, loaded_map)) {
        cout << "failed to write to " << path << endl;
        return 1;
    }

    return 0;
}

const map<string, int (*)(int, char**)> kCommandMap = {
        {"create", &cmd_create},
        {"list", &cmd_list},
        {"set", &cmd_set},
        {"unset", &cmd_unset},
};

int main(int argc, char** argv) {
    if (argc < 3) {
        cout << kHelpText;
        return 1;
    }

    for (const auto& [cmd_name, cmd_func] : kCommandMap) {
        if (!strcmp(argv[2], cmd_name.c_str())) {
            return cmd_func(argc, argv);
        }
    }

    cout << "invalid command" << endl;
    return 1;
}
