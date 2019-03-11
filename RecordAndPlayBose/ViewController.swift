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
    let audioRecordingFileName = "audio_recordAndPlayApp.m4a"
    let viewBackgroundColor = UIColor(red: 3/255.0, green: 23/255.0, blue: 37/255.0, alpha: 1.0)
    let butttonBackgroundColor = UIColor(red: 59/255.0, green: 101/255.0, blue: 126/255.0, alpha: 1.0)
    
    var boseLogo: UIImageView!
    
    var playButton: UIButton!
    var recordButton: UIButton!
    var buttonsStackView: UIStackView!
    
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
        setupButtonsStackView()
        setupAudioRecorder()
    }
    
    private func initialSetup() {
        view.backgroundColor = viewBackgroundColor
        setupLogo()
    }
    
    private func setupLogo() {
        boseLogo = UIImageView(image: UIImage(named: "bose"))
        view.addSubview(boseLogo)
        boseLogo.translatesAutoresizingMaskIntoConstraints = false
//        boseLogo.contentMode = .scaleAspectFit
        let top = NSLayoutConstraint(item: boseLogo, attribute: .topMargin, relatedBy: .equal, toItem: view, attribute: .topMargin, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: boseLogo, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading , multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: boseLogo, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: boseLogo, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.20, constant: 0)
        view.addConstraints([top,leading,trailing,height])
    }
    
    private func setupButtonsStackView() {
        setupButtons()
        buttonsStackView = UIStackView(arrangedSubviews: [playButton,recordButton])
        view.addSubview(buttonsStackView)
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 25
        buttonsStackView.distribution = .fill
        let centerX = NSLayoutConstraint(item: buttonsStackView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: buttonsStackView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        view.addConstraints([centerX,centerY])
    }

    private func setupButtons() {
        playButton = UIButton()
        recordButton = UIButton()
        view.addSubview(playButton)
        view.addSubview(recordButton)
        playButton.isEnabled = false
        setHeightAndWidth(for: playButton)
        setHeightAndWidth(for: recordButton)
        playButton.layer.cornerRadius = 5
        recordButton.layer.cornerRadius = 5
        playButton.clipsToBounds = true
        recordButton.clipsToBounds = true
        playButton.setTitle("Play", for: .normal)
        playButton.setTitle("Pause", for: .selected)
        recordButton.setTitle("Record", for: .normal)
        recordButton.setTitle("Stop Recording", for: .selected)
        playButton.setTitleColor(.white, for: .normal)
        recordButton.setTitleColor(.white, for: .normal)
        playButton.backgroundColor = butttonBackgroundColor
        recordButton.backgroundColor = butttonBackgroundColor
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
        let height = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        let width = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 120)
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
}

extension ViewController: AVAudioPlayerDelegate {
    private func audioPlayer(play: Bool) {
        if play {
            do {
                guard let recordingURL = getRecordingURL() else { return }
                audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
                audioPlayer.numberOfLoops = -1
                audioPlayer.play()
            } catch let error {
                print("Error creating AVAudioPlayer - \(error)")
            }
        } else {
            audioPlayer.pause()
        }
    }
    
    private func getRecordingURL() -> URL? {
        let fileManager = FileManager.default
        do {
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            return documentsURL.appendingPathComponent(audioRecordingFileName)
        } catch let error {
            print("Error creating url to document directory - \(error)")
        }
        return nil
    }
}
