import Foundation

// MARK: Xcodeproj entry point type

/// The main entry point type to parse `.xcodeproj` files
class Xcodeproj {
    let projectURL: URL // points to the "<projectDirectory>/<projectName>.xcodeproj/project.pbxproj" file
    private let pbxproj: PBXProjFile
    
    /// Semantic type for strings that correspond to an object' UUID in the `pbxproj` file
    typealias ObjectUUID = String
    
    /// Builds an `Xcodeproj` instance by parsing the `.xcodeproj` or `.pbxproj` file at the provided URL.
    init(url: URL) throws {
        projectURL = url.pathExtension == "xcodeproj" ? URL(fileURLWithPath: "project.pbxproj", relativeTo: url) : url
        let data = try Data(contentsOf: projectURL)
        let decoder = PropertyListDecoder()
        pbxproj = try decoder.decode(PBXProjFile.self, from: data)
    }
    
    /// An internal mapping listing the parent ObjectUUID for each ObjectUUID.
    /// - Built by recursing top-to-bottom in the various `PBXGroup` objects of the project to visit all the children objects,
    ///   and storing which parent object they belong to.
    /// - Used by the `resolveURL` method to find the real path of a `PBXReference`, as we need to navigate from the `PBXReference` object
    ///   up into the chain of parent `PBXGroup` containers to construct the successive relative paths of groups using `sourceTree = "<group>"`
    private lazy var referrers: [ObjectUUID: ObjectUUID] = {
        var referrers: [ObjectUUID: ObjectUUID] = [:]
        func recurseIfGroup(objectID: ObjectUUID) {
            guard let group = try? (self.pbxproj.object(id: objectID) as PBXGroup) else { return }
            for childID in group.children {
                referrers[childID] = objectID
                recurseIfGroup(objectID: childID)
            }
        }
        recurseIfGroup(objectID: self.pbxproj.rootProject.mainGroup)
        return referrers
    }()
}

// Convenience methods and properties
extension Xcodeproj {
    /// Builds an `Xcodeproj` instance by parsing the `.xcodeproj` or `pbxproj` file at the provided path
    convenience init(path: String) throws {
        try self.init(url: URL(fileURLWithPath: path))
    }
    
    /// The directory where the `.xcodeproj` resides.
    var projectDirectory: URL { projectURL.deletingLastPathComponent().deletingLastPathComponent() }
    /// The list of `PBXNativeTarget` targets in the project. Convenience getter for `PBXProjFile.nativeTargets`
    var nativeTargets: [PBXNativeTarget] { pbxproj.nativeTargets }
    /// The list of `PBXBuildFile` files a given `PBXNativeTarget` will build. Convenience getter for `PBXProjFile.buildFiles(for:)`
    func buildFiles(for target: PBXNativeTarget) -> [PBXBuildFile] { pbxproj.buildFiles(for: target) }
    
    /// Finds the full path / URL of a `PBXBuildFile` based on the groups it belongs to and their `sourceTree` attribute
    func resolveURL(to buildFile: PBXBuildFile) throws -> URL? {
        if let fileRefID = buildFile.fileRef, let fileRefObject = try? self.pbxproj.object(id: fileRefID) as PBXFileReference {
            return try resolveURL(objectUUID: fileRefID, object: fileRefObject)
        } else {
            // If the `PBXBuildFile` is pointing to `XCVersionGroup` (like `*.xcdatamodel`) and `PBXVariantGroup` (like `*.strings`)
            // (instead of a `PBXFileReference`), then in practice each file in the group's `children` will be built by the Build Phase.
            // In practice we can skip parsing those in our case and save some CPU, as we don't have a need to lint those non-source-code files.
            return nil // just skip those (but don't throw — those are valid use cases in any pbxproj, just ones we don't care about)
        }
    }
    
    /// Finds the full path / URL of a PBXReference (`PBXFileReference` of `PBXGroup`) based on the groups it belongs to and their `sourceTree` attribute
    private func resolveURL<T: PBXReference>(objectUUID: ObjectUUID, object: T) throws -> URL? {
        if objectUUID == self.pbxproj.rootProject.mainGroup { return URL(fileURLWithPath: ".", relativeTo: projectDirectory) }
        
        switch object.sourceTree {
        case .absolute:
            guard let path = object.path else { throw ProjectInconsistencyError.incorrectAbsolutePath(id: objectUUID) }
            return URL(fileURLWithPath: path)
        case .group:
            guard let parentUUID = referrers[objectUUID] else { throw ProjectInconsistencyError.orphanObject(id: objectUUID, object: object) }
            let parentGroup = try self.pbxproj.object(id: parentUUID) as PBXGroup
            guard let groupURL = try resolveURL(objectUUID: parentUUID, object: parentGroup) else { return nil }
            return object.path.map { groupURL.appendingPathComponent($0) } ?? groupURL
        case .projectRoot:
            return object.path.map { URL(fileURLWithPath: $0, relativeTo: projectDirectory) } ?? projectDirectory
        case .buildProductsDir, .devDir, .sdkDir:
            print("\(self.projectURL.path): warning: Reference \(objectUUID) is relative to \(object.sourceTree.rawValue), which is not supported by the linter")
            return nil
        }
    }
}

// MARK: - Implementation Details

/// "Parent" type for all the PBX... types of objects encountered in a pbxproj 
protocol PBXObject: Decodable {
    static var isa: String { get }
}
extension PBXObject {
    static var isa: String { String(describing: self) }
}

/// "Parent" type for PBXObjects referencing relative path information (`PBXFileReference`, `PBXGroup`)
protocol PBXReference: PBXObject {
    var name: String? { get }
    var path: String? { get }
    var sourceTree: Xcodeproj.SourceTree { get }
}

/// Types used to parse and decode the internals of a `*.xcodeproj/project.pbxproj` file
extension Xcodeproj {
    /// An error `thrown` when an inconsistency is found while parsing the `.pbxproj` file.
    enum ProjectInconsistencyError: Swift.Error, CustomStringConvertible {
        case objectNotFound(id: ObjectUUID)
        case unexpectedObjectType(id: ObjectUUID, expectedType: Any.Type, found: PBXObject)
        case incorrectAbsolutePath(id: ObjectUUID)
        case orphanObject(id: ObjectUUID, object: PBXObject)
        
        var description: String {
            switch self {
            case .objectNotFound(id: let id):
                return "Unable to find object with UUID `\(id)`"
            case .unexpectedObjectType(id: let id, expectedType: let expectedType, found: let found):
                return  "Object with UUID `\(id)` was expected to be of type \(expectedType) but found \(found) instead"
            case .incorrectAbsolutePath(id: let id):
                return "Object `\(id)` has `sourceTree = \(Xcodeproj.SourceTree.absolute)` but no `path`"
            case .orphanObject(id: let id, object: let object):
                return "Unable to find parent group of \(object) (`\(id)`) during file path resolution"
            }
        }
    }
    
    /// Type used to represent and decode the root object of a `.pbxproj` file.
    struct PBXProjFile: Decodable {
        let rootObject: ObjectUUID
        let objects: [String: PBXObjectWrapper]
        
        // Convenience methods
        
        /// Returns the `PBXObject` instance with the given `ObjectUUID`, by looking it up in the list of `objects` registered in the project.
        func object<T: PBXObject>(id: ObjectUUID) throws -> T {
            guard let wrapped = objects[id] else { throw ProjectInconsistencyError.objectNotFound(id: id) }
            guard let obj = wrapped.wrappedValue as? T else {
                throw ProjectInconsistencyError.unexpectedObjectType(id: id, expectedType: T.self, found: wrapped.wrappedValue)
            }
            return obj
        }
        
        /// Returns the `PBXObject` instance with the given `ObjectUUID`, by looking it up in the list of `objects` registered in the project.
        func object<T: PBXObject>(id: ObjectUUID) -> T? {
            try? object(id: id) as T
        }
        
        /// The `PBXProject` corresponding to the `rootObject` of the project file.
        var rootProject: PBXProject { try! object(id: rootObject) }
        
        /// The `PBXGroup` corresponding to the main groop serving as root for the whole hierarchy of files and groups in the project.
        var mainGroup: PBXGroup { try! object(id: rootProject.mainGroup) }
        
        /// The list of `PBXNativeTarget` targets found in the project.
        var nativeTargets: [PBXNativeTarget] { rootProject.targets.compactMap(object(id:)) }
        
        /// The list of `PBXBuildFile` build file references included in a given target.
        func buildFiles(for target: PBXNativeTarget) -> [PBXBuildFile] {
            guard let sourceBuildPhase: PBXSourcesBuildPhase = target.buildPhases.lazy.compactMap(object(id:)).first else { return [] }
            return sourceBuildPhase.files.compactMap(object(id:)) as [PBXBuildFile]
        }
    }
    
    /// One of the many `PBXObject` types encountered in the `.pbxproj` file format.
    /// Represents the root project object.
    struct PBXProject: PBXObject {
        let mainGroup: ObjectUUID
        let targets: [ObjectUUID]
    }
    
    /// One of the many `PBXObject` types encountered in the `.pbxproj` file format.
    /// Represents a native target (i.e. a target building an app, app extension, bundle...).
    /// - note: Does not represent other types of targets like `PBXAggregateTarget`, only native ones.
    struct PBXNativeTarget: PBXObject {
        let name: String
        let buildPhases: [ObjectUUID]
        let productType: String
        var knownProductType: ProductType? { ProductType(rawValue: productType) }
        
        enum ProductType: String, Decodable {
            case app = "com.apple.product-type.application"
            case appExtension = "com.apple.product-type.app-extension"
            case unitTest = "com.apple.product-type.bundle.unit-test"
            case uiTest = "com.apple.product-type.bundle.ui-testing"
            case framework = "com.apple.product-type.framework"
        }
    }
    
    /// One of the many `PBXObject` types encountered in the `.pbxproj` file format.
    /// Represents a "Compile Sources" build phase containing a list of files to compile.
    /// - note: Does not represent other types of Build Phases that could exist in the project, only "Compile Sources" one
    struct PBXSourcesBuildPhase: PBXObject {
        let files: [ObjectUUID]
    }
    
    /// One of the many `PBXObject` types encountered in the `.pbxproj` file format.
    /// Represents a single build file in a `PBXSourcesBuildPhase` build phase.
    struct PBXBuildFile: PBXObject {
        let fileRef: ObjectUUID?
    }
    
    /// This type is used to indicate what a file reference in the project is actually relative to
    enum SourceTree: String, Decodable, CustomStringConvertible {
        case absolute = "<absolute>"
        case group = "<group>"
        case projectRoot = "SOURCE_ROOT"
        case buildProductsDir = "BUILT_PRODUCTS_DIR"
        case devDir = "DEVELOPER_DIR"
        case sdkDir = "SDKROOT"
        var description: String { rawValue }
    }
    
    /// One of the many `PBXObject` types encountered in the `.pbxproj` file format.
    /// Represents a reference to a file contained in the project tree.
    struct PBXFileReference: PBXReference {
        let name: String?
        let path: String?
        let sourceTree: SourceTree
    }
    
    /// One of the many `PBXObject` types encountered in the `.pbxproj` file format.
    /// Represents a group (aka "folder") contained in the project tree.
    struct PBXGroup: PBXReference {
        let name: String?
        let path: String?
        let sourceTree: SourceTree
        let children: [ObjectUUID]
    }
    
    /// Fallback type for any unknown `PBXObject` type.
    struct UnknownPBXObject: PBXObject {
        let isa: String
    }
    
    /// Wrapper helper to decode any `PBXObject` based on the value of their `isa` field
    @propertyWrapper
    struct PBXObjectWrapper: Decodable, CustomDebugStringConvertible {
        let wrappedValue: PBXObject
        
        static let knownTypes: [PBXObject.Type] = [
            PBXProject.self,
            PBXGroup.self,
            PBXFileReference.self,
            PBXNativeTarget.self,
            PBXSourcesBuildPhase.self,
            PBXBuildFile.self
        ]
        
        init(from decoder: Decoder) throws {
            let untypedObject = try UnknownPBXObject(from: decoder)
            if let objectType = Self.knownTypes.first(where: { $0.isa == untypedObject.isa }) {
                self.wrappedValue = try objectType.init(from: decoder)
            } else {
                self.wrappedValue = untypedObject
            }
        }
        var debugDescription: String { String(describing: wrappedValue) }
    }
}



// MARK: - Lint method

/// The outcome of running our lint logic on a file
enum LintResult { case ok, skipped, violationsFound([(line: Int, col: Int)]) }

/// Lint a given file for usages of `NSLocalizedString` instead of `AppLocalizedString`
func lint(fileAt url: URL, targetName: String) throws -> LintResult {
    guard ["m", "swift"].contains(url.pathExtension) else { return .skipped }
    let content = try String(contentsOf: url)
    var lineNo = 0
    var violations: [(line: Int, col: Int)] = []
    content.enumerateLines { line, _ in
        lineNo += 1
        guard line.range(of: "\\s*//", options: .regularExpression) == nil else { return } // Skip commented lines
        guard let range = line.range(of: "NSLocalizedString") else { return }
        
        // Violation found, report it
        let colNo = line.distance(from: line.startIndex, to: range.lowerBound)
        let message = "Use `AppLocalizedString` instead of `NSLocalizedString` in source files that are used in the `\(targetName)` extension target. See paNNhX-nP-p2 for more info."
        print("\(url.path):\(lineNo):\(colNo): error: \(message)")
        violations.append((lineNo, colNo))
    }
    return violations.isEmpty ? .ok : .violationsFound(violations)
}



// MARK: - Main (Script Code entry point)

// 1st arg = project path
let args = CommandLine.arguments.dropFirst()
guard let projectPath = args.first, !projectPath.isEmpty else { print("You must provide the path to the xcodeproj as first argument."); exit(1) }
do {
    let project = try Xcodeproj(path: projectPath)
    
    // 2nd arg (optional) = name of target to lint
    let targetsToLint: [Xcodeproj.PBXNativeTarget]
    if let targetName = args.dropFirst().first, !targetName.isEmpty {
        print("Selected target: \(targetName)")
        targetsToLint = project.nativeTargets.filter { $0.name == targetName }
    } else {
        print("Linting all app extension targets")
        targetsToLint = project.nativeTargets.filter { $0.knownProductType == .appExtension }
    }
    
    // Lint each requested target
    var violationsFound = 0
    for target in targetsToLint {
        let buildFiles: [Xcodeproj.PBXBuildFile] = project.buildFiles(for: target)
        print("Linting the Build Files for \(target.name):")
        for buildFile in buildFiles {
            guard let fileURL = try project.resolveURL(to: buildFile) else { continue }
            let result = try lint(fileAt: fileURL.absoluteURL, targetName: target.name)
            print("  - \(fileURL.relativePath) [\(result)]")
            if case .violationsFound(let list) = result { violationsFound += list.count }
        }
    }
    print("Done! \(violationsFound) violation(s) found.")
    exit(violationsFound > 0 ? 1 : 0)
} catch let error {
    print("\(projectPath): error: Error while parsing the project file \(projectPath): \(error.localizedDescription)")
    exit(2)
}
