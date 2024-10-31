//
//  OOG200AudioListViewController.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/23.
//

import UIKit
import OOGMediaPlayer

class OOG200AudioListViewController: UIViewController, AudioPlayerOwner {

    var playerProvider: OOGAudioPlayerProvider
    var albums = [any BGMAlbum]()
    var settings = OOGAudioPlayerSettings.loadScheme(.bgm)
    
    let tableView = UITableView(frame: UIScreen.main.bounds, style: .grouped)
    
    init(playerProvider: OOGAudioPlayerProvider, albums: [any BGMAlbum] = [any BGMAlbum]()) {
        self.playerProvider = playerProvider
        self.albums = albums
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        playerProvider.playDesignatedLoopSongIfNeeds(settings: settings)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.registerHeaderFooterFromClass(AudioAlbumTableHeaderFooterView.self)
        tableView.registerFromNib(AudioTableViewCell.self)
        tableView.register(BGMAlbumTableHeaderView.self, forHeaderFooterViewReuseIdentifier: "header")
        tableView.registerCellFromClass(BGMItemTableViewCell.self)
        tableView.estimatedSectionHeaderHeight = 70
        tableView.estimatedRowHeight = 70
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = #colorLiteral(red: 0.9594742656, green: 0.956212461, blue: 0.9530892968, alpha: 1)
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
        
        let cell: BGMItemTableViewCell = .reuse(from: tableView)
        
        let song = albums[indexPath.section].mediaList[indexPath.row]
        
        let isCurrent = playerProvider.currentIndexPath == indexPath
        let isLoop = isLoop(song: song)
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row + 1 == albums[indexPath.section].mediaList.count
        
        cell.load(song)
        cell.set(isFirst: isFirst, isLast: isLast)
        cell.setFavorite(settings.isFavorite(song))
        cell.setLoop(settings.isLoop(song))
          
        cell.loopAction = { [weak self] cell in
            guard let `self` = self else { return }
            let isLoop = cell.loopButton.isSelected
            if isLoop {
                // 取消循环
                self.setPlayerLoop(mode: .order)
            } else {
                // 单曲循环
                self.setPlayerSingleLoop(song: song)
            }
            // 刷新循环选中按钮状态
            self.tableView.reloadData()
        }
        
        cell.favoriteAction = { [weak self] cell in
            guard let `self` = self else { return }
            let isFavorite = self.settings.isFavorite(song)
            self.settings.setFavorite(for: song, !isFavorite)
            
            cell.setFavorite(!isFavorite)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header: BGMAlbumTableHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as! BGMAlbumTableHeaderView
        header.headerContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        header.headerContentView.layer.cornerRadius = section == 0 ? 8 : 0
        
        let album = albums[section]
        header.titleLabel.text = album.name
        header.subtitleLabel.text = "\(album.mediaList.count) 歌曲"
        header.setLoop(settings.isAlbumLoop(album))
        
        let isCurrentAlbumLoop = playerProvider.loopMode == .album && settings.loopDesignateAlbumID == album.id
        header.loopButton.isSelected = isCurrentAlbumLoop
        header.loopAction = { [weak self] header in
            guard let `self` = self else { return }
            
            let isLoop = header.loopButton.isSelected
            if isLoop {
                self.setPlayerLoop(mode: .order)
            } else {
                self.setPlayerAlbumLoop(album: album)
            }
            
            // 刷新循环选中按钮状态
            self.tableView.reloadData()
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = tableView.backgroundColor
        
        let whiteView = UIView()
        whiteView.backgroundColor = .white
        whiteView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        whiteView.layer.masksToBounds = true
        
        if albums.count - 1 == section {
            footer.frame = .init(x: 0, y: 0, width: tableView.frame.width, height: 16)
            whiteView.frame = .init(x: 16, y: 0, width: tableView.frame.width - 32, height: 16)
            whiteView.layer.cornerRadius = 8
        } else {
            footer.frame = .init(x: 0, y: 0, width: tableView.frame.width, height: 0.01)
            whiteView.frame = .init(x: 16, y: 0, width: tableView.frame.width - 32, height: 0.01)
            whiteView.layer.cornerRadius = 0
        }
        
        footer.addSubview(whiteView)
        return footer
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath != playerProvider.currentIndexPath else {
            
            if playerProvider.playerStatus == .playing {
                playerProvider.pause()
            } else {
                playerProvider.play()
            }
            
            return
        }
        
        playerProvider.play(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if albums.count - 1 == section {
            return 16
        } else {
            return 0.01
        }
    }
    
}

extension OOG200AudioListViewController: MediaPlayerProviderDelegate {
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, shouldPlay indexPath: IndexPath, current: IndexPath?) -> IndexPath? {
        
        if let current = current,
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
        
        guard albums.count > indexPath.section, albums[indexPath.section].mediaList.count > indexPath.row else {
            return
        }
        
        settings.currentAudioID = albums[indexPath.section].mediaList[indexPath.row].id
        try? settings.save()
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, playAt indexPath: IndexPath?, error: any Error) {
        print("[ERR] Play \(indexPath?.descriptionForPlayer ?? "-") failed, response", error.localizedDescription)
    }
    
    func mediaPlayerControlStatusDidChanged(_ provider: MediaPlayerControl) {
        let status = provider.playerStatus
        print("Player status -", status.userInterfaceDisplay())
    }
    
}
