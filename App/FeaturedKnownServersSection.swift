import SwiftUI

//
//  FeaturedKnownServersSection.swift
//  Conduit
//
//  Created by Cursor on 6/19/26.
//

/// Reusable list section for curated MCP servers.
struct FeaturedKnownServersSection<Destination: View>: View {
  @Environment(MCPServerStore.self) private var store

  private let title: LocalizedStringKey
  private let destination: (KnownServer) -> Destination

  init(
    title: LocalizedStringKey = "Featured",
    @ViewBuilder destination: @escaping (KnownServer) -> Destination
  ) {
    self.title = title
    self.destination = destination
  }

  var body: some View {
    Section(title) {
      ForEach(KnownServers.all) { known in
        NavigationLink {
          destination(known)
        } label: {
          KnownServerRow(known: known, isAdded: store.contains(known.urlString))
        }
      }
    }
  }
}
