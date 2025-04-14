//
//  ContentView.swift
//  xgraph
//
//  Created by Anton Timonin on 13.04.2025.
//

import SwiftUI
import UniformTypeIdentifiers
import Charts

struct MainView: View {
    
    // MARK: - Private properties
    
    @StateObject private var derivedDataManager = DerivedDataManager()
    @State private var selectedLogFile: URL?
    @State private var activeLog: LogDependencies?
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            DerivedDataDropAreaView { dir in
                derivedDataManager.processDerivedData(directory: dir)
            }
            .padding()
            
            if let graph = derivedDataManager.selectedDependencyGraph {
                Text("Выбран граф зависимостей с \(graph.keys.count) целями.")
                    .font(.headline)
                    .padding()
            }
            
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
