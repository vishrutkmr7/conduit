import SwiftUI

//
//  ServerListRow.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct ServerListRow: View {
  let server: MCPServer
  var health: ServerHealth = .unknown
  var toolCount: Int?

  var body: some View {
    HStack(spacing: 12) {
      ServerLogo(logoURLString: server.logoURLString, host: server.host, symbol: server.symbol, size: 36)
      VStack(alignment: .leading, spacing: 4) {
        Text(server.name)
        Text(detailText)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Image(systemName: health.symbol)
        .foregroundStyle(health.color)
        .accessibilityLabel(health.label)
    }
    .accessibilityElement(children: .combine)
  }

  private var detailText: String {
    if health == .connected, let toolCount {
      "\(server.host), \(toolCount == 1 ? "1 tool" : "\(toolCount) tools")"
    } else {
      "\(server.host), \(health.label)"
    }
  }
}
