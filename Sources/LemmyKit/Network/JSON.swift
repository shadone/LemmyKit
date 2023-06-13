//
// Copyright (c) 2020-2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Inspired by Lee Kah Seng https://swiftsenpai.com/swift/decode-dynamic-keys-json/
public enum JSON: Codable {
    case string(String)
    case number(Decimal)
    case object([String: JSON])
    case array([JSON])
    case bool(Bool)
    case null

    public var asObject: [String: JSON]? {
        if case let .object(value) = self {
            return value
        }
        return nil
    }

    public var isObject: Bool { asObject != nil }

    public var asArray: [JSON]? {
        if case let .array(value) = self {
            return value
        }
        return nil
    }

    public var isArray: Bool { asArray != nil }

    public var asString: String? {
        if case let .string(value) = self {
            return value
        }
        return nil
    }

    public var isString: Bool { asString != nil }

    public var asNumber: Decimal? {
        if case let .number(value) = self {
            return value
        }
        return nil
    }

    public var isNumber: Bool { asNumber != nil }

    public var asBool: Bool? {
        if case let .bool(value) = self {
            return value
        }
        return nil
    }

    public var isBool: Bool { asBool != nil }

    public var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }

    // Define DynamicCodingKeys type needed for creating
    // decoding container from JSONDecoder
    private struct DynamicCodingKeys: CodingKey {
        // Use for string-keyed dictionary
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        // Use for integer-keyed dictionary
        var intValue: Int?
        init?(intValue _: Int) {
            // We are not using this, thus just return nil
            nil
        }
    }

    public init(from decoder: Decoder) throws {
        if let keyedContainer = try? decoder.container(keyedBy: DynamicCodingKeys.self) {
            let objectValue = try keyedContainer.allKeys.reduce(into: [String: JSON]()) { result, key in
                let value = try keyedContainer.decode(JSON.self, forKey: key)
                result[key.stringValue] = value
            }
            self = .object(objectValue)
        } else if var unkeyedContainer = try? decoder.unkeyedContainer() {
            var arrayValue = [JSON]()
            if let count = unkeyedContainer.count {
                arrayValue.reserveCapacity(count)
            }
            while !unkeyedContainer.isAtEnd {
                let jsonValue = try unkeyedContainer.decode(JSON.self)
                arrayValue.append(jsonValue)
            }
            self = .array(arrayValue)
        } else {
            let singleValueContainer = try decoder.singleValueContainer()
            if let stringValue = try? singleValueContainer.decode(String.self) {
                self = .string(stringValue)
            } else if let numberValue = try? singleValueContainer.decode(Decimal.self) {
                self = .number(numberValue)
            } else if let boolValue = try? singleValueContainer.decode(Bool.self) {
                self = .bool(boolValue)
            } else if singleValueContainer.decodeNil() {
                self = .null
            } else {
                // what else could it be?
                preconditionFailure()
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .string(stringValue):
            var singleValueContainer = encoder.singleValueContainer()
            try singleValueContainer.encode(stringValue)
        case let .number(numberValue):
            var singleValueContainer = encoder.singleValueContainer()
            try singleValueContainer.encode(numberValue)
        case let .bool(boolValue):
            var singleValueContainer = encoder.singleValueContainer()
            try singleValueContainer.encode(boolValue)
        case .null:
            var singleValueContainer = encoder.singleValueContainer()
            try singleValueContainer.encodeNil()
        case let .object(objectValue):
            var singleValueContainer = encoder.singleValueContainer()
            try singleValueContainer.encode(objectValue)
        case let .array(arrayValue):
            var singleValueContainer = encoder.singleValueContainer()
            try singleValueContainer.encode(arrayValue)
        }
    }
}
