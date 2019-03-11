//
//  ViewController.swift
//  RecordAndPlayBose
//
//  Created by Armando Gonzalez on 3/7/19.
//  Copyright © 2019 Armando Gonzalez. All rights reserved.
//

import UIKit
import AVFoundation
import CoreBluetooth

class ViewController: UIViewController {
    let songKeyPath = "currentSong"
    let audioRecordingFileName = "audio_recordAndPlayApp.m4a"

    var playButton: UIButton!
    var recordButton: UIButton!
    var stackView: UIStackView!
    
    var audioSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var centralManager: CBCentralManager!
    var headPhonePeripheral: CBPeripheral!
    
    var recording: AVPlayerItem!
    var audioPlayer: AVAudioPlayer!
    
    var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
        setupStackView()
        setupAudioRecorder()
    }
    
    private func initialSetup() {
        view.backgroundColor = .white
    }

    private func setupStackView() {
        setupButtons()
        stackView = UIStackView(arrangedSubviews: [playButton,recordButton])
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 25
        stackView.distribution = .fill
        let centerX = NSLayoutConstraint(item: stackView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: stackView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        view.addConstraints([centerX,centerY])
    }
    
    private func addCenterConstraints(for sv: UIStackView) {
        
    }

    private func setupButtons() {
        playButton = UIButton()
        recordButton = UIButton()
        view.addSubview(playButton)
        view.addSubview(recordButton)
        playButton.isEnabled = false
        setHeightAndWidth(for: playButton)
        setHeightAndWidth(for: recordButton)
        playButton.layer.cornerRadius = 12
        recordButton.layer.cornerRadius = 12
        playButton.clipsToBounds = true
        recordButton.clipsToBounds = true
        playButton.setTitle("Play", for: .normal)
        playButton.setTitle("Pause", for: .selected)
        recordButton.setTitle("Record", for: .normal)
        recordButton.setTitle("Stop Recording", for: .selected)
        playButton.setTitleColor(.black, for: .normal)
        recordButton.setTitleColor(.black, for: .normal)
        playButton.backgroundColor = .green
        recordButton.backgroundColor = .red
        playButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        setHeightAndWidth(for: playButton)
        setHeightAndWidth(for: recordButton)
        playButton.addTarget(self, action: #selector(toggleButtons(_:)), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(toggleButtons(_:)), for: .touchUpInside)
    }
    
    @objc func toggleButtons(_ button: UIButton!) {
        switch (button == playButton, button.isSelected) {
        case (true,true):
            audioPlayer(play: false)
            playButton.isSelected = false
            recordButton.isEnabled = true
        case (true, false):
            playButton.isSelected = true
            recordButton.isEnabled = false
            audioPlayer(play: true)
        case (false, true):
            audioRecorder.stop()
            recordButton.isSelected = false
            playButton.isEnabled = true
        case (false, false):
            recordButton.isSelected = true
            playButton.isEnabled = false
            audioRecorder.record()
        }
    }
    
    private func setHeightAndWidth(for button: UIButton) {
        let height = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25)
        let width = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 125)
        view.addConstraints([height,width])
    }
}

extension ViewController: AVAudioRecorderDelegate {
    private func setupAudioRecorder() {
        let audioFilePathURL = documentsDirectory.appendingPathComponent(audioRecordingFileName)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePathURL, settings: settings)
            audioRecorder.delegate = self
        } catch let error{
            print("Could not setup audio recorder - \(error)")
        }
    }
    private func getRecordingURL() -> URL {
        let fileManager = FileManager.default
        let documentsURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        return documentsURL.appendingPathComponent(audioRecordingFileName)
    }
}

extension ViewController: AVAudioPlayerDelegate {
    private func audioPlayer(play: Bool) {
        if play {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: getRecordingURL())
            } catch let error {
                print("Error creating audio player - \(error)")
            }
            audioPlayer.numberOfLoops = -1
            audioPlayer.play()
            print("Playing audio")
        } else {
            audioPlayer.pause()
            print("Audio paused")
        }
    }
}
