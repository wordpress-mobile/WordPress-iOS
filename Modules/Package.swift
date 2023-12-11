// swift-tools-version: 5.8

import PackageDescription

let package = Package(name: "Modules")
    .with([
        LibraryModule(name: "JetpackStatsWidgetsCore")
    ])

// MARK: -

extension Package {

    func with(_ libraries: [LibraryModule]) -> Package {
        return Package(
            name: name,
            products: libraries.map { $0.product },
            targets: libraries.flatMap { $0.targets }
        )
    }
}

/// Abstraction to describe the a standard library sub-package.
/// That is, a library with both a production and test target, each located in the folder expected by SPM, <root>/Sources/LibraryName and <root>/Tests/LibrayNameTests respectively.
///
/// To describe such library, one can simply instantiate `LibrayModule(name: "LibraryName")`.
struct LibraryModule {

    enum UnitTests {
        case none
        case some([Target.Dependency] = [])
    }

    /// The name of the library. Example: FeatureXBusinessLogic.
    let name: String

    /// The production code dependencies, if any.
    let dependencies: [Target.Dependency]

    /// The library unit tests configuration
    let unitTests: UnitTests

    var product: Product {
        .library(name: name, targets: [name])
    }

    var target: Target {
        .target(name: name, dependencies: dependencies)
    }

    var testTarget: Target? {
        switch unitTests {
        case .none:
            return .none
        case .some(let dependencies):
            return .testTarget(
                name: "\(name)Tests",
                dependencies: [.target(name: target.name)] + dependencies
            )
        }
    }

    var targets: [Target] {
        [target, testTarget].compactMap { $0 }
    }

    init(
        name: String,
        dependencies: [Target.Dependency] = [],
        unitTests: UnitTests = .some([])
    ) {
        self.name = name
        self.dependencies = dependencies
        self.unitTests = unitTests
    }
}

