//
//  KeychainManager.swift
//  JChat
//

import Foundation
import Security

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidStatus(OSStatus)
    case conversionError
}

final class KeychainManager: @unchecked Sendable {
    static let shared = KeychainManager()

    private let service = "com.josh.jchat"
    private let apiKeyAccount = "openrouter-api-key"

    // Use kSecAttrSynchronizable to enable iCloud Keychain syncing
    // Set to false for local-only, true for iCloud-synced
    // TODO: - I want EVERYTHING to be synced via the user's iCloud Keychain and Storage if possible without having a paid Developer Account for CloudKit.
    private let synchronizable = false

    // TODO: - ENSURE ROBUST ENCRYPTION OF API KEY. DO NOT LEAK THIS KEY UNDER ANY CIRCUMSTANCES. LEAKING THIS KEY OR USING WEAK ENCRYPTION/NO ENCRYPTION IS A BLATANT SECURITY VIOLATION AND NOT ACCEPTABLE.
    func saveAPIKey(_ key: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.conversionError
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: synchronizable,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: apiKeyAccount,
            ]

            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data,
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.invalidStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.invalidStatus(status)
        }
    }

    func loadAPIKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.invalidStatus(status)
        }

        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.conversionError
        }

        return key
    }

    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.invalidStatus(status)
        }
    }
}
