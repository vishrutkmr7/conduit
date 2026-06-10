import SwiftUI

/// A compact, horizontally scrolling row of well-known servers the user hasn't
/// added yet, shown on the home screen so the first tap to value is short and the
/// screen never feels empty. Tapping a chip opens that server's setup flow.
struct FeaturedServersStrip: View {
  @Environment(MCPServerStore.self) private var store
  var onSelect: (KnownServer) -> Void

  /// Top picks the user hasn't connected, capped so the row stays glanceable.
  private var candidates: [KnownServer] {
    KnownServers.all
      .filter { !store.contains($0.urlString) }
      .prefix(5)
      .map { $0 }
  }

  var body: some View {
    if !candidates.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        Label("Quick add", systemImage: "sparkles")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
          .padding(.horizontal)

        ScrollView(.horizontal) {
          HStack(spacing: 10) {
            ForEach(candidates) { known in
              Button {
                onSelect(known)
              } label: {
                FeaturedServerChip(known: known)
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
      }
    }
  }
}

/// A single quick-add chip: brand logo, name, and an add affordance.
private struct FeaturedServerChip: View {
  let known: KnownServer

  var body: some View {
    HStack(spacing: 8) {
      ServerLogo(
        logoURLString: known.logoURLString,
        host: known.host,
        symbol: known.symbol,
        tint: known.tint,
        size: 26,
        cornerRadius: 7
      )
      Text(known.name)
        .font(.subheadline.weight(.medium))
        .lineLimit(1)
      Image(systemName: "plus")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }
    .padding(.leading, 8)
    .padding(.trailing, 12)
    .padding(.vertical, 8)
    .background(.background.secondary, in: .capsule)
    .overlay(Capsule().strokeBorder(.separator.opacity(0.5)))
    .contentShape(.capsule)
    .accessibilityLabel("Add \(known.name)")
    .accessibilityHint(known.summary)
  }
}
