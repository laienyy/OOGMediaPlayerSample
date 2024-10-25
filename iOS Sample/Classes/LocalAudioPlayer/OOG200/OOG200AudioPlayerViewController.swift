//
//  OOG200AudioPlayerViewController.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/23.
//

import Foundation
import UIKit
import OOGMediaPlayer

class OOG200AudioPlayerViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var musicEnableSwitch: UISwitch!
    @IBOutlet weak var currentMusicNameLabel: UILabel!
    @IBOutlet weak var silenceButton: UIButton!
    @IBOutlet weak var fullVolumnButton: UIButton!
    @IBOutlet weak var volumnSlider: UISlider!
    
    @IBOutlet weak var cacheEnableSwitch: UISwitch!
    @IBOutlet weak var mixOtherSwitch: UISwitch!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    // 随机播放按钮
    @IBOutlet weak var shufflePlayButton: UIButton!
    
    
    var updateTimeTimer: Timer?
    
    var settings = OOGAudioPlayerSettings(scheme: .bgm)
    
    let playerProvider: OOGAudioPlayerProvider = .init()
    
    deinit {
        print(OOG200AudioPlayerViewController.classNameStr, "deinit")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        syncSubsubviewsContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 完全显示才重新设置delegate
        playerProvider.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        destoryTimer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateVolumnSlider()
        startActivityIndicator(false)
        
        
        playerProvider.delegate = self
//
        loadPlayer()
        syncSubsubviewsContent()
    }
    
    func loadPlayer() {
        Task {
            do {
                try await playerProvider.getMusics(.oog200, [.animation], playAutomatically: false)
                
                if let previousPlayingAudioId = settings.currentAudioID,
                   let indexPath = playerProvider.indexPathOf(itemID: previousPlayingAudioId) {
                    // 继续播放之前播放的歌曲
                    playerProvider.play(indexPath: indexPath)
                } else {
                    // 播放下一曲
                    playerProvider.playNext()
                }
                
            } catch let error {
                statusLabel.text = "获取歌曲列表失败，错误：\(error.localizedDescription)"
            }
        }
        
    }
    
    // 根据播放器当前状态，更新视图显示
    func syncSubsubviewsContent() {
        
        // 更新当前歌曲名称
        currentMusicNameLabel.text = playerProvider.currentSong()?.displayName ?? "无"
        // 更新是否使用缓存
        cacheEnableSwitch.isOn = settings.isEnableCache
        // 更新播放器设置
        playerProvider.isUseCache = settings.isEnableCache
        // 更新音量
        playerProvider.volumn = settings.volumn
        // 更新音量滑条
        volumnSlider.value = settings.volumn
        
        // 更新随机播放模式按钮
        shufflePlayButton.isSelected = playerProvider.loopMode == .random
        // 更新播放按钮
        playButton.isSelected = playerProvider.playerStatus == .playing
        
        
        // 更新activity
        if let currentSong = playerProvider.currentSong() {
            switch currentSong.status {
            case .idle, .playing, .paused, .stoped, .error:
                startActivityIndicator(false)
            case .downloading, .prepareToPlay:
                startActivityIndicator(true)
            @unknown default:
                startActivityIndicator(false)
            }
        } else {
            startActivityIndicator(false)
        }
        
        // 更新状态栏
        switch playerProvider.playerStatus {
        case .stoped:
            statusLabel.text = "停止播放"
        case .prepareToPlay:
            statusLabel.text = "准备播放"
        case .playing, .paused, .finished, .error:
            let indexPath = playerProvider.currentIndexPath
            let media = playerProvider.currentSong()
            let statusStr = playerProvider.playerStatus.userInterfaceDisplay()
            statusLabel.text = "\(statusStr) - \(media?.fileName ?? "未知") \(indexPath?.descriptionForPlayer ?? "None")"
        @unknown default:
            break
        }
        
        // 更新播放时间
        updateTimeLable()
        if playerProvider.playerStatus == .playing {
            // 开始自动更新播放时间
            startUpdateTimeLabel()
        }
    }
    
    func startUpdateTimeLabel() {
        guard updateTimeTimer == nil else {
            return
        }
        
        updateTimeTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] timer in
            guard let `self` = self else {
                timer.invalidate()
                return
            }
            self.updateTimeLable()
        })
    }
    
    func updateTimeLable() {
        
        guard let song = playerProvider.currentSong(), var duration = song.audioDuration else {
            timeLabel.text = "— / —"
            return
        }
        
        duration /= 1000
        let durationStr = String(format: "%02ld:%02ld", duration / 60, duration % 60)
        let currentTime = Int(playerProvider.currentTime)
        let currentTimeStr = String(format: "%02ld:%02ld", currentTime / 60, currentTime % 60)
        timeLabel.text = currentTimeStr + " / " + durationStr
    }
    
    func resetTimeLabel() {
        timeLabel.text = "— / —"
    }

    func destoryTimer() {
        updateTimeTimer?.invalidate()
        updateTimeTimer = nil
    }
    
    @IBAction func popViewController(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playerEnableSwitchValueChanged(_ sender: UISwitch) {
        
        if sender.isOn {
            playerProvider.play()
            settings.isEnablePlayer = true
        } else {
            playerProvider.pause()
            settings.isEnablePlayer = false
        }

    }
    
    func startActivityIndicator(_ start: Bool) {
        if start {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        } else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
        }
    }
    
    func updateVolumnSlider() {
        volumnSlider.setValue(playerProvider.volumn, animated: true)
//        volumnSlider.value = playerProvider.volumn
    }
    @IBAction func volumnSliderValueDidChanged(_ sender: Any) {
        playerProvider.volumn = volumnSlider.value
        settings.volumn = volumnSlider.value
    }
    @IBAction func silenceButtonPressed(_ sender: Any) {
        playerProvider.volumn = 0
        volumnSlider.setValue(0, animated: true)
    }
    
    @IBAction func fullVolumnButtonPressed(_ sender: Any) {
        playerProvider.volumn = 1
        volumnSlider.setValue(1, animated: true)
    }
    
    @IBAction func showAlbumList(_ sender: Any) {
        let vc = OOG200AudioListViewController(playerProvider: playerProvider)
        vc.albums = playerProvider.albumList
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func cacheSwitchValueChanged(_ sender: UISwitch) {
        settings.isEnableCache = sender.isOn
        playerProvider.isUseCache = settings.isEnableCache
        
//        playerProvider.albumList = playerProvider.albumList.map { albulm in
//            var album = albulm
//            var list = album.mediaList.map { song in
//                var song = song
//                song.useCache = isUseCache
//                return song
//            }
//            album.mediaList = list
//            return album
//        }
        
    }
    
    @IBAction func mixOtherAudioSwitchValueChanged(_ sender: UISwitch) {
        
        if sender.isOn {
            LocalAudioPlayerProvider.dukeOtherAudio()
        } else {
            LocalAudioPlayerProvider.mixOtherAudio()
        }
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if sender.isSelected {
            playerProvider.pause()
        } else {
            playerProvider.play()
        }
    }
    
    @IBAction func forwardButtonPressed(_ sender: UIButton) {
        playerProvider.playNext()
    }
    
    @IBAction func backwardButtonPressed(_ sender: UIButton) {
        playerProvider.playPrevious()
    }
    
    @IBAction func shuffleButtonPressed(_ sender: UIButton) {
        let isShufflePlayMode = sender.isSelected
        playerProvider.loopMode = isShufflePlayMode ? .order : .random
        sender.isSelected = !sender.isSelected
    }
    
}

extension OOG200AudioPlayerViewController: MediaPlayerProviderDelegate {
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, at indexPath: IndexPath?, playForwardError error: any Error) {
        
        if indexPath != nil, playerProvider.currentIndexPath != indexPath {
            return
        }
        
        startActivityIndicator(false)
        
        guard let indexPath = indexPath else {
            statusLabel.text = "播放上一曲失败，错误：\(error.localizedDescription)"
            return
        }
        
        if let media = playerProvider.getSong(at: indexPath) {
            statusLabel.text = "播放 - `\(media.fileName)`；失败，错误：\(error.localizedDescription)"
        } else {
            statusLabel.text = "播放 - 未知歌曲 - 失败，未知错误"
        }
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, at indexPath: IndexPath?, playBackwardError error: any Error) {
        
        if indexPath != nil, playerProvider.currentIndexPath != indexPath {
            return
        }
        
        guard let indexPath = indexPath else {
            return
        }
        
        if let media = playerProvider.getSong(at: indexPath) {
            statusLabel.text = "播放 - `\(media.fileName)`；失败，错误：\(error.localizedDescription)"
        } else {
            statusLabel.text = "播放 - 未知歌曲；失败，未知错误"
        }
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, shouldPlay indexPath: IndexPath) -> IndexPath? {
        
        resetTimeLabel()
        
        guard let media = playerProvider.getSong(at: indexPath) else {
            currentMusicNameLabel.text = "无"
            return indexPath
        }
        currentMusicNameLabel.text = media.displayName ?? "未命名"
        startActivityIndicator(true)
        
        return indexPath
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, willPlay indexPath: IndexPath) {
        guard let media = playerProvider.getSong(at: indexPath) else {
            return
        }
        statusLabel.text = "正在加载 - \(media.fileName) [\(indexPath.section) - \(indexPath.row)]"
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, startPlaying indexPath: IndexPath) {
        
        updateVolumnSlider()
        startActivityIndicator(false)
        
        guard let media = playerProvider.getSong(at: indexPath) else {
            return
        }
        
        //        print("Playing `\(media.name)`, at [\(indexPath.section), \(indexPath.row)]")
        statusLabel.text = "正在播放 - \(media.fileName) [\(indexPath.section) - \(indexPath.row)]"
        settings.currentAudioID = media.id
    }
    
    func mediaPlayerControlStatusDidChanged(_ provider: MediaPlayerControl) {
        let status = provider.playerStatus
        
        playButton.isSelected = status == .playing
        
        if status == .playing {
            playButton.setImage(.init(systemName: "pause.fill"), for: .selected)
        } else {
            
            playButton.setImage(.init(systemName: "play.fill"), for: .normal)
            
            if let indexPath = playerProvider.currentIndexPath, let media = playerProvider.currentItem() {
                if status == .paused {
                    statusLabel.text = "\(status.userInterfaceDisplay()) - \(media.fileName) [\(indexPath.section) - \(indexPath.row)]"
                }
            }
        }
        
        
        switch status {
        case .playing:
            startUpdateTimeLabel()
            
        case .prepareToPlay, .error:
            updateTimeLable()
            fallthrough
            
        case .paused, .stoped, .finished:
            destoryTimer()
        @unknown default:
            destoryTimer()
        }
        
    }
    
}
