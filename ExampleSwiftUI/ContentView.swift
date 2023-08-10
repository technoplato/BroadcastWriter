//
//  ContentView.swift
//  ExampleSwiftUI
//
//  Created by laptop on 8/10/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Goodbye, world!")
          SharedFilesView(viewModel: SharedFilesViewModel())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}


/// MARK - App Group Files
struct FileItem {
    let name: String
    let path: String
    let isDirectory: Bool
    var children: [FileItem] = []
}


class SharedFilesViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    
    private let fileManager = FileManager.default
    private let containerURL: URL?
    
    init() {
        containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.lustig.Example")
    }
    
    func fetchFiles(from directoryURL: URL? = nil) -> [FileItem] {
        let url = directoryURL ?? containerURL
        
        guard let containerURL = url else {
            debugPrint("no container directory")
            return []
        }

        var items: [FileItem] = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil, options: [])
            for contentURL in contents {
                let isDirectoryResourceValue = try contentURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
                let name = contentURL.lastPathComponent
                let filePath = contentURL.path
                var item = FileItem(name: name, path: filePath, isDirectory: isDirectoryResourceValue ?? false)
                if item.isDirectory {
                    item.children = fetchFiles(from: contentURL) // Recursive call for directories
                }
                items.append(item)
            }
        } catch {
            debugPrint("Error reading contents:", error)
        }
        
        if directoryURL == nil {
            self.files = items // Only update the root level files
        }
        
        return items
    }
}

struct FileItemView: View {
    let item: FileItem

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.name)
            if item.isDirectory {
                ForEach(item.children, id: \.path) { childItem in
                    FileItemView(item: childItem)
                        .padding(.leading, 16)
                }
            }
        }
    }
}

struct SharedFilesView: View {
    @ObservedObject var viewModel: SharedFilesViewModel
    
    var body: some View {
        VStack {
            Button("Refresh") {
                viewModel.fetchFiles()
            }
            List(viewModel.files, id: \.path) { fileItem in
                FileItemView(item: fileItem)
            }
        }
        .onAppear {
            viewModel.fetchFiles()
        }
    }
}

