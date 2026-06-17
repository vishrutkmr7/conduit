import SwiftUI

//
//  CustomServerForm.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

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

  private let symbols = ["server.rack", "cloud", "globe", "bolt.horizontal", "cpu", "wrench.and.screwdriver", "terminal", "shippingbox"]

  private var isValid: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty && URL(string: urlString)?.scheme?.hasPrefix("http") == true
  }

  var body: some View {
    Form {
      Section("Server") {
        TextField("Name", text: $name, prompt: Text("My MCP Server"))
        TextField("Endpoint URL", text: $urlString, prompt: Text("https://example.com/mcp"))
          .textContentType(.URL)
          #if os(iOS)
          .keyboardType(.URL)
          .textInputAutocapitalization(.never)
          #endif
          .autocorrectionDisabled()
      }

      Section("Authentication") {
        Picker("Method", selection: $authKind) {
          ForEach(MCPAuthKind.allCases) { kind in
            Text(kind.label).tag(kind)
          }
        }
        if authKind == .apiKey {
          TextField("Header", text: $headerName, prompt: Text("X-Api-Key"))
            .autocorrectionDisabled()
        }
        if authKind != .none {
          SecureField(authKind == .oauth ? "Access token" : "Credential", text: $credential)
        }
      }

      Section("Appearance") {
        Picker("Symbol", selection: $symbol) {
          ForEach(symbols, id: \.self) { name in
            Label(name, systemImage: name).tag(name)
          }
        }
      }

      Section {
        Button("Add Server", systemImage: "plus", action: add)
          .disabled(!isValid)
      }
    }
    .navigationTitle("Custom Server")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
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
