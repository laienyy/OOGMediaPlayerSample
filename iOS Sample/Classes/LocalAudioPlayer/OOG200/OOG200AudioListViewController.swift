//
//  OOG200AudioListViewController.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/23.
//

import UIKit
import OOGMediaPlayer

class OOG200AudioListViewController: UIViewController {

    var playerProvider: OOGAudioPlayerProvider
    var albums = [any BGMAlbum]()
    
    let tableView = UITableView(frame: UIScreen.main.bounds, style: .plain)
    
    init(playerProvider: OOGAudioPlayerProvider, albums: [any BGMAlbum] = [any BGMAlbum]()) {
        self.playerProvider = playerProvider
        self.albums = albums
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.registerHeaderFooterFromClass(AudioAlbumTableHeaderFooterView.self)
        tableView.registerFromNib(AudioTableViewCell.self)
        tableView.estimatedSectionHeaderHeight = 70
        tableView.estimatedRowHeight = 70
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        playerProvider.delegate = self
        
    }
    
}

extension OOG200AudioListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums[section].mediaList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let song = albums[indexPath.section].mediaList[indexPath.row]
        
        let isCurrent = playerProvider.currentIndexPath == indexPath
        let isLoop = isCurrent && playerProvider.loopMode == .single
        
        let cell: AudioTableViewCell = tableView.dequeueReusableCell()
        cell.loadModel(song, isLoop: isLoop)
        cell.setIsCurrentPlay(isCurrent)
        
        cell.loopAction = { [weak self] cell in
            guard let `self` = self else { return }
            
            let isLoop = cell.loopButton.isSelected
            self.playerProvider.loopMode = isLoop ? .order : .single
            
            if !isLoop {
                // 修改循环模式
                self.playerProvider.loopMode = .single
                
                // 未播放本曲目时，使播放器播放此曲
                if self.playerProvider.currentIndexPath != indexPath {
                    self.playerProvider.play(indexPath: indexPath)
                }
            }
            
            // 刷新循环选中按钮状态
            self.tableView.reloadData()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header: AudioAlbumTableHeaderFooterView = .fromNib()
        
        let album = albums[section]
        header.nameLabel.text = album.name
        header.descriptionLabel.text = "\(album.mediaList.count) 歌曲"
        
        let isCurrentAlbumLoop = playerProvider.loopMode == .album && playerProvider.currentIndexPath?.section == section
        header.loopButton.isSelected = isCurrentAlbumLoop
        header.loopAction = { [weak self] header in
            guard let `self` = self else { return }
            
            let isLoop = header.loopButton.isSelected
            
            self.playerProvider.loopMode = isLoop ? .order : .album
            
            let isCurrentAlbum = self.playerProvider.currentIndexPath?.section == section
            if !isCurrentAlbum {
                // 循环播放当前专辑
                playerProvider.play(indexPath: .init(row: 0, section: section))
            }
            
            // 刷新循环选中按钮状态
            self.tableView.reloadData()
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath != playerProvider.currentIndexPath else {
            return
        }
        
        playerProvider.play(indexPath: indexPath)
        tableView.reloadData()
    }
}

extension OOG200AudioListViewController: MediaPlayerProviderDelegate {
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, shouldPlay indexPath: IndexPath) -> IndexPath? {
        
        if let current = playerProvider.currentIndexPath,
           let cell = tableView.cellForRow(at: current) as? AudioTableViewCell {
            // 即将播放其他曲目时，将正在播放的 cell 置为当前未播放
            cell.setIsCurrentPlay(false)
        }
        return indexPath
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, willPlay indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? AudioTableViewCell {
            // 将正在 cell 置为正在播放
            cell.setIsCurrentPlay(true)
        }
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, at indexPath: IndexPath?, playForwardError error: any Error) {
        print("[ERR] Play \(indexPath?.descriptionForPlayer) failed, response", error.localizedDescription)
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, at indexPath: IndexPath?, playBackwardError error: any Error) {
        print("[ERR] Play \(indexPath?.descriptionForPlayer) failed, response", error.localizedDescription)
    }
    
    func mediaPlayerControlStatusDidChanged(_ provider: MediaPlayerControl) {
        let status = provider.playerStatus
        print("Player status -", status.userInterfaceDisplay())
    }
    
}
