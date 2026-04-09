// ---------------------------------------------------------------------------
// Copyright 2026 Mateusz Nalewajski
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: GPL-3.0-or-later
// ---------------------------------------------------------------------------

#ifndef NES_LOADER_H
#define NES_LOADER_H

#include <stdint.h>

int nes_load_without_save(const char *path);
int nes_load_with_save(const char *path, const char *save_path);
int nes_save(const char *save_path);

int sdcard_ls(const char *path);

uint32_t prg_nvram_size(uint64_t mapper_flags);

#endif
