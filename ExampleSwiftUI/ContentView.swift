//
//  ContentView.swift
//  ExampleSwiftUI
//
//  Created by laptop on 8/10/23.
//

import SwiftUI
import AVKit

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
  @State private var showVideoPlayer = false
  @State private var player: AVPlayer?
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(item.name)
        Spacer()
        if item.path.hasSuffix(".mp4") {
          Button("Play") {
            let url = URL(fileURLWithPath: item.path)
            player = AVPlayer(url: url)
            showVideoPlayer = true
          }
          .sheet(isPresented: $showVideoPlayer) {
            VideoPlayerView(player: $player)
          }
        }
      }
      
      if item.isDirectory {
        ForEach(item.children, id: \.path) { childItem in
          FileItemView(item: childItem)
            .padding(.leading, 16)
        }
      }
    }
  }
}

struct VideoPlayerView: View {
  @Binding var player: AVPlayer?
  @State var isPlaying: Bool = false
  
  var body: some View {
    VStack {
      VideoPlayer(player: player)
        .frame(width: 320, height: 180, alignment: .center)
      
      Button {
        isPlaying ? player?.pause() : player?.play()
        isPlaying.toggle()
        player?.seek(to: .zero)
      } label: {
        Image(systemName: isPlaying ? "stop" : "play")
          .padding()
      }
    }
  }
}

// Rest of the code remains the same


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

