//
//  TargetGraphParser.swift
//  xgraph
//
//  Created by Антон Тимонин on 23.03.2025.
//

import Foundation

// MARK: - Models

struct Target: Hashable {
    let name: String
    let project: String
}

struct Dependency: Hashable {
    let target: Target
    let type: DependencyType
}

enum DependencyType: Hashable {
    case explicit
    case implicit
}

// MARK: - Target Parser

final class TargetGraphParser {
    
    // MARK: - Internal methods
    
    func parse(text: String) -> [Target: [Dependency]] {
        
        var graph = [Target: [Dependency]]()
        var currentTarget: Target?
        
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.starts(with: "Target") {
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
            
            else if trimmedLine.starts(with: "➜") {
                guard let currentTarget = currentTarget else { continue }
                
                // Определяем тип зависимости типа зависимости
                let isExplicit = trimmedLine.contains("Explicit")
                let dependencyType: DependencyType = isExplicit ? .explicit : .implicit
                
                let dependencyPart = trimmedLine.components(separatedBy: "dependency on target '").last ?? ""
                let targetComponents = dependencyPart.components(separatedBy: "' in project '")
                
                guard targetComponents.count >= 2 else { continue }
                let targetName = targetComponents[0]
                let projectName = targetComponents[1].components(separatedBy: "'").first ?? ""
                
                // Создание зависимости
                let target = Target(name: targetName, project: projectName)
                let dependency = Dependency(target: target, type: dependencyType)
                
                // Добавление зависимости в граф
                graph[currentTarget]?.append(dependency)
            }
        }
        
        return graph
    }
}
