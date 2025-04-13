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
            
        }
    }
}
