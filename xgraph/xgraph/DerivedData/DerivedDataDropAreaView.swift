//
//  Derived.swift
//  xgraph
//
//  Created by Антон Тимонин on 01.03.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct DerivedDataDropAreaView: View {
    
    // MARK: - Internal properties
    
    var onDirectoryDropped: (URL) -> Void
    
    // MARK: - Private properties
    
    @State private var isTargeted = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .frame(height: 100)
                .overlay(
                    Text(isTargeted ? "Отпустите DerivedData" : "Перетащите директорию DerivedData сюда")
                        .foregroundColor(.secondary)
                )
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Private methods
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                guard  let data = data as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    DispatchQueue.main.async {
                        onDirectoryDropped(url)
                    }
                }
            }
        }
        return true
    }
}
