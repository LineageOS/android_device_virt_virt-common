/*
 * Copyright (C) 2022 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "BootControl.h"
#include <cstdint>

#include <android-base/logging.h>

using ndk::ScopedAStatus;

namespace aidl::android::hardware::boot {

BootControl::BootControl() {}

ScopedAStatus BootControl::getActiveBootSlot(int32_t* _aidl_return) {
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getCurrentSlot(int32_t* _aidl_return) {
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getNumberSlots(int32_t* _aidl_return) {
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getSnapshotMergeStatus(MergeStatus* _aidl_return) {
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getSuffix(int32_t in_slot, std::string* _aidl_return) {
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::isSlotBootable(int32_t in_slot, bool* _aidl_return) {
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::isSlotMarkedSuccessful(int32_t in_slot, bool* _aidl_return) {
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::markBootSuccessful() {
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::setActiveBootSlot(int32_t in_slot) {
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::setSlotAsUnbootable(int32_t in_slot) {
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::setSnapshotMergeStatus(MergeStatus in_status) {
    return ScopedAStatus::ok();
}

}  // namespace aidl::android::hardware::boot
