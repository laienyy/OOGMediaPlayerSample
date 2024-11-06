//
//  BGMItemTableViewCell.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/31.
//

import UIKit
import Lottie
import OOGMediaPlayer

class BGMItemTableViewCell: UITableViewCell {

    enum Status {
        case idle
        case downloading
        case playing
        case pause
    }
    
    // 白色背景
    let whiteBackgroundContainer = UIView()
    // 灰色背景
    let grayBackgroundView = UIView()
    
    let stackView = UIStackView()
    
    var playingStateView = LottieAnimationView()
    var downloadProgressStatusView = UILabel()
    var nameLabel = UILabel()
    var loopButton = UIButton(type: .custom)
    var favoriteButton = UIButton(type: .custom)
    let lockImageView = UIImageView(image: UIImage(named: "program_class_beginner_lock"))

    var bottomSeparatorLine = UIView()
    
    
    typealias CellCallback = (BGMItemTableViewCell) -> Void
    
    var favoriteAction: CellCallback?
    var loopAction: CellCallback?
    var lockAction: CellCallback?
    
    var lockTapGesture: UITapGestureRecognizer?
    
    public var isFavorite: Bool = false {
        didSet {
            favoriteButton.isSelected = isFavorite
        }
    }
    
    public var isLoop: Bool = false {
        didSet {
            loopButton.isSelected = isLoop
        }
    }
    
    public var isLock: Bool = false {
        didSet {
            lockImageView.isHidden = !isLock
            favoriteButton.isHidden = isLock
            loopButton.isHidden = isLock
            lockTapGesture?.isEnabled = isLock
            
            if isLock, lockTapGesture == nil {
                lockTapGesture = UITapGestureRecognizer(target: self, action: #selector(lockTapped))
                whiteBackgroundContainer.addGestureRecognizer(lockTapGesture!)
            }
        }
    }
    
    var cellStatus: Status = .idle {
        didSet {
            self.updateUIByStatus()
        }
    }
    
    var model: (any BGMSong)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        initialization()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initialization()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isLock = false
        
        model?.removeStatusObserver(self)
        model?.removeDownloadProgressObserver(self)
        
    }
    
    lazy var statusChangedAction: StatusChangedClosure = {
        return { [weak self] item, status in
            guard let `self` = self, let currentModel = self.model, currentModel.id == item.id else {
                return false
            }
            print("Status changed", status, item.fileName)
            self.updateStatusByModel()
            return true
        }
    }()
    
    
    
    
    func initialization() {
        
        contentView.backgroundColor = #colorLiteral(red: 0.9594742656, green: 0.956212461, blue: 0.9530892968, alpha: 1)
        
        whiteBackgroundContainer.backgroundColor = .white
        contentView.addSubview(whiteBackgroundContainer) { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16).priority(.high)
            make.top.equalToSuperview().priority(.high)
            make.bottom.equalToSuperview().priority(.high)
        }
        
//        stackView.distribution = .equalSpacing
//        stackView.alignment = .leading
        
        grayBackgroundView.backgroundColor = #colorLiteral(red: 0.9782040715, green: 0.9782039523, blue: 0.9782040715, alpha: 1)
        whiteBackgroundContainer.addSubview(grayBackgroundView) { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16).priority(.high)
            make.top.bottom.equalToSuperview().priority(.high)
        }
        
//        stackView.backgroundColor = .white
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        whiteBackgroundContainer.addSubview(stackView) { make in
            make.leading.equalToSuperview().offset(16 * 2.0)
            make.trailing.equalToSuperview().inset(16 * 2.0).priority(.high)
            make.height.equalTo(60)
            make.top.bottom.equalToSuperview().priority(.high)
        }
        
        nameLabel.font = .systemFont(ofSize: 15, weight: .medium)
        
        loadAnimationView()
        
        stackView.addArrangedSubview(playingStateView)
        stackView.addArrangedSubview(downloadProgressStatusView)
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(loopButton)
        stackView.addArrangedSubview(favoriteButton)
        stackView.addArrangedSubview(lockImageView)
        
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        loopButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        loopButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        favoriteButton.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        favoriteButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        playingStateView.snp.makeConstraints { make in
            make.width.height.equalTo(25)
        }
        
        downloadProgressStatusView.snp.makeConstraints { make in
            make.width.height.equalTo(25)
        }
        
        loopButton.snp.makeConstraints { make in
            make.width.equalTo(32)
            make.height.equalToSuperview()
        }
        
        favoriteButton.snp.makeConstraints { make in
            make.width.equalTo(32)
            make.height.equalToSuperview()
        }
        
        lockImageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }
        
        bottomSeparatorLine.backgroundColor = #colorLiteral(red: 0.9593991637, green: 0.9593990445, blue: 0.9593991637, alpha: 1)
        whiteBackgroundContainer.addSubview(bottomSeparatorLine) { make in
            make.leading.trailing.equalTo(stackView)
            make.bottom.equalToSuperview()
            make.height.equalTo(1.0)
        }
        
        playingStateView.isHidden = true
        downloadProgressStatusView.isHidden = true
        nameLabel.text = "Song"
        
        loopButton.setImage(UIImage(named: "bgm_single_loop"), for: .normal)
        loopButton.setImage(UIImage(named: "bgm_single_loop_selected"), for: .selected)
        loopButton.addTarget(self, action: #selector(loopButtonPressed), for: .touchUpInside)
        

        favoriteButton.setImage(UIImage(named: "vision_favorate_n"), for: .normal)
        favoriteButton.setImage(UIImage(named: "vision_favorate_s"), for: .selected)
        favoriteButton.addTarget(self, action: #selector(favoriteButtonPressed), for: .touchUpInside)
        
    }
    
    func loadAnimationView() {
        guard let path = Bundle.main.path(forResource: "bgm_playing", ofType: "json") else {
            return
        }
        playingStateView = LottieAnimationView(filePath: path)
        playingStateView.loopMode = .loop
    }
    
    @objc func loopButtonPressed() {
        loopAction?(self)
    }
    
    @objc func favoriteButtonPressed() {
        favoriteAction?(self)
    }
    
    @objc func lockTapped(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            lockAction?(self)
        }
    }
}

extension BGMItemTableViewCell {
    
    func load(_ song: any BGMSong) {
        model = song
        model?.observeStatusChanged(self, statusChangedAction)
        
        updateStatusByModel()
        nameLabel.text = song.displayName
    }
    
    func updateStatusByModel() {
        guard let status = self.model?.status else {
            self.cellStatus = .idle
            return
        }
        switch status {
        case .idle, .error, .stoped:
            self.cellStatus = .idle
        case .downloading:
            self.cellStatus = .downloading
        case .paused, .prepareToPlay:
            self.cellStatus = .pause
        case .playing:
            self.cellStatus = .playing
        @unknown default:
            break
        }
        
    }
    
    func handleDownloadAction() {
        
        if model?.downloadProgress.isDownloaded ?? true {
            downloadProgressStatusView.isHidden = true
            return
        }
        
        downloadProgressStatusView.isHidden = false
        
        model?.observeDownloadProgress(self) { [weak self] model, status in
            guard self?.model?.id == model.id else {
                return false
            }
            switch status {
            case .downloading(let progress):
                self?.downloadProgressStatusView.text = "\(Int(progress * 100))%"
            case .downloaded:
                self?.downloadProgressStatusView.text = "100%"
            default:
                break
            }
            
            return true
        }
    }
    
    func updateCorner(isFirst: Bool, isLast: Bool) {

        grayBackgroundView.layer.cornerRadius = 10
        grayBackgroundView.layer.masksToBounds = true
        
        if isFirst, isLast {
            grayBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if isFirst {
            grayBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            grayBackgroundView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            grayBackgroundView.layer.cornerRadius = 0
            grayBackgroundView.layer.masksToBounds = false
        }
        
        bottomSeparatorLine.isHidden = isLast
    }
    
    func updateUIByStatus() {
        
        downloadProgressStatusView.isHidden = true
        
        print("Update UI by status:", cellStatus, model?.displayName ?? "Null")
        
        switch cellStatus {
        case .downloading:
            handleDownloadAction()
        case .playing:
            playingStateView.isHidden = false
            playingStateView.play()
            nameLabel.textColor = #colorLiteral(red: 0.2341707945, green: 0.5062331557, blue: 0.3894308805, alpha: 1)
        case .pause:
            playingStateView.isHidden = false
            playingStateView.pause()
            nameLabel.textColor = #colorLiteral(red: 0.2341707945, green: 0.5062331557, blue: 0.3894308805, alpha: 1)
        case .idle:
            nameLabel.textColor = .black
            playingStateView.isHidden = true
            playingStateView.pause()
        }
    }
}
