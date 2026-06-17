import Foundation

//
//  AppGroup.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

/// Shared App Group used by the app, its App Intents, and the widget extension to
/// read and write the list of configured MCP servers.
nonisolated enum AppGroup {
  static let id = "group.app.bitrig.vishrutjha.conduit"

  static var defaults: UserDefaults {
    UserDefaults(suiteName: id) ?? .standard
  }

  static var containerURL: URL {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) ?? URL.documentsDirectory
  }
}
