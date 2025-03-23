//
//  TargetGraphParser.swift
//  xgraph
//
//  Created by Антон Тимонин on 23.03.2025.
//

import Foundation

struct Target: Hashable {
    let name: String
    let project: String
}

class TargetGraphParser {
    
    func parse(text: String) -> [Target: [Dependency]] {
        var graph = [Target: [Dependency]]()
        var currentTarget: Target?
        
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            let components = trimmedLine.components(separatedBy: "'")
            guard components.count >= 5 else { continue }
            let name = components[1]
            let project = components[3]
            currentTarget = Target(name: name, project: project)
            
            // Добавляем цель в граф, если её ещё нет
            if graph[currentTarget!] == nil {
                graph[currentTarget!] = []
            }
        }
        
        return graph
    }
}
