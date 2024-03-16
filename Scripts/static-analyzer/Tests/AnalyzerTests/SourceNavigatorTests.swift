import XCTest
import IndexStoreDB

@testable import Analyzer

class SourceNavigatorTests: XCTestCase {

    func testLookupSymbols() throws {
        let support = TestSupport()

        let code = """
            import Foundation
            func foo<T>(a: Int, b: Bool, c: String, d: T) -> NSArray {
                fatalError("Unimplemented")
            }
            func bar() {
                _ = foo(a: 0, b: false, c: "", d: 1.0)
            }
            """
        let navigator = try support.navigator(forSourceCode: code)

        let symbols = navigator.lookupSymbols(name: "foo(a:b:c:d:)", in: support.sourceFile)
        XCTAssertEqual(symbols.count, 1)

        let symbol = try XCTUnwrap(symbols.first)
        let callSites = navigator.callSites(of: USR(rawValue: symbol.usr)!)
        XCTAssertEqual(callSites.count, 1)
    }

    func testLookupExpression() throws {
        let support = TestSupport()

        let code = """
            import Foundation
            func foo<T>(a: Int, b: Bool, c: String, d: T) -> NSArray {
                fatalError("Unimplemented")
            }
            func bar() {
                _ = foo(a: 0, b: false, c: "", d: 1.0)
            }
            """
        let navigator = try support.navigator(forSourceCode: code)

        let symbols = navigator.lookupSymbols(name: "foo(a:b:c:d:)", in: support.sourceFile)
        XCTAssertEqual(symbols.count, 1)

        let symbol = try XCTUnwrap(symbols.first)
        let callSites = navigator.callSites(of: USR(rawValue: symbol.usr)!)
        XCTAssertEqual(callSites.count, 1)

        let location = SymbolLocation(path: support.sourceFile.pathString, moduleName: "", line: 6, utf8Column: 10)
        let expressions = try navigator.expressions(at: location).map { $0.type }
        XCTAssertTrue(expressions.contains("(Int, Bool, String, Double) -> NSArray"))
    }

    func testLookupInstanceMethod() throws {
        let support = TestSupport()
        let code = """
            protocol ProtocolA {
                func map(_ transform: Any) -> Any
            }
            func foo(p: ProtocolA) {
              _ = p.map(0)
            }
            func bar(p: ProtocolA) {
              _ = p.map("")
            }
            func baz() {
              _ = [1, 2, 3].map { $0 * 2}
            }
            """
        let navigator = try support.navigator(forSourceCode: code)

        let proto = try navigator.resolveType(named: "ProtocolA")

        let mapFuncs = navigator.lookupInstanceMethods(named: "map(_:)", of: proto)
        XCTAssertEqual(mapFuncs.count, 1)
        let mapFunc = try XCTUnwrap(mapFuncs.first)

        let mapCallSites = navigator.callSites(of: mapFunc)
        XCTAssertEqual(mapCallSites.count, 2)
        let lines = mapCallSites.map { $0.line }
        XCTAssertEqual(Set(lines), [5, 8])
    }

    func testLookupInstanceMethod_InComplexTypes() throws {
        let support = TestSupport()
        let code = """
            func foo() {
              _ = [1, 2, 3].map { $0 * 2}
            }
            """
        let navigator = try support.navigator(forSourceCode: code)
        let arrayType = try navigator.resolveType(named: "Array")
        let mapFuncs = navigator.lookupInstanceMethods(named: "map(_:)", of: arrayType)
        XCTAssertFalse(mapFuncs.isEmpty)

        let callSites = mapFuncs.flatMap { navigator.callSites(of: $0) }
        XCTAssertEqual(callSites.count, 1)
    }

    func testLookupInstanceMethod_UnusedFunction() throws {
        let support = TestSupport()
        let code = """
            func foo() {
              _ = [1, 2, 3].map { $0 * 2}
            }
            """
        let navigator = try support.navigator(forSourceCode: code)
        let arrayType = try navigator.resolveType(named: "Array")
        let unusedFuncs = navigator.lookupInstanceMethods(named: "flatMap(_:)", of: arrayType)
        XCTAssertTrue(unusedFuncs.isEmpty)
    }

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

        try XCTAssertTrue(navigator.isInheritance(subclass: "Class2", superclass: "Class1"))
        try XCTAssertTrue(navigator.isInheritance(subclass: "Class3", superclass: "Class1"))
        try XCTAssertFalse(navigator.isInheritance(subclass: "Class2", superclass: "Class3"))
        try XCTAssertFalse(navigator.isInheritance(subclass: "Class2", superclass: "NSObject"))

    }

}
