import Foundation
import OSLog

/// A UserDefaults key paired with its PRD default, so the default is declared exactly once.
struct SettingKey<Value> {
    let name: String
    let defaultValue: Value
}

extension UserDefaults {
    func value(for key: SettingKey<Bool>) -> Bool {
        object(forKey: key.name) as? Bool ?? key.defaultValue
    }

    func set(_ value: Bool, for key: SettingKey<Bool>) {
        set(value, forKey: key.name)
    }

    func value(for key: SettingKey<Int>) -> Int {
        object(forKey: key.name) as? Int ?? key.defaultValue
    }

    func set(_ value: Int, for key: SettingKey<Int>) {
        set(value, forKey: key.name)
    }

    func value(for key: SettingKey<String>) -> String {
        string(forKey: key.name) ?? key.defaultValue
    }

    func set(_ value: String, for key: SettingKey<String>) {
        set(value, forKey: key.name)
    }

    func value<Value: RawRepresentable>(for key: SettingKey<Value>) -> Value where Value.RawValue == String {
        string(forKey: key.name).flatMap(Value.init(rawValue:)) ?? key.defaultValue
    }

    func set<Value: RawRepresentable>(_ value: Value, for key: SettingKey<Value>) where Value.RawValue == String {
        set(value.rawValue, forKey: key.name)
    }

    /// Collections and optionals are stored as JSON. A value that no longer decodes (e.g. after a schema change)
    /// falls back to the default instead of crashing, and the reason is logged.
    func decodedValue<Value: Codable>(for key: SettingKey<Value>) -> Value {
        guard let data = data(forKey: key.name) else { return key.defaultValue }
        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            Logger.settings.error("Resetting \(key.name, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return key.defaultValue
        }
    }

    func setEncoded<Value: Codable>(_ value: Value, for key: SettingKey<Value>) {
        do {
            set(try JSONEncoder().encode(value), forKey: key.name)
        } catch {
            Logger.settings.error("Could not save \(key.name, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
}
