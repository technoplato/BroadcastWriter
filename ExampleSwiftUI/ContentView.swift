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


class SharedFilesViewModel: ObservableObject {
    @Published var files: [String] = []
    
    private let fileManager = FileManager.default
    private let containerURL: URL?
    
    init() {
        containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.lustig.Example")
    }
    
    func fetchFiles() {
        guard let containerURL = containerURL else {
            debugPrint("no container directory")
            return
        }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: containerURL.path)
            self.files = contents
            for path in contents {
                let fullPath = containerURL.appendingPathComponent(path).path
                debugPrint("Full path of content in shared container:", fullPath)
            }
        } catch {
            debugPrint("Error reading contents:", error)
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
            List(viewModel.files, id: \.self) { file in
                Text(file)
            }
        }
        .onAppear {
            viewModel.fetchFiles()
        }
    }
}
