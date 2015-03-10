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
finalReport = dataDirectory + "/FinalReport"

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
    createDirectoryIfNecessary(finalReport)
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

# Parsing the data

def parseCoverageData(line):
    header = "Lines executed:"
    
    assert line.startswith(header)
    
    line = line[len(header):]
    lineComponents = line.split(" of ")
    
    percentage = float(lineComponents[0].strip("%")) / 100
    totalLines = int(lineComponents[1])
    linesExecuted = int(round(percentage * totalLines))
    
    return str(percentage), str(totalLines), str(linesExecuted)

def parseFilePath(line):
    assert line.startswith("File '")

    splitStrings = line.split("'")
    path = splitStrings[1]

    parentDir = os.path.dirname(os.getcwd())
    
    if path.startswith(parentDir):
        path = path[len(parentDir):]
    else:
        path = None

    return path

def parseGcovFiles():
    gcovFile = open(gcovOutputFileName, "r")
    csvFile = open(finalReport + "/report.csv", "w")
    
    lineNumber = 0
    skipNext = False
    
    csvFile.write("File, Covered Lines, Total Lines, Coverage Percentage\r\n")
    
    for line in gcovFile:
        lineOffset = lineNumber % 4
        
        if lineOffset == 0:
            filePath = parseFilePath(line)
        
            if filePath:
                csvFile.write(filePath + ",")
            else:
                skipNext = True
        
        elif lineOffset == 1:
            if not skipNext:
                percentage, totalLines, linesExecuted = parseCoverageData(line)
                
                csvFile.write(linesExecuted + "," + totalLines + "," + percentage + "\r\n")
            else:
                skipNext = False

        lineNumber += 1

    return

# Main

def main(arguments):
    createInitialDirectories()

    generateGcdaAndGcnoFiles()
    processGcdaAndGcnoFiles()
    parseGcovFiles()
    
    removeDirectory(derivedDataDirectory)
    return

main(sys.argv)
print("Done.")









