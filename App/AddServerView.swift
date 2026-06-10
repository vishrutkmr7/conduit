import SwiftUI

/// Sheet presenting a gallery of known remote MCP servers plus a custom form.
struct AddServerView: View {
  @Environment(MCPServerStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @State private var mode: Mode = .featured

  private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

  var body: some View {
    NavigationStack {
      ScrollView {
        Picker("Source", selection: $mode) {
          Text("Featured").tag(Mode.featured)
          Text("Custom").tag(Mode.custom)
        }
        .pickerStyle(.segmented)
        .padding([.horizontal, .top])

        switch mode {
        case .featured:
          featuredGrid
        case .custom:
          CustomServerForm { dismiss() }
        }
      }
      .navigationTitle("Add Server")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", systemImage: "xmark") { dismiss() }
            .labelStyle(.iconOnly)
        }
      }
    }
  }

  private var featuredGrid: some View {
    LazyVGrid(columns: columns, spacing: 14) {
      ForEach(KnownServers.all) { known in
        NavigationLink {
          ServerSetupView(known: known) { dismiss() }
        } label: {
          KnownServerCard(known: known, isAdded: store.contains(known.urlString))
        }
        .buttonStyle(.plain)
      }
    }
    .padding()
  }

  enum Mode: String {
    case featured
    case custom
  }
}

private struct KnownServerCard: View {
  let known: KnownServer
  let isAdded: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        ServerLogo(logoURLString: known.logoURLString, symbol: known.symbol, tint: known.tint, size: 40, cornerRadius: 10)
        Spacer()
        if isAdded {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .accessibilityLabel("Already added")
        }
      }
      Text(known.name)
        .font(.headline)
      Text(known.summary)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
      Label(known.authKind == .none ? "Open access" : "Needs sign in", systemImage: known.authKind.symbol)
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.background.secondary, in: .rect(cornerRadius: 16))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .strokeBorder(.separator.opacity(0.5))
    )
  }
}
