#!/usr/bin/env swift

import Foundation

let fileManager = FileManager.default
let cwd = fileManager.currentDirectoryPath
let script = CommandLine.arguments[0]

let base = cwd
let projectDir = base.appending("/WordPress")
let resources = projectDir.appending("/Resources")
let frameworkRoots = [
    "WordPressTodayWidget",
    "WordPressShareExtension"
    ].map({ projectDir.appending("/\($0)") })

guard fileManager.fileExists(atPath: projectDir) else {
    print("Must run script from project root folder")
    exit(1)
}


func projectLanguages() -> [String] {
    return (try? fileManager.contentsOfDirectory(atPath: resources)
        .filter({ $0.hasSuffix(".lproj") })
        .map({ $0.replacingOccurrences(of: ".lproj", with: "") })
        .filter({ $0 != "en" })
        ) ?? []
}

func readStrings(path: String) -> [String: String] {
    do {
        let sourceData = try Data(contentsOf: URL(fileURLWithPath: path))
        let source = try PropertyListSerialization.propertyList(from: sourceData, options: [], format: nil) as! [String: String]
        return source
    } catch {
        print("Error reading \(path): \(error)")
        return [:]
    }
}

func sourceStrings(framework: String) -> [String: String] {
    let sourcePath = framework.appending("/Base.lproj/Localizable.strings")
    return readStrings(path: sourcePath)
}

func readProjectTranslations(for language: String) -> [String: String] {
    let path = resources.appending("/\(language).lproj/Localizable.strings")
    return readStrings(path: path)
}

func writeTranslations(_ translations: [String: String], language: String, framework: String) {
    let frameworkName = (framework as NSString).lastPathComponent
    let languageDir = framework.appending("/\(language).lproj")
    let stringsPath = languageDir.appending("/Localizable.strings")
    do {
        try fileManager.createDirectory(atPath: languageDir, withIntermediateDirectories: true, attributes: nil)
        let data = try PropertyListSerialization.data(fromPropertyList: translations, format: .binary, options: 0)
        if !fileManager.fileExists(atPath: stringsPath) {
            print("New \(language) translation for \(frameworkName). Please add it to the Xcode project")
        }
        try data.write(to: URL(fileURLWithPath: stringsPath))
    } catch {
        print("Error writing translation to \(stringsPath): \(error)")
    }
}

for framework in frameworkRoots {
    let name = (framework as NSString).lastPathComponent
    let sources = sourceStrings(framework: framework)
    var languagesAdded = [String]()
    for language in projectLanguages() {
        let projectTranslations = readProjectTranslations(for: language)
        var translations = sources
        for (key, _) in sources {
            translations[key] = projectTranslations[key]
        }

        guard !translations.isEmpty else {
            continue
        }
        languagesAdded.append(language)

        writeTranslations(translations, language: language, framework: framework)
    }
    if languagesAdded.isEmpty {
        print("No translations extracted to \(name)")
    } else {
        print("Extracted translations to \(name) for: " + languagesAdded.joined(separator: " "))
    }
}
