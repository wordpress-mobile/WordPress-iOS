import glob
import os
import shutil
import subprocess
import StringIO
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

# Data conversion methods

def IsInt(i):
    try:
        int(i)
        return True
    except ValueError:
        return False

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

# Xcode interaction methods

def xcodeBuildOperation(operation, simulator):
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
                            "platform=" + simulator,
                            "-derivedDataPath",
                            derivedDataDirectory,
                            "GCC_GENERATE_TEST_COVERAGE_FILES=YES",
                            "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES"])

def xcodeClean(simulator):
    return xcodeBuildOperation("clean", simulator)

def xcodeBuild(simulator):
    return xcodeBuildOperation("build", simulator)

def xcodeTest(simulator):
    return xcodeBuildOperation("test", simulator)

# Simulator interaction methods

def simulatorEraseContentAndSettings(simulator):
    
    deviceID = simulator[2]
    
    command = ["xcrun",
               "simctl",
               "erase",
               deviceID]
    result = subprocess.call(command)
    
    if (result != 0):
        exit("Error: subprocess xcrun failed to erase content and settings for device ID: " + deviceID + ".")
    
    return

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

def generateGcdaAndGcnoFiles(simulator):
    if xcodeClean(simulator) != 0:
        sys.exit("Exit: the clean procedure failed.")
    
    if xcodeBuild(simulator) != 0:
        sys.exit("Exit: the build procedure failed.")
    
    if xcodeTest(simulator) != 0:
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

# Selecting a Simulator

def availableSimulators():
    command = ["xcrun",
               "simctl",
               "list",
               "devices"]

    process = subprocess.Popen(command,
                               stdout = subprocess.PIPE)
    out, err = process.communicate()

    simulators = availableSimulatorsFromXcrunOutput(out)

    return simulators

def availableSimulatorsFromXcrunOutput(output):
    outStringIO = StringIO.StringIO(output)
    
    iOSVersion = ""
    simulators = []
    
    line = outStringIO.readline()
    line = line.strip("\r").strip("\n")
    
    assert line == "== Devices =="

    while True:
        line = outStringIO.readline()
        line = line.strip("\r").strip("\n")
        
        if line.startswith("-- "):
            iOSVersion = line.strip("-- iOS ").strip(" --")
        elif line:
            name = line[4:line.rfind(" (", 0, line.rfind(" ("))]
            id = line[line.rfind("(", 0, line.rfind("(")) + 1:line.rfind(")", 0, line.rfind(")"))]
            simulators.append([iOSVersion, name, id])
        else:
            break

    return simulators

def askUserToSelectSimulator(simulators):
    option = ""
    
    while True:
        print "\r\nPlease select a simulator:\r\n"
        
        for idx, simulator in enumerate(simulators):
            print str(idx) + " - iOS Version: " + simulator[0] + " - Name: " + simulator[1] + " - ID: " + simulator[2]
        print "x - Exit\r\n"
        
        option = raw_input(": ")
        
        if option == "x":
            exit(0)
        elif IsInt(option):
            intOption = int(option)
            if intOption >= 0 and intOption < len(simulators):
                break

        print "Invalid option!"
    return int(option)

def selectSimulator():
    result = None
    simulators = availableSimulators()
    
    if (len(simulators) > 0):
        option = askUserToSelectSimulator(simulators)
        
        assert option >= 0 and option < len(simulators)
        
        simulatorEraseContentAndSettings(simulators[option])
        
        result = "iOS Simulator,name=" + simulators[option][1] + ",OS=" + simulators[option][0]
        print "Selected simulator: " + result

    return result

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

    simulator = selectSimulator()
    
    generateGcdaAndGcnoFiles(simulator)
    processGcdaAndGcnoFiles()
    parseGcovFiles()
    
    removeDirectory(derivedDataDirectory)
    return

main(sys.argv)
print("Done.")









