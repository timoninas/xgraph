//
//  ContentView.swift
//  xgraph
//
//  Created by Anton Timonin on 13.04.2025.
//

import SwiftUI
import UniformTypeIdentifiers
import Charts

// форматирование даты
private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .short
    f.timeStyle = .short
    return f
}()

struct MainView: View {

    @StateObject private var derivedDataManager = DerivedDataManager()
    @State private var selectedLogFile: URL?
    @State private var activeLog: LogDependencies?

    var body: some View {
        VStack {
            // перетаскивание DerivedData
            DerivedDataDropAreaView { dir in
                derivedDataManager.processDerivedData(directory: dir)
            }
            .padding()

            if let graph = derivedDataManager.selectedDependencyGraph {
                Text("Выбран граф зависимостей с \(graph.keys.count) целями.")
                    .font(.headline)
                    .padding()
            }

            // список .xcactivitylog
            if !derivedDataManager.xcactivityLogFiles.isEmpty {
                Text("Выберите лог сборки (.xcactivitylog):")
                    .font(.subheadline)

                List(derivedDataManager.xcactivityLogFiles, id: \.self) { url in
                    Button {
                        selectedLogFile = url
                        derivedDataManager.parseLogs(urls: [url])
                    } label: {
                        HStack {
                            Text(url.lastPathComponent)
                            Spacer()
                            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                               let dt   = attrs[.creationDate] as? Date {
                                Text("\(dt, formatter: dateFormatter)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }

            // индикатор
            if derivedDataManager.isParsingActivityLogs {
                ProgressView().padding()
            }

            // список пакетов
            DependencyListView(results: derivedDataManager.parsedResults)

            if let log = activeLog {
                Button("Открыть диаграмму") {
                    GanttWindow.show(for: log, graph: derivedDataManager.selectedDependencyGraph)
                }
                .padding(.vertical)
            }
        }
        .frame(minWidth: 600, minHeight: 800)
        .onChange(of: derivedDataManager.parsedResults) { activeLog = $0.first }
        .alert("Ошибка",
               isPresented: Binding(get: { derivedDataManager.errorMessage != nil },
                                    set: { _ in derivedDataManager.errorMessage = nil })) {
            Button("OK", role: .cancel) { derivedDataManager.errorMessage = nil }
        } message: {
            Text(derivedDataManager.errorMessage ?? "")
        }
    }
}

struct DependencyListView: View {
    let results: [LogDependencies]

    var body: some View {
        List {
            ForEach(results) { log in
                DisclosureGroup(log.fileName) {
                    Text("Project total time: \(String(format: "%.2f", log.totalDuration)) sec")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.vertical, 4)

                    ForEach(log.packages) { p in
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: icon(for: p.type))
                                    .foregroundColor(color(for: p.type))
                                Text(p.name)
                                Spacer()
                                Text(label(for: p.type))
                                    .foregroundColor(color(for: p.type))
                            }
                            Text("Duration: \(String(format: "%.2f", p.duration)) sec")
                                .font(.caption)
                                .foregroundColor(.gray)

                            if !p.dependencies.isEmpty {
                                Text("Depends on: \(p.dependencies.sorted().joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .font(.headline)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    private func icon(for t: Package.DepType) -> String {
        switch t {
        case .dynamic:   return "link"
        case .staticLib: return "cube.fill"
        case .unknown:   return "questionmark"
        }
    }
    private func label(for t: Package.DepType) -> String {
        switch t {
        case .dynamic:   return "Dynamic"
        case .staticLib: return "Static"
        case .unknown:   return "Unknown"
        }
    }
    private func color(for t: Package.DepType) -> Color {
        switch t {
        case .dynamic:   return .blue
        case .staticLib: return .green
        case .unknown:   return .gray
        }
    }
}
