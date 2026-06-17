import SwiftUI

//
//  HealthStatusLabel.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct HealthStatusLabel: View {
  let health: ServerHealth

  var body: some View {
    Label(health.label, systemImage: health.symbol)
      .foregroundStyle(health.color)
      .accessibilityLabel(health.label)
  }
}
