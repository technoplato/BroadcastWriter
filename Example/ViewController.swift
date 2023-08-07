//
//  ViewController.swift
//  Example
//
//  Created by Roman on 28.02.2021.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
  
  var observations: [NSObjectProtocol] = []
  private lazy var notificationCenter: NotificationCenter = .default
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    print("Viewdid appear, initial reading.")
    
    read()
    
    observations.append(
      notificationCenter.addObserver(
        forName: UIApplication.willEnterForegroundNotification,
        object: nil,
        queue: nil
      ) { [weak self] _ in
        print("reading in observer")
        self?.read()
      }
    )
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
      )?.appendingPathComponent("Library")  {
      print("Container?")
      
      // Read the text file
      let textFilePath = container.appendingPathComponent("info.txt").path
      do {
        let content = try String(contentsOfFile: textFilePath, encoding: .utf8)
        print("Read from file: \(content)")
      } catch {
        print("Error reading the file: \(error.localizedDescription)")
      }
      
      let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
      do {
        let contents = try fileManager.contentsOfDirectory(atPath: container.path)
        for path in contents {
          print("path")
          print(path)
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

