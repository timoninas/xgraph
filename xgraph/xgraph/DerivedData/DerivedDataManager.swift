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
    @Published var xcactivityLogFiles: [URL] = []
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(isParsingActivityLogs: Bool = false,
         selectedDependencyGraph: [Target : [Dependency]]? = nil,
         xcactivityLogFiles: [URL] = [],
         errorMessage: String? = nil,
         cancellables: Set<AnyCancellable> = Set<AnyCancellable>(),
         xcactivityLogParser: XcactivityLogParser = XcactivityLogParser(),
         targetGraphParser: TargetGraphParser = TargetGraphParser()) {
        self.isParsingActivityLogs = isParsingActivityLogs
        self.xcactivityLogFiles = xcactivityLogFiles
        self.errorMessage = errorMessage
        self.cancellables = cancellables
    }
    
    func parseLogs(urls: [URL]) {
    }
    
    func processDerivedData(directory: URL) {
        self.xcactivityLogFiles = []
        self.errorMessage = nil
        
        let fileManager = FileManager.default
        
        let xcbuildDataPath = directory.appendingPathComponent("Build/Intermediates.noindex/XCBuildData")
        var bestGraph: [Target: [Dependency]]?
        var bestCount = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: xcbuildDataPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            let buildDataFolders = contents.filter { $0.pathExtension == "xcbuilddata" }
        } catch {
            self.errorMessage = "Ошибка при обработке XCBuildData: \(error.localizedDescription)"
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
