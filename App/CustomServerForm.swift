import SwiftUI

/// Form for adding a fully custom remote MCP server.
struct CustomServerForm: View {
  @Environment(MCPServerStore.self) private var store
  var onAdded: () -> Void

  @State private var name = ""
  @State private var urlString = ""
  @State private var authKind: MCPAuthKind = .none
  @State private var headerName = "Authorization"
  @State private var credential = ""
  @State private var symbol = "server.rack"
  @State private var tint = "teal"

  private let symbols = ["server.rack", "cloud", "globe", "bolt.horizontal", "cpu", "wrench.and.screwdriver", "terminal", "shippingbox"]

  private var isValid: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty && URL(string: urlString)?.scheme?.hasPrefix("http") == true
  }

  var body: some View {
    VStack(spacing: 20) {
      GroupBox {
        VStack(spacing: 12) {
          LabeledField("Name", text: $name, prompt: "My MCP Server")
          LabeledField("Endpoint URL", text: $urlString, prompt: "https://example.com/mcp")
            .textContentType(.URL)
            #if os(iOS)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            #endif
            .autocorrectionDisabled()
        }
      }

      GroupBox("Authentication") {
        VStack(spacing: 12) {
          Picker("Method", selection: $authKind) {
            ForEach(MCPAuthKind.allCases) { kind in
              Text(kind.label).tag(kind)
            }
          }
          if authKind == .apiKey {
            LabeledField("Header", text: $headerName, prompt: "X-Api-Key")
              .autocorrectionDisabled()
          }
          if authKind != .none {
            VStack(alignment: .leading, spacing: 6) {
              Text(authKind == .oauth ? "Access token" : "Credential")
                .font(.caption)
                .foregroundStyle(.secondary)
              SecureField("Paste token", text: $credential)
                .textFieldStyle(.roundedBorder)
            }
          }
        }
      }

      GroupBox("Appearance") {
        VStack(alignment: .leading, spacing: 14) {
          symbolPicker
          tintPicker
        }
      }

      Button {
        add()
      } label: {
        Text("Add Server")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(!isValid)
    }
    .padding()
  }

  private var symbolPicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Symbol").font(.caption).foregroundStyle(.secondary)
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
        ForEach(symbols, id: \.self) { name in
          Button {
            symbol = name
          } label: {
            Image(systemName: name)
              .font(.title3)
              .frame(width: 44, height: 44)
              .background(symbol == name ? AnyShapeStyle(ServerTint.color(tint).opacity(0.25)) : AnyShapeStyle(.background.secondary), in: .rect(cornerRadius: 10))
              .overlay(
                RoundedRectangle(cornerRadius: 10)
                  .strokeBorder(symbol == name ? ServerTint.color(tint) : .clear, lineWidth: 2)
              )
          }
          .buttonStyle(.plain)
          .accessibilityLabel(name)
        }
      }
    }
  }

  private var tintPicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Color").font(.caption).foregroundStyle(.secondary)
      HStack {
        ForEach(ServerTint.names, id: \.self) { name in
          Button {
            tint = name
          } label: {
            Circle()
              .fill(ServerTint.color(name).gradient)
              .frame(width: 28, height: 28)
              .overlay(
                Circle().strokeBorder(.primary, lineWidth: tint == name ? 2 : 0)
              )
          }
          .buttonStyle(.plain)
          .accessibilityLabel(name)
        }
      }
    }
  }

  private func add() {
    let trimmedURL = urlString.trimmingCharacters(in: .whitespaces)
    let logo = URL(string: trimmedURL)?.host().map {
      "https://www.google.com/s2/favicons?domain=\($0)&sz=128"
    }
    let server = MCPServer(
      name: name.trimmingCharacters(in: .whitespaces),
      urlString: trimmedURL,
      symbol: symbol,
      tint: tint,
      logoURLString: logo,
      authKind: authKind,
      credential: credential.isEmpty ? nil : credential,
      headerName: headerName,
      isCustom: true
    )
    store.add(server)
    onAdded()
  }
}

/// A captioned text field used throughout the forms.
struct LabeledField: View {
  let title: String
  @Binding var text: String
  var prompt: String

  init(_ title: String, text: Binding<String>, prompt: String) {
    self.title = title
    self._text = text
    self.prompt = prompt
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).font(.caption).foregroundStyle(.secondary)
      TextField(prompt, text: $text)
        .textFieldStyle(.roundedBorder)
    }
  }
}
