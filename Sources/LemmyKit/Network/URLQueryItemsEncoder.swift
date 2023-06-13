//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

//
// Inspired by https://github.com/elegantchaos/DictionaryCoding
//

enum URLQueryItemsEncoderError: Error {
    case unsupportedType(label: String?)
    case unimplemented
}

/// An extra wrapper to make our container (where we write the result) refcountable so we can pass it around.
class URLQueryItemsEncodingOutputOwner {
    var container: [URLQueryItem] = []

    func append(_ value: String?, forKey key: String) {
        container.append(
            URLQueryItem(
                name: key,
                value: value
            )
        )
    }
}

public class URLQueryItemsEncoder {
    public init() {
    }

    public func encode<T: Encodable>(_ value: T) throws -> [URLQueryItem] {
        let encoder = URLQueryItemsEncoderImpl()
        let result = try encoder.encode(value)
        switch result {
        case .singleValue:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "invalid top level value type",
                    underlyingError: nil)
            )

        case let .keyed(output):
            return output.container
        }
    }
}

#if canImport(Combine)
import Combine

extension URLQueryItemsEncoder: TopLevelEncoder {
    public typealias Output = [URLQueryItem]
}
#endif

class URLQueryItemsEncoderStorage {
    enum Container {
        case singleValue(String?)
        case keyed(URLQueryItemsEncodingOutputOwner)
    }

    var containers: [Container] = []

    func pushKeyedContainer() -> URLQueryItemsEncodingOutputOwner {
        let container = URLQueryItemsEncodingOutputOwner()
        containers.append(.keyed(container))
        return container
    }

    func pushSingleValueContainer(_ value: String?) {
        containers.append(.singleValue(value))
    }

    func popContainer() -> Container {
        assert(containers.count >= 1)
        return containers.popLast()!
    }
}

class URLQueryItemsEncoderImpl: Encoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey: Any] = [:]

    let storage = URLQueryItemsEncoderStorage()

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let output = storage.pushKeyedContainer()

        let container = URLQueryItemsKeyedEncodingContainer<Key>(
            encoder: self,
            codingPath: codingPath,
            output: output
        )
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("unimplemented")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        URLQueryItemsSingleValueEncodingContainer(
            encoder: self,
            codingPath: codingPath,
            storage: storage
        )
    }

    func encode<T: Encodable>(_ value: T) throws -> URLQueryItemsEncoderStorage.Container {
        try value.encode(to: self)
        return storage.popContainer()
    }

    func box(_ value: String) -> String? { value }
    func box(_ value: Double) -> String? { String(value) }
    func box(_ value: Float) -> String? { String(value) }
    func box(_ value: Int) -> String? { String(value) }
    func box(_ value: Int8) -> String? { String(value) }
    func box(_ value: Int16) -> String? { String(value) }
    func box(_ value: Int32) -> String? { String(value) }
    func box(_ value: Int64) -> String? { String(value) }
    func box(_ value: UInt) -> String? { String(value) }
    func box(_ value: UInt8) -> String? { String(value) }
    func box(_ value: UInt16) -> String? { String(value) }
    func box(_ value: UInt32) -> String? { String(value) }
    func box(_ value: UInt64) -> String? { String(value) }
}

struct URLQueryItemsSingleValueEncodingContainer: SingleValueEncodingContainer {
    var codingPath: [CodingKey]

    let encoder: URLQueryItemsEncoderImpl
    let storage: URLQueryItemsEncoderStorage

    init(
        encoder: URLQueryItemsEncoderImpl,
        codingPath: [CodingKey],
        storage: URLQueryItemsEncoderStorage
    ) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.storage = storage
    }

    func encodeNil() throws {
        storage.pushSingleValueContainer(nil)
    }

    func encode(_ value: Bool) throws {
        throw URLQueryItemsEncoderError.unimplemented
    }

    func encode(_ value: String) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: Double) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: Float) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: Int) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: Int8) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: Int16) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: Int32) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: Int64) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: UInt) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: UInt8) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: UInt16) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: UInt32) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode(_ value: UInt64) throws {
        storage.pushSingleValueContainer(encoder.box(value))
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        switch try encoder.encode(value) {
        case let .singleValue(value):
            storage.pushSingleValueContainer(value)

        case .keyed:
            fatalError("when we can get here?")
        }
    }
}

struct URLQueryItemsKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let encoder: URLQueryItemsEncoderImpl
    var codingPath: [CodingKey]
    let output: URLQueryItemsEncodingOutputOwner

    init(
        encoder: URLQueryItemsEncoderImpl,
        codingPath: [CodingKey],
        output: URLQueryItemsEncodingOutputOwner
    ) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.output = output
    }

    mutating func encodeNil(forKey key: Key) throws {
        output.append(nil, forKey: key.stringValue)
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        throw EncodingError.invalidValue(value, .init(
            codingPath: codingPath,
            debugDescription: "encoding 'Bool' value is not supported",
            underlyingError: nil
        ))
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        output.append(encoder.box(value), forKey: key.stringValue)
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
//        encoder.codingPath.append(key)
        switch try encoder.encode(value) {
        case let .singleValue(value):
            output.append(value, forKey: key.stringValue)

        case .keyed:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "cannot output complex object as a nested value",
                    underlyingError: nil
                )
            )
        }

    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        fatalError("unimplemented")
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError("unimplemented")
    }

    mutating func superEncoder() -> Encoder {
        fatalError("unimplemented")
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        fatalError("unimplemented")
    }
}
