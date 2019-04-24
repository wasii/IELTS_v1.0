//
//  RecordingsViewController.swift
//  Khoa IELTS
//
//  Created by ColWorx on 03/01/2019.
//  Copyright © 2019 ast. All rights reserved.
//

import UIKit
import AVFoundation

struct RecordingSections {
    var folderName = String()
    var files = [Any]()
    
    init(folderName: String, files: [Any]) {
        self.folderName = folderName
        self.files = files
    }
}
class RecordingsViewController: UIViewController {

    var pausedAudioBar = 0.0
    var currentPlaying = [String: AnyObject]()
    var audioPlayer : AVAudioPlayer!
    var animateViewTimer = Timer()
    
    let pauseBtn = UIImage(named: "pause")
    let playBtn  = UIImage(named: "play")
    
    var currentIndexPath = IndexPath()
    var recordingCell = RecordingsTableViewCell()
    var recordingCellLoadingBarWidth = 0.0
    var cellDuration = 0
    var loadingBar = 0.0
    var duration = 0
    var tempDuration = 0
    var filesCount = 0
    
    var sections = [RecordingSections]()
    @IBOutlet weak var tableView: UITableView!
    
    var savedData = Array<Dictionary<String,AnyObject>>()// NSMutableArray()
    var dummydata = [
        [
            "title" : "Culture",
            "subTitle" : "Your Memories & Food",
            "duration" : "02:15",
        ],
        [
            "title" : "Travel",
            "subTitle" : "Lorem Ipsum dolor sit amet",
            "duration" : "02:15",
        ],
        [
            "title" : "Environment",
            "subTitle" : "Lorem Ipsum dolor sit amet",
            "duration" : "02:15",
        ],
        [
            "title" : "Technology",
            "subTitle" : "Lorem Ipsum dolor sit amet",
            "duration" : "02:15",
        ],
        [
            "title" : "Medical",
            "subTitle" : "Lorem Ipsum dolor sit amet",
            "duration" : "02:15",
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getFoldersName()
        self.tableView.rowHeight = 115
    }
    
    func getFoldersName() {
        
        var temporaryDictionary = [String: AnyObject]()
        var fileNamesInFolders = [AnyObject]()
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [])
            
            let subdirs = directoryContents.filter{ $0.hasDirectoryPath }
            
            var i = 0
            for folderName in subdirs {
                let subdirNamesStr = subdirs.map{ $0.lastPathComponent }
                let subFolderName = try FileManager.default.contentsOfDirectory(at: folderName, includingPropertiesForKeys: nil, options: [])

                for directories in subFolderName {
                    fileNamesInFolders.removeAll()
                    let subFolderNameDirectoriesFiles = try FileManager.default.contentsOfDirectory(at: directories, includingPropertiesForKeys: nil, options: [])
                    
                    let subFolderNameDirectoriesWithExtension = subFolderNameDirectoriesFiles.map{$0.deletingPathExtension()}
                    let subFolderNameDirectoriesWithOutExtension = subFolderNameDirectoriesWithExtension.map{$0.lastPathComponent}
                    
                    let subFolderNameDirectoriesFilesNames = subFolderNameDirectoriesFiles.map{$0.lastPathComponent}
                    
                    var j = 0
                    for subFolderNameDirectoriesFilesNamesDuration in subFolderNameDirectoriesFilesNames {
                        filesCount = filesCount + 1
                        
                        let directoryString = directories.appendingPathComponent(subFolderNameDirectoriesFilesNamesDuration).absoluteString
                        let audioUrl = URL(string: directoryString)
                        let audioAsset = AVURLAsset.init(url: audioUrl!, options: nil)
                        let duration = audioAsset.duration
                        let durationInSeconds = Int(CMTimeGetSeconds(duration))
                        
                        let dictionary = ["fileName" : subFolderNameDirectoriesWithOutExtension[j],
                                          "duration" : durationInSeconds,
                                          "location" : audioUrl!,
                                          "isPlaying" : false as AnyObject] as [String : AnyObject]
                        fileNamesInFolders.append(dictionary as AnyObject)
                        
                        j = j + 1
                    }
                    temporaryDictionary = ["folderName" : subdirNamesStr[i],
                                           "files": fileNamesInFolders] as [String : AnyObject]

                    if sections.isEmpty {
                        sections = [RecordingSections(folderName: subdirNamesStr[i], files: fileNamesInFolders)]
                    } else {
                        sections = sections + [RecordingSections(folderName: subdirNamesStr[i], files: fileNamesInFolders)]
                    }
                }
                i = i + 1
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}

extension RecordingsViewController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
       return sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingsCell") as! RecordingsTableViewCell

        var cellduration = "00:"
        let data = sections[indexPath.section].files[indexPath.row] as! [String: AnyObject]
        cell.headingLabel.text = sections[indexPath.section].folderName
        cell.subHeadingLabel.text = data["fileName"] as? String
        if(data["duration"] as? Int != 20){
            cellduration = "00:0"
        }
        let duration = data["duration"] as? Int
        
        if(duration! > 20) {
            if(duration! < 60) {
                let timer = duration! - 60
                if timer >= 10 {
                    cellduration = "01:"
                } else {
                    cellduration = "01:0"
                }
                
            } else {
                cellduration = "00:"
            }
        }
        
        if (data["isPlaying"] as! Bool) {
            self.recordingCell.loadingBar.frame.size.width = CGFloat(pausedAudioBar)
            self.recordingCell.imageViewFrame.layer.position.x =  CGFloat(pausedAudioBar + 7)
            self.recordingCellLoadingBarWidth = pausedAudioBar
            
            if(duration! == 120) {
                self.recordingCell.durationLabel.text = "02:00"
            } else {
                self.recordingCell.durationLabel.text = "\(cellduration)\(self.duration)"//"00:\(self.duration)"
            }
            
        } else {
            cell.playPauseBtn.isSelected = false
            cell.loadingBar.frame.size.width = 0.0
            cell.imageViewFrame.layer.position.x = 7.0
            cell.playPauseBtn.setImage(self.playBtn, for: .normal)
            
            cell.durationLabel.text = cellduration+"\(data["duration"] as? Int ?? 0)"
        }
        cell.playPauseBtn.tag = indexPath.row
        cell.playPauseBtn.addTarget(self, action: #selector(playCurrentRecording(_:)), for: .touchUpInside)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

    }
    
    @objc func playCurrentRecording(_ sender:UIButton){
        
        sender.isSelected = !sender.isSelected
        let buttonPosition = sender.convert(CGPoint.zero, to: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at:buttonPosition)

        
        if currentIndexPath.isEmpty {
            currentIndexPath = indexPath!
        } else {
            if currentIndexPath != indexPath {
                if audioPlayer.isPlaying {
                    stopAnimation(currentIndexPath)
                }
            }
        }
        let data = sections[(indexPath?.section)!].files[(indexPath?.row)!] as! [String: AnyObject]
        let fileLocation = data["location"] as! URL
        duration = data["duration"] as! Int
        
        
        
        if sender.isSelected {
            for (key, value) in sections[(indexPath?.section)!].files[(indexPath?.row)!] as! [String: AnyObject]{
                if key == "location" {
                    currentPlaying[key] = value
                }
                if key == "duration" {
                    currentPlaying[key] = value
                }
                if key == "isPlaying" {
                    currentPlaying[key] = true as AnyObject
                }
                if key == "fileName" {
                    currentPlaying[key] = value
                }
            }
            sections[(indexPath?.section)!].files[(indexPath?.row)!] = currentPlaying as Any
            
            sender.setImage(pauseBtn, for: .normal)
            do {
              recordingCell = self.tableView.cellForRow(at: indexPath!) as! RecordingsTableViewCell
                let sound = try AVAudioPlayer(contentsOf: fileLocation)
                audioPlayer = sound
                sound.play()
                sound.numberOfLoops = 0
                self.tableView.isScrollEnabled = false
                animateViewTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(animateView(_:)), userInfo: nil, repeats: true)
            } catch {
                
            }
        } else {
            recordingCell = self.tableView.cellForRow(at: indexPath!) as! RecordingsTableViewCell
            sender.setImage(playBtn, for: .normal)
            if audioPlayer.isPlaying {
                audioPlayer.pause()
                terminateTimer()
                pauseAnimateView()
            }
        }
        currentIndexPath = indexPath!
    }
    
    func stopAnimation(_ indexPath: IndexPath) {
        currentPlaying = [:]
        for (key, value) in sections[(indexPath.section)].files[(indexPath.row)] as! [String: AnyObject]{
            if key == "location" {
                currentPlaying[key] = value
            }
            if key == "duration" {
                currentPlaying[key] = value
            }
            if key == "isPlaying" {
                currentPlaying[key] = false as AnyObject
            }
            if key == "fileName" {
                currentPlaying[key] = value
            }
        }
        sections[(indexPath.section)].files[(indexPath.row)] = currentPlaying as Any
        self.recordingCell = self.tableView.cellForRow(at: indexPath) as! RecordingsTableViewCell
        self.recordingCell.loadingBar.frame.size.width = 0.0
        self.recordingCell.imageViewFrame.layer.position.x = 7.0
        self.recordingCell.playPauseBtn.setImage(self.playBtn, for: .normal)
        
        self.recordingCellLoadingBarWidth = 0.0
        self.loadingBar = 0.0
        self.duration = 0
        self.tempDuration = 0
        audioPlayer.stop()
    }
    
    @objc func pauseAnimateView(){
        self.recordingCell.loadingBar.frame.size.width = CGFloat(self.recordingCellLoadingBarWidth)
        //self.loadingBar = Double(self.recordingCell.loadingBar.frame.size.width)
        self.pausedAudioBar = Double(self.recordingCell.loadingBar.frame.size.width)
        
        let pausedDuration = self.recordingCell.durationLabel.text
        let string = String((pausedDuration?.suffix(1))!)
        self.duration = Int(string)!
    }
    
    @objc func animateView(_:Timer){
        if tempDuration==0{
            tempDuration = duration
            tempDuration = tempDuration - 1
        } else {
            tempDuration = tempDuration - 1
        }
        if loadingBar == 0.0 {
            UIView.animate(withDuration: 2, animations: {
                self.recordingCell.loadingBar.frame.size.width = self.recordingCell.whiteRoundedView.frame.width / CGFloat(self.duration)
                self.recordingCell.imageViewFrame.layer.position.x = self.recordingCell.loadingBar.frame.size.width
                self.loadingBar = Double(self.recordingCell.loadingBar.frame.size.width)
                self.recordingCellLoadingBarWidth = Double(self.recordingCell.loadingBar.frame.size.width)
                
                self.recordingCell.durationLabel.text? = "00:0\(self.tempDuration)"
                
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 2, animations: {
                self.recordingCell.loadingBar.frame.size.width = self.recordingCell.loadingBar.frame.size.width + CGFloat(self.loadingBar)
                self.recordingCell.imageViewFrame.layer.position.x =  self.recordingCell.loadingBar.frame.size.width + 7
                self.recordingCellLoadingBarWidth = Double(self.recordingCell.loadingBar.frame.size.width)
                self.recordingCell.durationLabel.text? = "00:0\(self.tempDuration)"
            }, completion: nil)
        }
        
        if Double(self.recordingCell.whiteRoundedView.frame.size.width) == Double(self.recordingCell.loadingBar.frame.size.width) {
            UIView.animate(withDuration: 2, animations: {
                self.recordingCell.imageViewFrame.layer.position.x =  self.recordingCell.loadingBar.frame.size.width - 7
            }, completion: nil)
            
            terminateTimer()
            loadingBar = 0.0
            self.recordingCell.durationLabel.text? = "00:00"
            
            let deadlineTime = DispatchTime.now() + .seconds(3)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                var temp = "00:00"
                if self.duration == 20 {
                    temp = "00:\(self.duration)"
                } else {
                    temp = "00:0\(self.duration)"
                }
                self.recordingCell.durationLabel.text? = temp
                self.recordingCell.loadingBar.frame.size.width = 0.0
                self.recordingCell.imageViewFrame.layer.position.x = 7.0
                self.recordingCell.playPauseBtn.setImage(self.playBtn, for: .normal)
                self.recordingCell.playPauseBtn.isSelected = false
                self.audioPlayer.stop()
            }
        }
    }
    func terminateTimer(){
        animateViewTimer.invalidate()
        self.tableView.isScrollEnabled = true
    }
}
