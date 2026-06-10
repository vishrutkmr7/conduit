import SwiftUI

/// Configure and authenticate a known MCP server before adding it.
struct ServerSetupView: View {
  @Environment(MCPServerStore.self) private var store
  let known: KnownServer
  var onAdded: () -> Void

  @State private var credential = ""
  @State private var isShowingBrowser = false

  private var needsCredential: Bool { known.authKind != .none }
  private var canAdd: Bool { !needsCredential || !credential.isEmpty }

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        header

        if needsCredential {
          GroupBox {
            VStack(alignment: .leading, spacing: 14) {
              Text("Sign in to \(known.name) in the in-app browser, create or copy an access token, then paste it below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

              Button {
                isShowingBrowser = true
              } label: {
                Label("Open \(known.name) Sign-in", systemImage: "safari")
                  .frame(maxWidth: .infinity)
              }
              .buttonStyle(.bordered)
              .controlSize(.large)

              VStack(alignment: .leading, spacing: 6) {
                Text("Access token").font(.caption).foregroundStyle(.secondary)
                SecureField("Paste token", text: $credential)
                  .textFieldStyle(.roundedBorder)
                  .autocorrectionDisabled()
              }
            }
          }
        } else {
          GroupBox {
            Label("This server is openly accessible — no sign-in required.", systemImage: "lock.open")
              .font(.subheadline)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }

        Button {
          add()
        } label: {
          Text("Add \(known.name)")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!canAdd)
      }
      .padding()
    }
    .navigationTitle(known.name)
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    .sheet(isPresented: $isShowingBrowser) {
      if let url = URL(string: known.authURLString ?? known.urlString) {
        WebBrowserView(url: url)
      }
    }
  }

  private var header: some View {
    VStack(spacing: 12) {
      ServerLogo(logoURLString: known.logoURLString, host: known.host, symbol: known.symbol, tint: known.tint, size: 76, cornerRadius: 18)
      Text(known.summary)
        .font(.callout)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Text(known.urlString)
        .font(.caption.monospaced())
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 8)
  }

  private func add() {
    var server = known.makeServer()
    server.credential = credential.isEmpty ? nil : credential
    store.add(server)
    onAdded()
  }
}
