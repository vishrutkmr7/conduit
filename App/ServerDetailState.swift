import Foundation

//
//  ServerDetailState.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

enum LoadState: Equatable {
  case idle
  case loading
  case loaded
  case failed(String)
}

enum IdeasState: Equatable {
  case idle
  case loading
  case unavailable
  case loaded([ShortcutIdea])
  case failed(String)
}

enum AgentState: Equatable {
  case idle
  case running
  case success(String)
  case failure(String)

  var isRunning: Bool {
    if case .running = self { true } else { false }
  }
}
