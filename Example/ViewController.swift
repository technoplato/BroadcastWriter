//
//  ViewController.swift
//  Example
//
//  Created by Roman on 28.02.2021.
//

import UIKit
import AVFoundation
import AVKit
import ReplayKit

class ViewController: UIViewController {
  
  var observations: [NSObjectProtocol] = []
  private lazy var notificationCenter: NotificationCenter = .default
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
//    broadcastPicker.preferredExtension = "com.your-app.broadcast.extension"
//
//
//    view.addSubview(broadcastPicker)

  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    print("Viewdid appear, initial reading.")
    
//    read()
    
    observations.append(
      notificationCenter.addObserver(
        forName: UIApplication.willEnterForegroundNotification,
        object: nil,
        queue: nil
      ) { [weak self] _ in
        print("reading in observer")
        if (self != nil) { print(self as Any) }
//        self?.read()
      }
    )
    
    
    let vc = RPBroadcastActivityViewController()
    present(vc, animated: true)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    observations.forEach(notificationCenter.removeObserver(_:))
  }
  
  private func read() {
    print("read called!")
    let fileManager = FileManager.default
    
    var mediaURLs: [URL] = []
    if let container = fileManager
      .containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.lustig.Example"
      ) {
      print("Container?")
      
      do {
        let contents = try fileManager.contentsOfDirectory(atPath: container.path)
        for path in contents {
          let fullPath = container.appendingPathComponent(path).absoluteString
          print("Full path of content in shared container: \(fullPath)")
        }
      } catch {print(error)}
      
      // Read the text file
      let textFilePath = container.appendingPathComponent("info.txt").path
      if fileManager.fileExists(atPath: textFilePath) {
        do {
          let content = try String(contentsOfFile: textFilePath, encoding: .utf8)
          print("Read from file: \(content)")
        } catch {
          print("Error reading the file: \(error.localizedDescription)")
        }
      } else {
        print("File 'info.txt' does not exist yet.")
      }
      
      let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
      do {
        let contents = try fileManager.contentsOfDirectory(atPath: container.path)
        for path in contents {
          let fullPath = container.appendingPathComponent(path).absoluteString
          print("Full path of file: \(fullPath)")
          guard !path.hasSuffix(".plist") else {
            print("file at path \(path) is plist, exiting")
            return
          }
          let fileURL = container.appendingPathComponent(path)
          var isDirectory: ObjCBool = false
          guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
            return
          }
          guard !isDirectory.boolValue else {
            return
          }
          let destinationURL = documentsDirectory.appendingPathComponent(path)
          if fileManager.fileExists(atPath: destinationURL.absoluteString, isDirectory: &isDirectory)  {
            print("File exsists!!! uh oh")
            fileManager.removeFileIfExists(url: destinationURL)
          }
          
          do {
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            print("Successfully copied \(fileURL)", "to: ", destinationURL)
          } catch {
            print("error copying \(fileURL) to \(destinationURL)", error)
          }
          mediaURLs.append(destinationURL)
        }
      } catch {
        print("contents, \(error)")
      }
    }
    
    mediaURLs.first.map {
      let asset: AVURLAsset = .init(url: $0)
      let item: AVPlayerItem = .init(asset: asset)
      
      let movie: AVMutableMovie = .init(url: $0)
      for track in movie.tracks {
        print("track", track)
      }
      
      let player: AVPlayer = .init(playerItem: item)
      let playerViewController: AVPlayerViewController = .init()
      playerViewController.player = player
      present(playerViewController, animated: true, completion: { [player = playerViewController.player] in
        player?.play()
      })
    }
  }
}

extension FileManager {
  
  func removeFileIfExists(url: URL) {
    guard fileExists(atPath: url.path) else { return }
    do {
      try removeItem(at: url)
    } catch {
      print("error removing item \(url)", error)
    }
  }
}
