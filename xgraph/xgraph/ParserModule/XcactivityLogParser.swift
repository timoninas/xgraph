//
//  XcactivityLogParser.swift
//  xgraph
//
//  Created by Антон Тимонин on 01.04.2025.
//

import Foundation
import SwiftUI

struct Package: Identifiable, Hashable {
    
    // MARK: - Internal properties
    
    enum DepType {
        case staticLib
        case dynamic
        case unknown
    }

    let id = UUID()
    let name: String
    var type: DepType
    var startTime: TimeInterval
    var endTime: TimeInterval
    var duration: TimeInterval
    var dependencies: Set<String> = []
}

struct LogDependencies: Identifiable, Hashable {
    
    // MARK: - Internal properties

    let id = UUID()
    let fileName: String
    let totalDuration: TimeInterval
    var packages: [Package]
    
    // MARK: - Internal methods

    mutating func applyDependencies(from graph: [Target: [Dependency]]?) {
        guard let graph else { return }

        var indexForName: [String: Int] = [:]
        for (i, pkg) in packages.enumerated() { indexForName[pkg.name] = i }

        for (parent, deps) in graph {
            guard let pIdx = indexForName[parent.name] else { continue }
            for dep in deps { packages[pIdx].dependencies.insert(dep.target.name) }
        }
    }
}

final class XcactivityLogParser: ObservableObject {
    
    // MARK: - Internal properties

    @Published var parsedResults: [LogDependencies] = []
    @Published var isParsing: Bool
    @Published var progressValue: Int
    @Published var totalLogs: Int
    @Published var errorMessage: String?
    
    // MARK: - Init
    
    init(parsedResults: [LogDependencies] = [],
         isParsing: Bool = false,
         progressValue: Int = 0,
         totalLogs: Int = 0,
         errorMessage: String? = nil) {
        self.parsedResults = parsedResults
        self.isParsing = isParsing
        self.progressValue = progressValue
        self.totalLogs = totalLogs
        self.errorMessage = errorMessage
    }
    
    // MARK: - Internal properties

    func parseLogs(urls: [URL]) {
        parsedResults.removeAll()
        isParsing = true
        progressValue = 0
        totalLogs = urls.count

        DispatchQueue.global(qos: .userInitiated).async {
            for url in urls {
                do {
                    let buildStep = try self.parseLogFile(at: url)
                    let totalBuildTime = buildStep.duration
                    let logDependencies = self.extractPackages(
                        from: buildStep,
                        fileURL: url,
                        totalBuildTime: totalBuildTime
                    )
                    DispatchQueue.main.async {
                        self.parsedResults.append(logDependencies)
                        self.progressValue += 1
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Ошибка при разборе \(url.lastPathComponent): \(error.localizedDescription)"
                    }
                }
            }
            DispatchQueue.main.async { self.isParsing = false }
        }
    }
    
    // MARK: - Private methods

    private func extractPackages(
            from buildStep: BuildStep,
            fileURL: URL,
            totalBuildTime: TimeInterval
        ) -> LogDependencies {

            var packagesDict: [String: Package] = [:]

            func traverse(step: BuildStep) {
                guard step.type == .target,
                      step.title.hasPrefix("Build target ") else {
                    step.subSteps.forEach { traverse(step: $0) }
                    return
                }

                let targetName    = step.title.replacingOccurrences(of: "Build target ", with: "")
                let inferredType  = inferPackageType(for: step)

                let pureDuration  = step.compilationDuration > 0
                                  ? step.compilationDuration
                                  : step.duration

                let startTime     = step.startTimestamp
                let endTime       = startTime + pureDuration

                if var existing = packagesDict[targetName] {
                    existing.duration = max(existing.duration, pureDuration)
                    existing.type     = inferredType == .unknown ? existing.type : inferredType
                    existing.endTime  = max(existing.endTime, endTime)
                    packagesDict[targetName] = existing
                } else {
                    packagesDict[targetName] = Package(
                        name:       targetName,
                        type:       inferredType,
                        startTime:  startTime,
                        endTime:    endTime,
                        duration:   pureDuration
                    )
                }
            }

            traverse(step: buildStep)
            let packages = Array(packagesDict.values)

            return LogDependencies(
                fileName:       fileURL.lastPathComponent,
                totalDuration:  totalBuildTime,
                packages:       packages
            )
        }
    
    private func parseLogFile(at url: URL) throws -> BuildStep {
        let activityLog = try ActivityParser().parseActivityLogInURL(
            url,
            redacted: false,
            withoutBuildSpecificInformation: false
        )
        let buildParser = ParserBuildSteps(
            omitWarningsDetails: false,
            omitNotesDetails: false,
            truncLargeIssues: false
        )
        return try buildParser.parse(activityLog: activityLog)
    }

    private func inferPackageType(for target: BuildStep) -> Package.DepType {

        if stepContains(target, where: { $0.detailStepType == .createStaticLibrary }) {
            return .staticLib
        }

        if stepContains(target, where: { $0.detailStepType == .linker }) ||
            stepContains(target, where: { signatureContains($0, pattern: "-emit-library") }) {
            return .dynamic
        }

        return .unknown
    }

    private func stepContains(_ step: BuildStep,
                              where predicate: (BuildStep) -> Bool) -> Bool {
        if predicate(step) { return true }
        for sub in step.subSteps {
            if stepContains(sub, where: predicate) { return true }
        }
        return false
    }

    private func signatureContains(_ step: BuildStep, pattern: String) -> Bool {
        step.signature.contains(pattern) || step.title.contains(pattern)
    }
}
