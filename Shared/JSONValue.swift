import Foundation

//
//  JSONValue.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

nonisolated enum JSONValue: Codable, Hashable, Sendable {
  case object([String: JSONValue])
  case array([JSONValue])
  case string(String)
  case number(Double)
  case bool(Bool)
  case null

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Double.self) {
      self = .number(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode([String: JSONValue].self) {
      self = .object(value)
    } else {
      self = .array(try container.decode([JSONValue].self))
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .object(let value):
      try container.encode(value)
    case .array(let value):
      try container.encode(value)
    case .string(let value):
      try container.encode(value)
    case .number(let value):
      try container.encode(value)
    case .bool(let value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    }
  }

  var objectValue: [String: JSONValue]? {
    if case .object(let value) = self { value } else { nil }
  }

  var arrayValue: [JSONValue]? {
    if case .array(let value) = self { value } else { nil }
  }

  var stringValue: String? {
    if case .string(let value) = self { value } else { nil }
  }

  static func parseObject(_ string: String) throws -> JSONValue {
    let data = Data(string.utf8)
    let value = try JSONDecoder().decode(JSONValue.self, from: data)
    guard case .object = value else { throw MCPClientError.decoding }
    return value
  }

  func prettyPrinted() -> String {
    guard let data = try? JSONEncoder().encode(self),
          let object = try? JSONSerialization.jsonObject(with: data),
          let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
          let string = String(data: pretty, encoding: .utf8) else {
      return String(describing: self)
    }
    return string
  }
}
