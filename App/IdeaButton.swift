import SwiftUI

//
//  IdeaButton.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct IdeaButton: View {
  let idea: ShortcutIdea
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      Label {
        VStack(alignment: .leading, spacing: 4) {
          Text(idea.title)
            .font(.subheadline)
          Text(idea.prompt)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      } icon: {
        Image(systemName: "arrow.up.left.circle")
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityHint("Fills in the task field with this idea")
  }
}
