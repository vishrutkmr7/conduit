import SwiftUI

//
//  KnownServerRow.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct KnownServerRow: View {
  let known: KnownServer
  let isAdded: Bool

  var body: some View {
    Label {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(known.name)
          if isAdded {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
              .accessibilityLabel("Already added")
          }
        }
        Text(known.summary)
          .font(.footnote)
          .foregroundStyle(.secondary)
        Text(known.authKind == .none ? "Open access" : "Needs sign in")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    } icon: {
      ServerLogo(logoURLString: known.logoURLString, host: known.host, symbol: known.symbol, size: 36)
    }
    .accessibilityElement(children: .combine)
  }
}
