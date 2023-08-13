import XCTest
import IndexStoreDB

@testable import Analyzer

class ASTParsingTests: XCTestCase {

    func testParseInstanceMethod() throws {
        let support = TestSupport()
        let code = """
            func foo() {
              let result = [1, 2, 3].map { $0.description }
              print(result)
            }
            """
        let navigator = try support.navigator(forSourceCode: code)

        // the specialized `map` function call in the code
        let mapFunction = "([Int]) -> ((Int) throws -> String) throws -> [String]"

        // Verify the map function signature is correct, not made up.
        let location = SymbolLocation(path: support.sourceFile.pathString, moduleName: "", line: 2, utf8Column: 27)
        let types = try navigator.expressions(at: location).map { $0.type }
        XCTAssertTrue(types.contains(mapFunction))

        let arg0 = try ASTHelper.parseFunctionParameterType(at: 0, function: mapFunction)
        let arg1 = try ASTHelper.parseFunctionParameterType(at: 0, function: ASTHelper.parseFunctionReturnType(function: mapFunction))
        let ret = try ASTHelper.parseFunctionReturnType(function: ASTHelper.parseFunctionReturnType(function: mapFunction))

        XCTAssertEqual(arg0, "[Int]")
        XCTAssertEqual(arg1, "(Int) throws -> String")
        XCTAssertEqual(ret, "[String]")

        let noThirdParameter = expectation(description: "There is no third parameter")
        do {
            _ = try ASTHelper.parseFunctionParameterType(at: 2, function: mapFunction)
        } catch {
            noThirdParameter.fulfill()
        }
        wait(for: [noThirdParameter], timeout: 0.1)
    }

    func testParseGlobalFunction() throws {
        let support = TestSupport()
        let code = """
            func foo(array: [Int], multiplier: Int) -> String {
              fatalError("boom")
            }
            func bar() {
              foo(array: [1, 2, 3], multiplier: 2)
            }
            """
        let navigator = try support.navigator(forSourceCode: code)

        let fooFunction = "([Int], Int) -> String"

        // Verify the foo function signature is correct, not made up.
        let location = SymbolLocation(path: support.sourceFile.pathString, moduleName: "", line: 5, utf8Column: 4)
        let types = try navigator.expressions(at: location).map { $0.type }
        XCTAssertTrue(types.contains(fooFunction))

        try XCTAssertEqual(ASTHelper.parseFunctionParameterType(at: 0, function: fooFunction), "[Int]")
        try XCTAssertEqual(ASTHelper.parseFunctionParameterType(at: 1, function: fooFunction), "Int")
        try XCTAssertEqual(ASTHelper.parseFunctionReturnType(function: fooFunction), "String")

        let noThirdParameter = expectation(description: "There is no third parameter")
        do {
            _ = try ASTHelper.parseFunctionParameterType(at: 3, function: fooFunction)
        } catch {
            noThirdParameter.fulfill()
        }
        wait(for: [noThirdParameter], timeout: 0.1)
    }

    func testParseStaticFunction() throws {
        let support = TestSupport()
        let code = """
            enum Foo {
              static func bar(array: [Int], multiplier: Int) -> String {
                fatalError("boom")
              }
            }
            func baz() {
              Foo.bar(array: [1, 2, 3], multiplier: 2)
            }
            """
        let navigator = try support.navigator(forSourceCode: code)

        let barFunction = "([Int], Int) -> String"

        // Verify the bar function signature is correct, not made up.
        let location = SymbolLocation(path: support.sourceFile.pathString, moduleName: "", line: 7, utf8Column: 8)
        let types = try navigator.expressions(at: location).map { $0.type }
        XCTAssertTrue(types.contains(barFunction))

        try XCTAssertEqual(ASTHelper.parseFunctionParameterType(at: 0, function: barFunction), "[Int]")
        try XCTAssertEqual(ASTHelper.parseFunctionParameterType(at: 1, function: barFunction), "Int")
        try XCTAssertEqual(ASTHelper.parseFunctionReturnType(function: barFunction), "String")

        let noThirdParameter = expectation(description: "There is no third parameter")
        do {
            _ = try ASTHelper.parseFunctionParameterType(at: 3, function: barFunction)
        } catch {
            noThirdParameter.fulfill()
        }
        wait(for: [noThirdParameter], timeout: 0.1)
    }

}
