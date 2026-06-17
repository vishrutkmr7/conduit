import Foundation
import Security

//
//  ConduitKeychain.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

nonisolated enum ConduitKeychain {
  private static let service = "app.bitrig.vishrutjha.conduit.credentials"

  static func credential(for account: String) -> String? {
    var query: [String: Any] = baseQuery(account: account)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  static func setCredential(_ credential: String?, for account: String) {
    guard let credential, !credential.isEmpty else {
      deleteCredential(for: account)
      return
    }

    let data = Data(credential.utf8)
    let query = baseQuery(account: account)
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      var item = query
      item[kSecValueData as String] = data
      item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      SecItemAdd(item as CFDictionary, nil)
    }
  }

  static func deleteCredential(for account: String) {
    SecItemDelete(baseQuery(account: account) as CFDictionary)
  }

  private static func baseQuery(account: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
  }
}
