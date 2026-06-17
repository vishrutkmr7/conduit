import SwiftUI

//
//  AddServerView.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct AddServerView: View {
  @Environment(MCPServerStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        Section("Featured") {
          ForEach(KnownServers.all) { known in
            NavigationLink {
              ServerSetupView(known: known) { dismiss() }
            } label: {
              KnownServerRow(known: known, isAdded: store.contains(known.urlString))
            }
          }
        }

        Section("Custom") {
          NavigationLink {
            CustomServerForm { dismiss() }
          } label: {
            Label("Add Custom Server", systemImage: "server.rack")
          }
        }
      }
      .navigationTitle("Add Server")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", systemImage: "xmark") { dismiss() }
        }
      }
    }
  }
}
