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
