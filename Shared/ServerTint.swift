import SwiftUI

/// Maps the stored tint name on a server to a SwiftUI `Color`.
enum ServerTint {
  static let names = ["teal", "blue", "indigo", "purple", "pink", "orange", "yellow", "green", "mint", "gray"]

  static func color(_ name: String) -> Color {
    switch name {
    case "blue": .blue
    case "indigo": .indigo
    case "purple": .purple
    case "pink": .pink
    case "orange": .orange
    case "yellow": .yellow
    case "green": .green
    case "mint": .mint
    case "gray": .gray
    default: .teal
    }
  }
}
