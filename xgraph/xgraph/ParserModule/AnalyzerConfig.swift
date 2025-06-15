//
//  AnalyzerConfig.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//

import Foundation
import Yams

struct AnalyzerConfig: Decodable {

    struct Weights: Decodable, Hashable {
        let cold: Double
        let incr: Double
        let link: Double
        let run: Double
    }
    struct Thresholds: Decodable, Hashable {
        
        let heavyComponent: Double
        let criticalPath: Double
        let lowParallelism: Double
        let staticFanOut: Double
        let dynamicSingleUse: Double
        let longSequentialPath: Double
        let manySmallDeps: ManySmallDeps

        struct ManySmallDeps: Decodable, Hashable {
            let maxDuration: Double
            let minCount:    Int
        }
    }

    let weights: Weights
    let thresholds: Thresholds

    static func load() -> AnalyzerConfig {
        let fm = FileManager.default
        let url = Bundle.main.url(forResource: "xgraph", withExtension: "yml")!

        let data = try! Data(contentsOf: url)
        let dict = try! Yams.load(yaml: String(decoding: data, as: UTF8.self))!
        let json = try! JSONSerialization.data(withJSONObject: dict)
        return try! JSONDecoder().decode(AnalyzerConfig.self, from: json)
    }
}
