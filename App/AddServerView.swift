import SwiftUI

//
//  AddServerView.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct AddServerView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        FeaturedKnownServersSection { known in
          ServerSetupView(known: known) { dismiss() }
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
