import XCTest
@testable import LemmyKit

final class URLQueryItemsEncoderTests: XCTestCase {
    func testString() throws {
        struct Params: Encodable {
            let stringParam: String
        }

        let params = Params(
            stringParam: "i-am-string"
        )
        let result = try URLQueryItemsEncoder().encode(params)
        XCTAssertEqual(
            result,
            [
                URLQueryItem(name: "stringParam", value: "i-am-string"),
            ]
        )
    }

    func testInts() throws {
        struct Params: Encodable {
            let intParam: Int
            let int8Param: Int8
            let uintParam: UInt
            let uint8Param: UInt8
        }

        let params = Params(
            intParam: 123456,
            int8Param: 44,
            uintParam: 78900,
            uint8Param: 55
        )
        let result = try URLQueryItemsEncoder().encode(params)
        XCTAssertEqual(
            result,
            [
                URLQueryItem(name: "intParam", value: "123456"),
                URLQueryItem(name: "int8Param", value: "44"),
                URLQueryItem(name: "uintParam", value: "78900"),
                URLQueryItem(name: "uint8Param", value: "55"),
            ]
        )
    }

    func testFloats() throws {
        struct Params: Encodable {
            let floatParam: Float
            let doubleParam: Double
        }

        let params = Params(
            floatParam: 12345678,
            doubleParam: 1234567890
        )
        let result = try URLQueryItemsEncoder().encode(params)
        XCTAssertEqual(
            result,
            [
                URLQueryItem(name: "floatParam", value: "12345678.0"),
                URLQueryItem(name: "doubleParam", value: "1234567890.0"),
            ]
        )
    }

    func testEnum() throws {
        enum IAmEnum: String, Encodable {
            case one
            case two
            case three
        }
        struct Params: Encodable {
            let enumParam: IAmEnum
        }

        let params = Params(
            enumParam: .two
        )
        let result = try URLQueryItemsEncoder().encode(params)
        XCTAssertEqual(
            result,
            [
                URLQueryItem(name: "enumParam", value: "two")
            ]
        )
    }

    func testInvalidTopLevel_singleValue() throws {
        func assertInvalidValue(
            expectedDebugDescription: String
        ) -> (Error) -> Void {
            return { error in
                switch error as! EncodingError {
                case let .invalidValue(_, context):
                    XCTAssertEqual(context.debugDescription, expectedDebugDescription)

                default:
                    XCTFail()
                }
            }
        }

        XCTAssertThrowsError(
            try URLQueryItemsEncoder().encode("string-value"),
            "",
            assertInvalidValue(expectedDebugDescription: "invalid top level value type")
        )

        XCTAssertThrowsError(
            try URLQueryItemsEncoder().encode(42),
            "",
            assertInvalidValue(expectedDebugDescription: "invalid top level value type")
        )

        // TODO: This triggers fatalError, leaving out for now...
        // enum IAmEnum: Encodable {
        //     case one
        // }
        // XCTAssertThrowsError(
        //     try URLQueryItemsEncoder().encode(IAmEnum.one),
        //     "",
        //     assertInvalidValue(expectedDebugDescription: "invalid top level value type")
        // )
    }

    func testInvalidTopLevel_unkeyed() throws {
        // TODO: This triggers fatalError, leaving out for now...
        // XCTAssertThrowsError(
        //     try URLQueryItemsEncoder().encode(["one", "two"])
        // ) { error in
        //     switch error as! EncodingError {
        //     case let .invalidValue(_, context):
        //         XCTAssertEqual(context.debugDescription, "invalid top level value type")

        //     default:
        //         XCTFail()
        //     }
        // }
    }

    func testSuper() throws {
        class Base: Encodable {
            let value1: String

            init(value1: String) {
                self.value1 = value1
            }
        }

        class Child: Base {
            let value2: String

            enum CodingKeys: CodingKey {
                case value2
            }

            init(value1: String, value2: String) {
                self.value2 = value2

                super.init(value1: value1)
            }

            override func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(value2, forKey: .value2)
                try super.encode(to: encoder)
            }
        }

        let value = Child(
            value1: "i-am-value1",
            value2: "i-am-value2"
        )

        let result = try URLQueryItemsEncoder().encode(value)
        XCTExpectFailure("This is not implemented correctly yet")
        XCTAssertEqual(
            result,
            [
                URLQueryItem(name: "value1", value: "i-am-value1"),
                URLQueryItem(name: "value2", value: "i-am-value2"),
            ]
        )
    }
}
