import AppIntents

/// Opens the Conduit app. Used by the Control Center control.
struct OpenConduitIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Conduit"
  static let openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    .result()
  }
}
