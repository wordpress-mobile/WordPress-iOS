import XCTest
import IndexStoreDB

@testable import Analyzer

class TypeCheckTests: XCTestCase {

    func testLookupConformance() throws {
        let support = TestSupport()
        let code = """
            protocol ProtocolA {}
            protocol ProtocolB {}
            protocol ProtocolC {}
            protocol ProtocolD {}
            protocol ProtocolE: ProtocolD {}
            struct Foo: ProtocolA, ProtocolB {}
            extension Foo: ProtocolC, ProtocolE {}
            """
        let navigator = try support.navigator(forSourceCode: code)

        let fooType = try navigator.resolveType(named: "Foo")

        let protocols = navigator.conformedProtocols(of: fooType).map { $0.name }
        XCTAssertTrue(protocols.contains("ProtocolA"))
        XCTAssertTrue(protocols.contains("ProtocolB"))
        XCTAssertTrue(protocols.contains("ProtocolC"))
        XCTAssertTrue(protocols.contains("ProtocolD"))
        XCTAssertTrue(protocols.contains("ProtocolE"))
    }

    func testTypenameResolution() throws {
        let support = TestSupport()
        let code = """
            class Class1 {
                struct Inner {}
            }
            class Class2: Class1 {
                struct Inner {}
            }
            class Class3: Class2 {}
            """
        let navigator = try support.navigator(forSourceCode: code)

        try XCTAssertEqual(navigator.resolveType(named: "Class1").name, "Class1")
        XCTAssertNil(try? navigator.resolveType(named: "Inner"))

        let inner1 = try navigator.resolveType(named: "Class1.Inner")
        let inner2 = try navigator.resolveType(named: "Class2.Inner")
        XCTAssertEqual(navigator.fullTypename(of: inner1), "Class1.Inner")
        XCTAssertEqual(navigator.fullTypename(of: inner2), "Class2.Inner")
    }

    func testExpressions() throws {
        let support = TestSupport()
        let code = """
            func foo() {
              let result = [1, 2, 3].map { $0 * 2 }
              print(result)
            }
            """
        let navigator = try support.navigator(forSourceCode: code)

        // The location at the `map` call.
        let location = SymbolLocation(path: support.sourceFile.pathString, moduleName: "", line: 2, utf8Column: 27)
        let types = try navigator.expressions(at: location).map { $0.type }
        XCTAssertTrue(types.contains("[Int]"))
        XCTAssertTrue(types.contains("([Int]) -> ((Int) throws -> Int) throws -> [Int]"))
    }

    func testInheritenceCheck() throws {
        let support = TestSupport()
        let code = """
            import Foundation
            class Class1 {}
            class Class2: Class1 {}
            class Class3: Class2 {}
            """
        let navigator = try support.navigator(forSourceCode: code)

        try XCTAssertTrue(navigator.isInheritence(subclass: "Class2", superclass: "Class1"))
        try XCTAssertTrue(navigator.isInheritence(subclass: "Class3", superclass: "Class1"))
        try XCTAssertFalse(navigator.isInheritence(subclass: "Class2", superclass: "Class3"))
        try XCTAssertFalse(navigator.isInheritence(subclass: "Class2", superclass: "NSObject"))

    }

}
