//
//  OOG200AudioListViewController.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/23.
//

import UIKit
import OOGMediaPlayer

private let favoriteAlbumID = -1

class OOG200AudioListViewController: UIViewController, AudioPlayerOwner {

    typealias Album = AudioAlbumModel
    
    var playerProvider: OOGAudioPlayerProvider<Album>
    var albums: [Album] {
        get { playerProvider.albumList }
        set { playerProvider.albumList = newValue }
    }
    
    lazy var favAlbum: AudioAlbumModel = {
        var album = AudioAlbumModel()
        album.playlistName = "我最喜欢的"
        album.id = favoriteAlbumID
        album.localCoverImage = UIImage(named: "bgm_my_fav")
        return album
    }()
    
    var settings = OOGAudioPlayerSettings.loadScheme(.bgm)
    
    let tableView = UITableView(frame: UIScreen.main.bounds, style: .grouped)
    let tableHeaderView = BGMAlbumTableHeaderView()
    
    var foldAlbumList = Set<Int>()
    
    
    init(playerProvider: OOGAudioPlayerProvider<Album>) {
        self.playerProvider = playerProvider
        
        super.init(nibName: nil, bundle: nil)
        self.albums = playerProvider.albumList
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
        
        
//        if albums.count > 0 {
//            self.albums = [albums[0]]
//        }
        
        playerProvider.delegate = self
        
//        tableView.registerHeaderFooterFromClass(AudioAlbumTableHeaderFooterView.self)
        tableView.registerHeaderFooterFromClass(BGMAlbumTableSectionHeaderView.self)
        tableView.registerHeaderFooterFromClass(BGMAlbumTableSectionFooterView.self)
        tableView.registerCellFromClass(BGMItemTableViewCell.self)
        tableView.estimatedSectionHeaderHeight = 70
        tableView.estimatedRowHeight = 70
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = #colorLiteral(red: 0.9594742656, green: 0.956212461, blue: 0.9530892968, alpha: 1)
        view.addSubview(tableView)
        
        tableHeaderView.titleLabel.text = "全部随机播放"
        let screenSize = UIScreen.main.bounds.size
        var size = tableHeaderView.systemLayoutSizeFitting(screenSize)
        size.width = screenSize.width
        tableHeaderView.frame = .init(origin: .zero, size: size)
        tableView.tableHeaderView = tableHeaderView
        
        loadFavoriteAlbum()
    }
    
    func loadFavoriteAlbum() {
    
        let songs = albums.flatMap({ $0.mediaList })
        let favSongs = settings.favoriteList.compactMap { id in
            return songs.first(where: { $0.id == id })
        }
        
        guard favSongs.count > 0 else {
            return
        }
        
        favAlbum.mediaList = favSongs
        if albums.first?.id != favAlbum.id {
            albums.insert(favAlbum, at: 0)
            playerProvider.albumList = albums
        }
        
        guard isViewLoaded else {
            return
        }
    
        tableView.reloadData()
    }
    
    func isFold(section: Int) -> Bool {
        let album = albums[section]
        return foldAlbumList.contains(album.id)
    }
    
    func setFold(_ fold: Bool, album: any BGMAlbum) {
        if fold {
            foldAlbumList.insert(album.id)
        } else {
            foldAlbumList.remove(album.id)
        }
    }
    
    // album - 传入点击所属的album对象
    func favAlbumAddItem(_ item: AudioModel, album: AudioAlbumModel) {
        
        settings.setFavorite(for: item, true)
        guard !favAlbum.mediaList.contains(where: { $0.id == item.id }) else {
            return
        }
        
        let isAlbumHidden = favAlbum.mediaList.count == 0
        
        if isAlbumHidden {
            albums.insert(favAlbum, at: 0)
        }
        playerProvider.albumList = albums
        favAlbum.mediaList.append(item)
        tableView.performBatchUpdates {
            if isAlbumHidden {
                tableView.insertSections([0], with: .automatic)
            } else {
                tableView.insertRows(at: [.init(row: favAlbum.mediaList.count - 1, section: 0)], with: .bottom)
                tableView.reloadSections([0], with: .automatic)
            }
        } completion: { [weak self] finished in
            if album.id == favoriteAlbumID {
                // 点击的如果是《喜欢的》专辑，需要刷新其他section的喜欢状态
                self?.tableView.reloadData()
            }
        }
    }
    
    // album - 传入点击所属的album对象
    func favAlbumRemoveItem(_ item: AudioModel, album: AudioAlbumModel) {
        
        settings.setFavorite(for: item, false)
        
        guard let index = favAlbum.mediaList.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        let isAlbumWillHidden = favAlbum.mediaList.count == 1
        
        if isAlbumWillHidden {
            albums.removeAll(where: { $0.id == favAlbum.id })
        }
        
        playerProvider.albumList = albums
        favAlbum.mediaList.remove(at: index)
        tableView.performBatchUpdates {
            if isAlbumWillHidden {
                tableView.deleteSections([0], with: .automatic)
            } else {
                tableView.deleteRows(at: [.init(row: index, section: 0)], with: .top)
            }
        } completion: { [weak self] finished in
            if album.id == favoriteAlbumID {
                // 点击的如果是《喜欢的》专辑，需要刷新其他section的喜欢状态
                self?.tableView.reloadData()
            }
        }
        
    }
    
}

extension OOG200AudioListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let fold = isFold(section: section)
        return fold ? 0 : albums[section].mediaList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: BGMItemTableViewCell = .reuse(from: tableView)
        
        let album = albums[indexPath.section]
        let song = album.mediaList[indexPath.row]
        
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row + 1 == albums[indexPath.section].mediaList.count
        
        cell.load(song)
        cell.updateCorner(isFirst: isFirst, isLast: isLast)
        cell.isFavorite = isFavorite(song: song)
        cell.isLoop = isLoop(song: song)
        cell.isLock = song.subscription
        cell.loopAction = { [weak self] cell in
            guard let `self` = self, cell.model?.id == song.id else { return }
            
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
            guard let `self` = self, cell.model?.id == song.id else { return }
            
            let isFavorite = self.settings.isFavorite(song)
            if album.id != favoriteAlbumID {
                cell.isFavorite = !isFavorite
            }
            if !isFavorite == true {
                favAlbumAddItem(song, album: album)
            } else {
                favAlbumRemoveItem(song, album: album)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath != playerProvider.currentIndexPath else {
            
            print("Current ID \(playerProvider.currentItem()?.id ?? -10), selected ID \(playerProvider.getSong(at: indexPath)?.id ?? -11)")
            
            if playerProvider.playerStatus == .playing {
                playerProvider.pause()
            } else {
                playerProvider.play()
            }
            
            return
        }
        
        playerProvider.play(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header: BGMAlbumTableSectionHeaderView = .reuse(from: tableView)
        
        let album = albums[section]
        let isLoop = isLoop(album: album)
        
        let isFirst = section == 0
        let isLast = section + 1 == albums.count
        let isFold = isFold(section: section)
        
        header.updateCorner(isFirst: isFirst, isLast: isLast, isFold: isFold)
        
        header.titleLabel.text = album.name
        header.subtitleLabel.text = "\(album.mediaList.count) 歌曲"
        
        header.isLoop = isLoop
        header.loopAction = { [weak self] header in
            guard let `self` = self else { return }
            
            let isLoop = header.isLoop
            if isLoop {
                self.setPlayerLoop(mode: .order)
            } else {
                self.setPlayerAlbumLoop(album: album)
            }
            
            // 刷新循环选中按钮状态
            self.tableView.reloadData()
        }
        
        header.isFold = isFold
        header.foldAction = { [weak self] header in
            guard let `self` = self else { return }
            let isFold = header.isFold
            if isFold {
                // 展开
                self.setFold(false, album: album)
            } else {
                // 收起
                self.setFold(true, album: album)
            }
            self.tableView.reloadData()
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let height = self.tableView(tableView, heightForFooterInSection: section)
        let footer: BGMAlbumTableSectionFooterView = .reuse(from: tableView)
        footer.isLast = section + 1 == albums.count
        footer.frame = .init(x: 0, y: 0, width: tableView.frame.width, height: height)
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let isLast = section + 1 == albums.count
        
        if isLast {
            return isFold(section: section) ? 0.01 : 16.0
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
