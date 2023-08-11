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
        let expression = try navigator.typecheck(location: location)
        XCTAssertEqual(expression, "(Int, Bool, String, Double) -> NSArray")
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
            """
        let navigator = try support.navigator(forSourceCode: code)

        let types = navigator.lookupSymbols(name: "ProtocolA", kind: .protocol)
        XCTAssertEqual(types.count, 1)
        let proto = try XCTUnwrap(types.first)

        let mapFuncs = navigator.lookupInstanceMethods(named: "map(_:)", of: proto)
        XCTAssertEqual(mapFuncs.count, 1)
        let mapFunc = try XCTUnwrap(mapFuncs.first)

        let mapCallSites = navigator.callSites(of: mapFunc)
        XCTAssertEqual(mapCallSites.count, 2)
        let lines = mapCallSites.map { $0.line }
        XCTAssertEqual(Set(lines), [5, 8])
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

        let fooTypes = navigator.lookupSymbols(name: "Foo", kind: .struct)
        XCTAssertEqual(fooTypes.count, 1)
        let fooType = try XCTUnwrap(fooTypes.first)

        let protocols = navigator.conformedProtocols(of: fooType).map { $0.name }
        XCTAssertTrue(protocols.contains("ProtocolA"))
        XCTAssertTrue(protocols.contains("ProtocolB"))
        XCTAssertTrue(protocols.contains("ProtocolC"))
        XCTAssertTrue(protocols.contains("ProtocolD"))
        XCTAssertTrue(protocols.contains("ProtocolE"))
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
