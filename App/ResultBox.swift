import SwiftUI

//
//  ResultBox.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct ResultBox: View {
  let text: String
  let isError: Bool

  var body: some View {
    Label {
      Text(text)
        .textSelection(.enabled)
    } icon: {
      Image(systemName: isError ? "exclamationmark.triangle" : "checkmark.circle")
    }
    .font(.callout)
    .foregroundStyle(isError ? .red : .primary)
  }
}
