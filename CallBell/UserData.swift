//
//  UserData.swift
//  CallBell
//
//  Created by Ian Ynda-Hummel on 9/2/19.
//  Copyright © 2019 Ian Ynda-Hummel. All rights reserved.
//

import Foundation

enum UserDataError: Error {
    case noStoredData
    case incompleteUserData
    case inconsistentUserData
    case failedReadingFromKeychain(OSStatus)
    case failedWritingToKeychain(OSStatus)
}

struct UserData {
    let username: String
    let token: Data
    
    static func existingUserData() throws -> UserData {
        guard let username = UserDefaults.standard.string(forKey: "username") else {
            throw UserDataError.noStoredData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.ianyh.CallBell",
            kSecAttrAccount as String: username,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        var itemRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &itemRef)
        
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw UserDataError.noStoredData
        default:
            throw UserDataError.failedReadingFromKeychain(status)
        }
        
        guard
            let item = itemRef as? [String: Any],
            let token = item[kSecValueData as String] as? Data,
            let keychainUsername = item[kSecAttrAccount as String] as? String
        else {
            throw UserDataError.incompleteUserData
        }
        
        guard keychainUsername == username else {
            throw UserDataError.inconsistentUserData
        }

        return UserData(username: username, token: token)
    }
    
    func save() throws {
        do {
            try delete()
        } catch (error: UserDataError.noStoredData) {
            // noop
        } catch {
            throw error
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.ianyh.CallBell",
            kSecAttrAccount as String: username,
            kSecValueData as String: token
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw UserDataError.failedWritingToKeychain(status)
        }
        
        UserDefaults.standard.set(username, forKey: "username")
    }
    
    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.ianyh.CallBell",
            kSecAttrAccount as String: username
        ]
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw UserDataError.noStoredData
        default:
            throw UserDataError.failedWritingToKeychain(status)
        }
        
        UserDefaults.standard.removeObject(forKey: "username")
    }
}
