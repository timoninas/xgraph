//
//  DerivedDataManager.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.03.2025.
//

import Foundation
import SwiftUI
import Combine

class DerivedDataManager: ObservableObject {
    
    @Published var isParsingActivityLogs = false
    
    @Published var parsedResults: [LogDependencies]
    
    @Published var selectedDependencyGraph: [Target: [Dependency]]?
    @Published var xcactivityLogFiles: [URL] = []
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var xcactivityLogParser: XcactivityLogParser
    private let targetGraphParser: TargetGraphParser
    
    init(isParsingActivityLogs: Bool = false,
         selectedDependencyGraph: [Target : [Dependency]]? = nil,
         xcactivityLogFiles: [URL] = [],
         errorMessage: String? = nil,
         cancellables: Set<AnyCancellable> = Set<AnyCancellable>(),
         xcactivityLogParser: XcactivityLogParser = XcactivityLogParser(),
         targetGraphParser: TargetGraphParser = TargetGraphParser()) {
        self.isParsingActivityLogs = isParsingActivityLogs
        self.parsedResults = []
        self.xcactivityLogParser = xcactivityLogParser
        self.targetGraphParser = TargetGraphParser()
        self.selectedDependencyGraph = selectedDependencyGraph
        self.xcactivityLogFiles = xcactivityLogFiles
        self.errorMessage = errorMessage
        self.cancellables = cancellables
        
        self.subscribeToChanges()
    }
    
    private func subscribeToChanges() {
            xcactivityLogParser.$parsedResults
                .receive(on: DispatchQueue.main)
                .sink { [weak self] results in
                guard let self = self else { return }
                
                var enriched = results
                if let graph = self.selectedDependencyGraph {
                    for i in 0..<enriched.count {
                        enriched[i].applyDependencies(from: graph)
                    }
                }
                self.parsedResults = enriched
            }
            .store(in: &cancellables)
        
            xcactivityLogParser.$isParsing
                .receive(on: DispatchQueue.main)
                .assign(to: &$isParsingActivityLogs)
    }
    
    func parseLogs(urls: [URL]) {
        self.xcactivityLogParser.parseLogs(urls: urls)
    }
    
    func processDerivedData(directory: URL) {
            self.selectedDependencyGraph = nil
            self.xcactivityLogFiles = []
            self.errorMessage = nil
        
            let fileManager = FileManager.default
        
            let xcbuildDataPath = directory.appendingPathComponent("Build/Intermediates.noindex/XCBuildData")
            var bestGraph: [Target: [Dependency]]?
            var bestCount = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: xcbuildDataPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            let buildDataFolders = contents.filter { $0.pathExtension == "xcbuilddata" }
            
            for folder in buildDataFolders {
                let targetGraphURL = folder.appendingPathComponent("target-graph.txt")
                if fileManager.fileExists(atPath: targetGraphURL.path) {
                    let content = try String(contentsOf: targetGraphURL, encoding: .utf8)
                    let graph = self.targetGraphParser.parse(text: content)
                    let targetCount = graph.keys.count
                    if targetCount > bestCount {
                        bestCount = targetCount
                        bestGraph = graph
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Ошибка при обработке XCBuildData: \(error.localizedDescription)"
            }
        }
        
        DispatchQueue.main.async {
            self.selectedDependencyGraph = bestGraph
        }
        
        let logsPath = directory.appendingPathComponent("Logs/Build")
        var sortedLogFiles: [URL] = []
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsPath, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
                .filter { $0.pathExtension == "xcactivitylog" }
            sortedLogFiles = logFiles.sorted {
                let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 < date2
            }
            DispatchQueue.main.async {
                self.xcactivityLogFiles = sortedLogFiles
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Ошибка при обработке логов: \(error.localizedDescription)"
            }
        }
    }
}
