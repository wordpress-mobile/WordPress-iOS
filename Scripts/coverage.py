import glob
import os
import shutil
import subprocess
import sys

# Directories
dataDirectory = "./CoverageData"
cacheDirectory = dataDirectory + "/Cache"
derivedDataDirectory = dataDirectory + "/DerivedData"
buildObjectsDirectory = derivedDataDirectory + "/Build/Intermediates/WordPress.build/Debug-iphonesimulator/WordPress.build/Objects-normal/x86_64"
gcovOutputDirectory = dataDirectory + "/GCOVOutput"

# Files
gcovOutputFileName = gcovOutputDirectory + "/gcov.output"

# File Patterns
allGcdaFiles = "/*.gcda"
allGcnoFiles = "/*.gcno"

# Simulator
simulatorPlatform = "iOS Simulator,name=iPhone 6 (8.1),OS=8.1"

# Directory methods

def copyFiles(sourcePattern, destination):
    assert sourcePattern
    
    for file in glob.glob(sourcePattern):
        shutil.copy(file, destination)
    
    return

def createDirectoryIfNecessary(directory):
	if not os.path.exists(directory):
		os.makedirs(directory)
	return

def removeDirectory(directory):
    assert directory
    assert directory.startswith(dataDirectory)
    subprocess.call(["rm",
                     "-rf",
                     directory])
    return

def removeFileIfNecessary(file):
    if os.path.isfile(gcovOutputFileName):
        os.remove(gcovOutputFileName)
    return

#Xcode interaction methods

def xcodeBuildOperation(operation):
    assert operation
    return subprocess.call(["xcodebuild",
                            operation,
                            "-workspace",
                            "../WordPress.xcworkspace",
                            "-scheme",
                            "WordPress",
                            "-configuration",
                            "Debug",
                            "-destination",
                            "platform=" + simulatorPlatform,
                            "-derivedDataPath",
                            derivedDataDirectory,
                            "GCC_GENERATE_TEST_COVERAGE_FILES=YES",
                            "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES"])

def xcodeClean():
    return xcodeBuildOperation("clean")

def xcodeBuild():
    return xcodeBuildOperation("build")

def xcodeTest():
    return xcodeBuildOperation("test")

# Caching methods

def cacheAllGcdaFiles():
    allGcdaFilesPath = buildObjectsDirectory + allGcdaFiles
    copyFiles(allGcdaFilesPath, cacheDirectory)
    return

def cacheAllGcnoFiles():
    allGcnoFilesPath = buildObjectsDirectory + allGcnoFiles
    copyFiles(allGcnoFilesPath, cacheDirectory)
    return

# Core procedures

def createInitialDirectories():
    createDirectoryIfNecessary(dataDirectory)
    createDirectoryIfNecessary(cacheDirectory)
    createDirectoryIfNecessary(derivedDataDirectory)
    createDirectoryIfNecessary(gcovOutputDirectory)
    return

def generateGcdaAndGcnoFiles():
    if xcodeClean() != 0:
        sys.exit("Exit: the clean procedure failed.")
    
    if xcodeBuild() != 0:
        sys.exit("Exit: the build procedure failed.")
    
    if xcodeTest() != 0:
        sys.exit("Exit: the test procedure failed.")
    
    cacheAllGcdaFiles()
    cacheAllGcnoFiles()
    return

def parseGcdaAndGcnoFiles():
    
    return

def processGcdaAndGcnoFiles():
    
    removeFileIfNecessary(gcovOutputFileName)
    gcovOutputFile = open(gcovOutputFileName, "wb")
    
    sourceFilesPattern = cacheDirectory + allGcnoFiles
    
    for file in glob.glob(sourceFilesPattern):
        fileWithPath = "../../" + file
        
        command = ["gcov", fileWithPath]

        subprocess.call(command,
                        cwd = gcovOutputDirectory,
                        stdout = gcovOutputFile)
    return

# Main

def main(arguments):
    createInitialDirectories()

    generateGcdaAndGcnoFiles()
    processGcdaAndGcnoFiles()
    parseGcdaAndGcnoFiles()
    
    removeDirectory(derivedDataDirectory)
    return

#main(sys.argv)

createDirectoryIfNecessary(gcovOutputDirectory)
processGcdaAndGcnoFiles()
print("Done")









