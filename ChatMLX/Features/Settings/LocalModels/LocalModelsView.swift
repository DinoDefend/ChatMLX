//
//  LocalModelsView.swift
//  ChatMLX
//
//  Created by John Mai on 2024/8/10.
//
import Defaults
import SwiftUI

struct LocalModelsView: View {
    @State private var modelGroups: [LocalModelGroup] = []
    @Default(.defaultModel) var defaultModel

    var body: some View {
        List {
            ForEach(modelGroups.indices, id: \.self) { groupIndex in
                Section(
                    header: Text(modelGroups[groupIndex].name).font(
                        .title2.bold())
                ) {
                    ForEach(modelGroups[groupIndex].models.indices, id: \.self)
                    { modelIndex in
                        LocalModelItemView(
                            model: $modelGroups[groupIndex].models[modelIndex],
                            onDelete: {
                                deleteModel(
                                    at: IndexSet(integer: modelIndex),
                                    from: groupIndex)
                            }
                        )
                    }
                    .onDelete { offsets in
                        deleteModel(at: offsets, from: groupIndex)
                    }
                }
            }
        }
        .onAppear(perform: loadModels)
        .scrollContentBackground(.hidden)
        .listStyle(SidebarListStyle())
        .ultramanNavigationTitle("Models")
        .ultramanToolbarItem {
            Button(action: openModelsDirectory) {
                Image(systemName: "folder")
            }
            .buttonStyle(.plain)
        }
    }

    private func loadModels() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        let modelsURL = documentsURL.appendingPathComponent(
            "huggingface/models")

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: modelsURL, includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles])
            var groups: [LocalModelGroup] = []

            for groupURL in contents {
                if groupURL.hasDirectoryPath {
                    let groupName = groupURL.lastPathComponent
                    var models: [LocalModel] = []

                    let modelContents = try fileManager.contentsOfDirectory(
                        at: groupURL, includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles])

                    for modelURL in modelContents {
                        if modelURL.hasDirectoryPath {
                            let modelName = modelURL.lastPathComponent
                            models.append(
                                LocalModel(
                                    group: groupName,
                                    name: modelName,
                                    url: modelURL)
                            )
                        }
                    }

                    groups.append(
                        LocalModelGroup(name: groupName, models: models))
                }
            }

            if !groups.contains(where: {
                $0.models.contains(where: { $0.origin == defaultModel })
            }) {
                defaultModel = ""
            }

            DispatchQueue.main.async {
                modelGroups = groups
            }
        } catch {
            logger.error("loadModels failed: \(error)")
        }
    }

    private func deleteModel(at offsets: IndexSet, from group: Int) {
        let fileManager = FileManager.default

        for index in offsets {
            let model = modelGroups[group].models[index]
            do {
                try fileManager.removeItem(at: model.url)
                modelGroups[group].models.remove(at: index)
                if defaultModel == model.origin {
                    defaultModel = ""
                }
            } catch {
                logger.error("deleteModel failed: \(error)")
            }
        }
    }

    private func openModelsDirectory() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        let modelsURL = documentsURL.appendingPathComponent(
            "huggingface/models")

        NSWorkspace.shared.open(modelsURL)
    }
}