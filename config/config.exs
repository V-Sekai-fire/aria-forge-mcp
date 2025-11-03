# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Configure aria_storage for resource storage
config :aria_storage, AriaStorage.Repo,
  database: Path.join(System.user_home!(), ".aria_forge/aria_storage.db"),
  pool_size: 1

config :waffle,
  storage: Waffle.Storage.Local,
  storage_dir_prefix: Path.join(System.user_home!(), ".aria_forge/storage")
