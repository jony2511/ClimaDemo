//
//  PlayerViewController.swift
//  ClimaBeats
//
//  
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController, AVAudioPlayerDelegate {

    public var position: Int = 0
    public var songs: [Song] = []
    
    @IBOutlet var holder: UIView!
    
    var player: AVAudioPlayer?
    var progressTimer: Timer?
    
    // Shuffle & Repeat state
    var isShuffleOn = false
    var repeatMode: RepeatMode = .off // off → all → one
    
    enum RepeatMode {
        case off, all, one
    }
    
    // User Interface elements
    
    private let albumImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        return imageView
    }()
    
    private let songNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont(name: "Helvetica-Bold", size: 20)
        return label
    }()
    
    private let artistNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont(name: "Helvetica", size: 16)
        label.textColor = .darkGray
        return label
    }()
    
    private let albumNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont(name: "Helvetica", size: 14)
        label.textColor = .gray
        return label
    }()
    
    let playPauseButton = UIButton()
    let favoriteButton = UIButton()
    let shuffleButton = UIButton()
    let repeatButton = UIButton()
    let progressSlider = UISlider()
    let elapsedTimeLabel = UILabel()
    let remainingTimeLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    var isFavorited = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if holder.subviews.count == 0 {
            configure()
        }
    }
    
    func configure(){
        // Stop previous timer
        progressTimer?.invalidate()
        
        let song = songs[position]
        let playbackURL = resolvePlaybackURL(for: song)
        
        do {
            try AVAudioSession.sharedInstance().setMode(.default)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            guard let playbackURL = playbackURL else {
                print("Playable URL is nil")
                return
            }
            
            player = try AVAudioPlayer(contentsOf: playbackURL)
            guard let player = player else {
                print("player is nil")
                return
            }
            
            player.delegate = self
            player.volume = 0.5
            player.play()
        }
        catch {
            print("error occurred")
        }
        
        // ====== UI LAYOUT ======
        let holderWidth = holder.frame.size.width

        configureCloseButton()
        
        // Album cover
        let imageSize = holderWidth - 40
        albumImageView.frame = CGRect(x: 20, y: 10, width: imageSize, height: imageSize)
        albumImageView.image = UIImage(named: song.imageName) ?? UIImage(named: "song_cover")
        holder.addSubview(albumImageView)
        
        // Song name
        let labelsY = albumImageView.frame.maxY + 5
        songNameLabel.frame = CGRect(x: 10, y: labelsY, width: holderWidth - 20, height: 30)
        songNameLabel.text = song.name
        holder.addSubview(songNameLabel)
        
        // Artist name
        artistNameLabel.frame = CGRect(x: 10, y: labelsY + 28, width: holderWidth - 20, height: 25)
        artistNameLabel.text = song.artistName
        holder.addSubview(artistNameLabel)
        
        // Album name
        albumNameLabel.frame = CGRect(x: 10, y: labelsY + 50, width: holderWidth - 20, height: 22)
        albumNameLabel.text = song.albumName
        holder.addSubview(albumNameLabel)
        
        // ====== PROGRESS BAR (Phase 4) ======
        let progressY = albumNameLabel.frame.maxY + 10
        
        // Elapsed time label
        elapsedTimeLabel.frame = CGRect(x: 20, y: progressY, width: 50, height: 20)
        elapsedTimeLabel.text = "0:00"
        elapsedTimeLabel.font = UIFont(name: "Helvetica", size: 12)
        elapsedTimeLabel.textColor = .gray
        holder.addSubview(elapsedTimeLabel)
        
        // Remaining time label
        remainingTimeLabel.frame = CGRect(x: holderWidth - 70, y: progressY, width: 50, height: 20)
        remainingTimeLabel.text = "0:00"
        remainingTimeLabel.textAlignment = .right
        remainingTimeLabel.font = UIFont(name: "Helvetica", size: 12)
        remainingTimeLabel.textColor = .gray
        holder.addSubview(remainingTimeLabel)
        
        // Progress slider
        progressSlider.frame = CGRect(x: 20, y: progressY + 18, width: holderWidth - 40, height: 20)
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.minimumTrackTintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        progressSlider.addTarget(self, action: #selector(didSeek(_:)), for: .valueChanged)
        holder.addSubview(progressSlider)
        
        // Start progress timer
        progressTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        
        // ====== PLAYER CONTROLS ======
        let controlsY = progressSlider.frame.maxY + 15
        let size: CGFloat = 50
        
        let nextButton = UIButton()
        let backButton = UIButton()
        
        // Shuffle button (Phase 6)
        shuffleButton.frame = CGRect(x: 20, y: controlsY + 10, width: 30, height: 30)
        shuffleButton.setBackgroundImage(UIImage(systemName: "shuffle"), for: .normal)
        shuffleButton.tintColor = isShuffleOn ? UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1) : .lightGray
        shuffleButton.addTarget(self, action: #selector(didTapShuffle), for: .touchUpInside)
        holder.addSubview(shuffleButton)
        
        // Back button
        backButton.frame = CGRect(x: holderWidth/2 - size - 50, y: controlsY, width: size, height: size)
        backButton.setBackgroundImage(UIImage(systemName: "backward.fill"), for: .normal)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(didTapBackButtton), for: .touchUpInside)
        holder.addSubview(backButton)
        
        // Play/Pause button
        playPauseButton.frame = CGRect(x: (holderWidth - size) / 2, y: controlsY, width: size, height: size)
        playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
        playPauseButton.tintColor = .black
        playPauseButton.addTarget(self, action: #selector(didTapPlayPauseButtton), for: .touchUpInside)
        holder.addSubview(playPauseButton)
        
        // Next button
        nextButton.frame = CGRect(x: holderWidth/2 + 50, y: controlsY, width: size, height: size)
        nextButton.setBackgroundImage(UIImage(systemName: "forward.fill"), for: .normal)
        nextButton.tintColor = .black
        nextButton.addTarget(self, action: #selector(didTapNextButtton), for: .touchUpInside)
        holder.addSubview(nextButton)
        
        // Repeat button (Phase 6)
        repeatButton.frame = CGRect(x: holderWidth - 50, y: controlsY + 10, width: 30, height: 30)
        updateRepeatButtonIcon()
        repeatButton.addTarget(self, action: #selector(didTapRepeat), for: .touchUpInside)
        holder.addSubview(repeatButton)
        
        // ====== FAVORITE BUTTON (Phase 3) ======
        favoriteButton.frame = CGRect(x: holderWidth / 2 - 20, y: controlsY + size + 15, width: 40, height: 40)
        favoriteButton.addTarget(self, action: #selector(didTapFavorite), for: .touchUpInside)
        holder.addSubview(favoriteButton)
        
        // Check if current song is favorited
        checkFavoriteStatus()
        
        // ====== VOLUME SLIDER ======
        let volumeY = holder.frame.size.height - 50
        
        let volumeIcon = UIImageView(image: UIImage(systemName: "speaker.fill"))
        volumeIcon.tintColor = .gray
        volumeIcon.frame = CGRect(x: 20, y: volumeY + 5, width: 18, height: 18)
        holder.addSubview(volumeIcon)
        
        let volumeMaxIcon = UIImageView(image: UIImage(systemName: "speaker.wave.3.fill"))
        volumeMaxIcon.tintColor = .gray
        volumeMaxIcon.frame = CGRect(x: holderWidth - 38, y: volumeY + 5, width: 22, height: 18)
        holder.addSubview(volumeMaxIcon)
        
        let slider = UISlider(frame: CGRect(x: 45, y: volumeY, width: holderWidth - 90, height: 30))
        slider.value = 0.5
        slider.addTarget(self, action: #selector(didSliderSlider(_:)), for: .valueChanged)
        holder.addSubview(slider)
    }

    private func configureCloseButton() {
        closeButton.removeFromSuperview()

        closeButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        closeButton.setTitle(" Back", for: .normal)
        closeButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        closeButton.titleLabel?.font = UIFont(name: "Helvetica", size: 17)
        closeButton.contentHorizontalAlignment = .left
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)

        let topInset = view.safeAreaInsets.top
        closeButton.frame = CGRect(x: 12, y: topInset + 8, width: 100, height: 34)
        view.addSubview(closeButton)
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    private func resolvePlaybackURL(for song: Song) -> URL? {
        if let localFileName = song.localFileName,
           let localURL = LibraryManager.shared.localFileURL(fileName: localFileName),
           FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }

        if let bundlePath = Bundle.main.path(forResource: song.trackName, ofType: "mp3") {
            return URL(fileURLWithPath: bundlePath)
        }

        if let directBundlePath = Bundle.main.path(forResource: song.trackName, ofType: nil) {
            return URL(fileURLWithPath: directBundlePath)
        }

        return nil
    }
    
    // MARK: - Progress Bar (Phase 4)
    
    @objc func updateProgress() {
        guard let player = player else { return }
        let currentTime = player.currentTime
        let duration = player.duration
        
        if duration > 0 {
            progressSlider.value = Float(currentTime / duration)
            elapsedTimeLabel.text = formatTime(currentTime)
            remainingTimeLabel.text = "-\(formatTime(duration - currentTime))"
        }
    }
    
    @objc func didSeek(_ slider: UISlider) {
        guard let player = player else { return }
        let seekTime = Double(slider.value) * player.duration
        player.currentTime = seekTime
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Shuffle & Repeat (Phase 6)
    
    @objc func didTapShuffle() {
        isShuffleOn.toggle()
        shuffleButton.tintColor = isShuffleOn ? UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1) : .lightGray
    }
    
    @objc func didTapRepeat() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
        updateRepeatButtonIcon()
    }
    
    func updateRepeatButtonIcon() {
        switch repeatMode {
        case .off:
            repeatButton.setBackgroundImage(UIImage(systemName: "repeat"), for: .normal)
            repeatButton.tintColor = .lightGray
        case .all:
            repeatButton.setBackgroundImage(UIImage(systemName: "repeat"), for: .normal)
            repeatButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        case .one:
            repeatButton.setBackgroundImage(UIImage(systemName: "repeat.1"), for: .normal)
            repeatButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        }
    }
    
    // MARK: - AVAudioPlayerDelegate (auto-next when song ends)
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer?.invalidate()
        
        switch repeatMode {
        case .one:
            // Replay same song
            player.currentTime = 0
            player.play()
            progressTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
            
        case .all:
            if isShuffleOn {
                position = Int.random(in: 0..<songs.count)
            } else {
                position = (position + 1) % songs.count // wrap around
            }
            reloadPlayer()
            
        case .off:
            if isShuffleOn {
                position = Int.random(in: 0..<songs.count)
                reloadPlayer()
            } else if position < songs.count - 1 {
                position += 1
                reloadPlayer()
            }
            // If last song and repeat off, just stop
        }
    }
    
    // MARK: - Favorites (Phase 3)
    
    func checkFavoriteStatus() {
        let song = songs[position]
        FavoritesManager.shared.isFavorite(song: song) { [weak self] favorited in
            self?.isFavorited = favorited
            let heartImage = favorited ? "heart.fill" : "heart"
            self?.favoriteButton.setBackgroundImage(UIImage(systemName: heartImage), for: .normal)
            self?.favoriteButton.tintColor = favorited ? .red : .gray
        }
    }
    
    @objc func didTapFavorite() {
        let song = songs[position]
        if isFavorited {
            FavoritesManager.shared.removeFavorite(song: song) { [weak self] success in
                if success {
                    self?.isFavorited = false
                    self?.favoriteButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
                    self?.favoriteButton.tintColor = .gray
                }
            }
        } else {
            FavoritesManager.shared.addFavorite(song: song) { [weak self] success in
                if success {
                    self?.isFavorited = true
                    self?.favoriteButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
                    self?.favoriteButton.tintColor = .red
                    
                    // Quick heart animation
                    UIView.animate(withDuration: 0.15, animations: {
                        self?.favoriteButton.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
                    }) { _ in
                        UIView.animate(withDuration: 0.15) {
                            self?.favoriteButton.transform = .identity
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Player Controls
    
    func reloadPlayer() {
        player?.stop()
        progressTimer?.invalidate()
        for subview in holder.subviews {
            subview.removeFromSuperview()
        }
        configure()
    }
    
    @objc func didTapBackButtton(){
        if isShuffleOn {
            position = Int.random(in: 0..<songs.count)
        } else if position > 0 {
            position = position - 1
        } else {
            return
        }
        reloadPlayer()
    }
    
    @objc func didTapNextButtton(){
        if isShuffleOn {
            position = Int.random(in: 0..<songs.count)
        } else if position < (songs.count - 1) {
            position = position + 1
        } else if repeatMode == .all {
            position = 0
        } else {
            return
        }
        reloadPlayer()
    }
    
    @objc func didTapPlayPauseButtton(){
        if player?.isPlaying == true {
            player?.pause()
            playPauseButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
            UIView.animate(withDuration: 0.2, animations: {
                self.albumImageView.frame = CGRect(x: 40, y: 30, width: self.holder.frame.size.width - 80, height: self.holder.frame.size.width - 80)
            })
        } else {
            player?.play()
            playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
            UIView.animate(withDuration: 0.2, animations: {
                self.albumImageView.frame = CGRect(x: 20, y: 10, width: self.holder.frame.size.width - 40, height: self.holder.frame.size.width - 40)
            })
        }
    }
    
    @objc func didSliderSlider(_ slider: UISlider){
        let value = slider.value
        player?.volume = value
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressTimer?.invalidate()
        if let player = player {
            player.stop()
        }
    }
}
