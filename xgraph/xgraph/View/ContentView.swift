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

            if derivedDataManager.isParsingActivityLogs {
                ProgressView().padding()
            }
        }
    }
}
