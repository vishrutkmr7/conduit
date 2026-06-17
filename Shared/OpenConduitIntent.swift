import AppIntents

//
//  OpenConduitIntent.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

/// Opens the Conduit app. Used by the Control Center control.
struct OpenConduitIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Conduit"
  static var supportedModes: IntentModes { .foreground(.dynamic) }

  func perform() async throws -> some IntentResult {
    .result()
  }
}
