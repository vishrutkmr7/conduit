import FoundationModels

/// A single suggested task the on-device model brainstorms from a server's tools.
/// Shown as a tappable suggestion that prefills the agent prompt.
@Generable
struct ShortcutIdea: Equatable {
  @Guide(description: "A short, action-oriented title of 2 to 5 words.")
  var title: String

  @Guide(description: "A concrete request phrased as the user speaking to an assistant, achievable with the server's tools.")
  var prompt: String
}

/// A small set of distinct ideas, capped so generation stays quick on device.
@Generable
struct ShortcutIdeas: Equatable {
  @Guide(description: "Distinct, practical task ideas for this server.", .count(3))
  var ideas: [ShortcutIdea]
}
