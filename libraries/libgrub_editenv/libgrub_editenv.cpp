#include <android-base/file.h>
#include <android-base/strings.h>

#include <map>
#include <string>
#include <string_view>
#include <vector>

#include <libgrub_editenv.h>

using android::base::ReadFileToString;
using android::base::Split;
using android::base::WriteStringToFile;
using std::map;
using std::string;
using std::string_view;
using std::vector;

static constexpr int kGrubenvFileSize = 1024;

static const string kHeader =
    "# GRUB Environment Block\n"
    "# WARNING: Do not edit this file by tools other than grub-editenv!!!\n";

namespace libgrub_editenv {

bool ValidateHeader(string_view content) {
    return content.starts_with(kHeader);
}

bool ValidateLength(string_view content) {
    return content.size() == kGrubenvFileSize;
}

bool Validate(string_view content) {
    return ValidateHeader(content) &&
           ValidateLength(content);
}

bool ParseStringToMap(const string& orig_content, GrubEnvMap* key_value_map) {
    // Copy the string
    string content = orig_content;

    // Clear the map
    key_value_map->clear();

    // Validate
    if (!Validate(content))
        return false;

    // Erase the header
    content.erase(0, kHeader.size());

    // Return if nothing defined
    if (content.find_first_not_of('#') == string::npos) return true;

    // Split into vector
    vector<string> variables = Split(content, "\n");
    if (variables.empty()) return false;

    // Drop the last element if it is empty space ('#')
    if (variables.back().starts_with('#')) variables.pop_back();

    // Split key and value and store into map
    for (const string& variable : variables) {
        size_t equal_sign_position = variable.find('=');
        if (equal_sign_position == string::npos) continue;

        string key = variable.substr(0, equal_sign_position);
        string value = variable.substr(equal_sign_position + 1);

        key_value_map->insert_or_assign(key, value);
    }

    return true;
}

bool LoadFileToMap(string path, GrubEnvMap* key_value_map) {
    string content;
    if (!ReadFileToString(path, &content, true)) return false;
    return ParseStringToMap(content, key_value_map);
}

void TrimOverflowVarsFromString(string* content) {
    while (content->size() > kGrubenvFileSize) {
        if (content->ends_with('\n')) content->pop_back();
        auto pos = content->find_last_of('\n') + 1;
        content->resize(pos);
    }
}

string GenerateStringFromMap(const GrubEnvMap& key_value_map, bool trim) {
    string content;

    // Assign the header
    content = kHeader;

    // Append key-value pairs
    for (const auto& [key, value] : key_value_map) {
        content += key + "=" + value + "\n";
    }

    // Check content size
    if (content.size() > kGrubenvFileSize) {
        if (trim) {
            TrimOverflowVarsFromString(&content);
        } else {
            return "";
        }
    }

    // Fill the tail with '#'
    content.resize(kGrubenvFileSize, '#');

    return content;
}

bool WriteFileFromMap(string path, const GrubEnvMap& key_value_map, bool trim) {
    string content = GenerateStringFromMap(key_value_map, trim);
    if (content.empty()) return false;
    return WriteStringToFile(content, path, true);
}

}  // namespace libgrub_editenv
