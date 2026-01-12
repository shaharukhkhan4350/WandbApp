//
//  WandbModels.swift
//  WandbApp
//
//  Data models for wandb API responses
//

import Foundation

struct WandbProject: Codable, Identifiable {
    let id: String
    let name: String
    let entity: String
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, entity
        case createdAt = "created_at"
    }
}

struct WandbRun: Codable, Identifiable {
    let id: String
    let name: String
    let state: String
    let config: [String: AnyCodable]?
    let summary: [String: AnyCodable]?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, state, config, summary
        case createdAt = "created_at"
    }
}

struct WandbMetric: Codable, Identifiable {
    let id: String
    let name: String
    let values: [Double]
    let steps: [Int]
    
    var dataPoints: [DataPoint] {
        zip(steps, values).map { DataPoint(step: $0, value: $1) }
    }
}

struct DataPoint: Codable {
    let step: Int
    let value: Double
}

// Helper for decoding Any type
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}
