//
//  XcactivityLogParser.swift
//  xgraph
//
//  Created by Антон Тимонин on 01.04.2025.
//

import Foundation
import SwiftUI

struct Package: Identifiable, Hashable {
    enum DepType { case staticLib, dynamic, unknown }

    let id = UUID()
    let name: String
    var type: DepType
    var startTime: TimeInterval
    var endTime: TimeInterval
}

struct LogDependencies: Identifiable, Hashable {

    let id = UUID()
    let fileName: String
    let totalDuration: TimeInterval
    var packages: [Package]
}

final class XcactivityLogParser: ObservableObject {

    @Published var parsedResults: [LogDependencies] = []
    @Published var isParsing = false
    @Published var progressValue = 0
    @Published var totalLogs = 0
    @Published var errorMessage: String?

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

                // «чистое» compile‑time таргета
                let pureDuration  = step.compilationDuration > 0
                                  ? step.compilationDuration
                                  : step.duration

                let startTime     = step.startTimestamp
                let endTime       = startTime + pureDuration

                if var existing = packagesDict[targetName] {
                    // если таргет встретился несколько раз (например, test‑таргет),
                    // берём больший compile‑time
                    existing.duration = max(existing.duration, pureDuration)
                    existing.endTime  = max(existing.endTime, endTime)
                    packagesDict[targetName] = existing
                } else {
                    packagesDict[targetName] = Package(
                        name:       targetName,
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
}
