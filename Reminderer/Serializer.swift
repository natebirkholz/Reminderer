// Serializer.swift
// Created by Nate Birkholz

import Foundation

enum SerializationError: Error {
    case encodingError(String)
    case loadingError
    case decodingError(String)
}

struct Serializer {
    static let authorizationKey: String = "com.natebirkholz.reminderer.defaults.authorizationKey"
    static let dataKey: String = "com.natebirkholz.reminderer.defaults.savedDataKey"
    static var dataExists: Bool {
        let exists = UserDefaults.standard.object(forKey: Serializer.dataKey) != nil
        return exists
    }
    
    static func saveData(_ data: ReminderData) throws {
        do {
            let stringValue = try JSONEncoder().encode(data)
            UserDefaults.standard.set(stringValue, forKey: Serializer.dataKey)
        } catch let error {
            throw SerializationError.encodingError(error.localizedDescription)
        }
    }
    
    static func loadData() throws -> ReminderData? {
        if let data = UserDefaults.standard.data(forKey: Serializer.dataKey) {
            do {
                let reminder = try JSONDecoder().decode(ReminderData.self, from: data)
                return reminder
            } catch let error {
                throw SerializationError.decodingError(error.localizedDescription)
            }
        } else {
            throw SerializationError.loadingError
        }
    }
    
    static func getEnd() throws -> TimeInterval? {
        if let data = UserDefaults.standard.data(forKey: Serializer.dataKey) {
            do {
                let reminder = try JSONDecoder().decode(ReminderData.self, from: data)
                return reminder.endTime
            } catch let error {
                throw SerializationError.decodingError(error.localizedDescription)
            }
        } else {
            throw SerializationError.loadingError
        }
    }
    
    static func clear() {
        UserDefaults.standard.set(nil, forKey: Serializer.dataKey)
    }
}
