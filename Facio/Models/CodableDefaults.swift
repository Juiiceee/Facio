import Foundation

extension KeyedDecodingContainer {
    func decodeOrDefault<T: Decodable>(_ type: T.Type, forKey key: Key, default defaultValue: @autoclosure () -> T) throws -> T {
        guard contains(key) else {
            return defaultValue()
        }

        if try decodeNil(forKey: key) {
            return defaultValue()
        }

        return try decode(type, forKey: key)
    }
}
