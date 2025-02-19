#!/bin/bash -e

# Do not run in CI environments.
# Our CI has its own static linter.
# As of 2025/01, this should save some 20-40s per build.
if [ -n "${CI+x}" ]; then
  echo 'CI environment detected. Skipping SwiftLint build phase in favor of dedicated CI process.'
  exit 0
fi

# Do not run when archiving (ACTION = install).
#
# For some reason, running when trying to archive, via CLI, results in a compilation failure at times.
#
# fatal error: module 'WordPressSharedObjC' in AST file '/path/to/DerivedData/ModuleCache.noindex/EQUUY9BHSJ5N/WordPressSharedObjC-5G93B85NZ09I.pcm'
# (imported by AST file '/Users/gio/Developer/a8c/wpios/DerivedData/WordPress/Build/Intermediates.noindex/ArchiveIntermediates/WordPress Alpha/PrecompiledHeaders/WordPress-Bridging-Header-swift_1L0UBHDEION2G-clang_EQUUY9BHSJ5N.pch')
# is not defined in any loaded module map file;
# maybe you need to load '/Users/gio/Developer/a8c/wpios/DerivedData/WordPress/Build/Intermediates.noindex/ArchiveIntermediates/WordPress Alpha/IntermediateBuildFilesPath/GeneratedModuleMaps-iphoneos/WordPressSharedObjC.modulemap'?
if [ "${ACTION}" == "install" ]; then
  echo "info: Running during archival (detected ACTION = $ACTION). Skipping SwiftLint because of a build failure during archival we are yet to investigate."
  exit 0
fi

rake lint
