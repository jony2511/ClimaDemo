//
//  HomeViewController.swift
//  ClimaBeats
//
//  

import UIKit
import FirebaseAuth
import FirebaseFirestore

class HomeViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var songss: UILabel!
    
    @IBOutlet var table: UITableView!
    var receivedWeatherData: WeatherData? // Property to hold received WeatherData
    var songs = [Song]()
    private let db = Firestore.firestore()
    private var currentModeKey: String = "chill"
    
    
    @IBOutlet weak var weather: UIButton!
    @IBOutlet weak var logout: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        let conditionText = receivedWeatherData?.current.condition.text ?? "Unknown"
        songss.text = conditionText
        currentModeKey = modeKey(for: conditionText)
       
        table.delegate = self
        table.dataSource = self
        loadPlaylistForCurrentMode()

        // Add button to modify current mode playlist from Library
        let addFromLibraryButton = UIButton(type: .system)
        addFromLibraryButton.setTitle("+ Add To Playlist", for: .normal)
        addFromLibraryButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 14)
        addFromLibraryButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        addFromLibraryButton.frame = CGRect(x: 20, y: view.frame.size.height - 80, width: 150, height: 40)
        addFromLibraryButton.backgroundColor = .white
        addFromLibraryButton.layer.cornerRadius = 20
        addFromLibraryButton.layer.borderWidth = 1.5
        addFromLibraryButton.layer.borderColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1).cgColor
        addFromLibraryButton.addTarget(self, action: #selector(addSongFromLibraryTapped), for: .touchUpInside)
        view.addSubview(addFromLibraryButton)

        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset Default", for: .normal)
        resetButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 14)
        resetButton.tintColor = UIColor(red: 130/255, green: 20/255, blue: 20/255, alpha: 1)
        resetButton.frame = CGRect(x: view.frame.size.width - 170, y: view.frame.size.height - 80, width: 150, height: 40)
        resetButton.backgroundColor = .white
        resetButton.layer.cornerRadius = 20
        resetButton.layer.borderWidth = 1.5
        resetButton.layer.borderColor = UIColor(red: 130/255, green: 20/255, blue: 20/255, alpha: 1).cgColor
        resetButton.addTarget(self, action: #selector(resetCurrentModePlaylistTapped), for: .touchUpInside)
        view.addSubview(resetButton)
        
        // Add Profile button programmatically
        let profileButton = UIButton(type: .system)
        profileButton.setTitle("👤 Profile", for: .normal)
        profileButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 14)
        profileButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        profileButton.frame = CGRect(x: view.frame.size.width - 110, y: 50, width: 100, height: 35)
        profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        view.addSubview(profileButton)
    }
    
    // MARK: - Phase 7: Expanded Weather-to-Mood Playlists
    
    // ☀️ Energetic - Sunny/Clear
    func configureSongsEnergetic(){
        songs.append(Song(name: "Ninth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song9"))
        songs.append(Song(name: "Tenth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song10"))
        songs.append(Song(name: "Eleventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song11"))
        songs.append(Song(name: "Fourth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song4"))
        songs.append(Song(name: "Fifth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song5"))
        songs.append(Song(name: "Sixth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song6"))
        songs.append(Song(name: "Seventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song7"))
        songs.append(Song(name: "Eighth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song8"))
    }
    
    // 🌤️ Chill - Partly Cloudy/Cloudy/Overcast
    func configureSongsChill(){
        songs.append(Song(name: "Fourth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song4"))
        songs.append(Song(name: "Ninth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song9"))
        songs.append(Song(name: "Tenth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song10"))
        songs.append(Song(name: "Eleventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song11"))
        songs.append(Song(name: "Twelfth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song12"))
        songs.append(Song(name: "First Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song1"))
        songs.append(Song(name: "Third Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song3"))
    }
    
    // 🌧️ Melancholic - Rain/Drizzle/Sleet
    func configureSongsMelancholic(){
        songs.append(Song(name: "Ninth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song9"))
        songs.append(Song(name: "Tenth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song10"))
        songs.append(Song(name: "Eleventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song11"))
        songs.append(Song(name: "Twelfth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song12"))
        songs.append(Song(name: "Second Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song2"))
        songs.append(Song(name: "Fourth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song4"))
        songs.append(Song(name: "Fifth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song5"))
    }
    
    // ⛈️ Intense - Thunderstorm/Heavy Rain
    func configureSongsIntense(){
        songs.append(Song(name: "Sixth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song6"))
        songs.append(Song(name: "Seventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song7"))
        songs.append(Song(name: "Tenth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song10"))
        songs.append(Song(name: "Fifth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song5"))
        songs.append(Song(name: "Fifth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song5"))
        songs.append(Song(name: "Fourth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song4"))
    }
    
    // ❄️ Cozy - Snow/Blizzard/Ice/Freezing
    func configureSongsCozy(){
        songs.append(Song(name: "First Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song1"))
        songs.append(Song(name: "Third Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song3"))
        songs.append(Song(name: "Eighth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song8"))
        songs.append(Song(name: "Seventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song7"))
        songs.append(Song(name: "Eleventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song11"))
        songs.append(Song(name: "Twelfth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song12"))
    }
    
    // 🌫️ Mysterious - Fog/Mist/Haze
    func configureSongsMysterious(){
        songs.append(Song(name: "Eighth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song8"))
        songs.append(Song(name: "Seventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song7"))
        songs.append(Song(name: "Sixth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song6"))
        songs.append(Song(name: "Second Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song2"))
        songs.append(Song(name: "Ninth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song9"))
        songs.append(Song(name: "Tenth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song10"))
    }

    //Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return songs.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let song = songs[indexPath.row]
        // configure
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.isLocalFile ? "" : song.albumName
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.image = UIImage(named: song.imageName) ?? UIImage(named: "song_cover")
        
        
        cell.textLabel?.font = UIFont(name: "Helvetica-Bold", size: 18)
        cell.detailTextLabel?.font = UIFont(name: "Helvetica", size: 17)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // present  the player
        let position = indexPath.row
        //songs
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "player") as? PlayerViewController else {
            return
        }
        
        vc.songs = songs
        vc.position = position
        present(vc , animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            songs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveCurrentModePlaylist()
        }
    }

    @IBAction func weatherTapped(_ sender: Any) {
    }
    @IBAction func logoutTapped(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            transitionToHome()
            
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    @objc func favoritesTapped() {
        let favVC = FavoritesViewController()
        favVC.modalPresentationStyle = .fullScreen
        present(favVC, animated: true)
    }

    @objc func libraryTapped() {
        let libraryVC = LibraryViewController()
        libraryVC.modalPresentationStyle = .fullScreen
        present(libraryVC, animated: true)
    }

    @objc func addSongFromLibraryTapped() {
        let librarySongs = LibraryManager.shared.fetchSongs()

        guard !librarySongs.isEmpty else {
            let alert = UIAlertController(title: "Library Empty", message: "Add songs to your Library first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let alert = UIAlertController(title: "Add Song", message: "Select a song for this mode playlist.", preferredStyle: .actionSheet)

        for librarySong in librarySongs {
            alert.addAction(UIAlertAction(title: librarySong.name, style: .default, handler: { [weak self] _ in
                guard let self else { return }

                let exists = self.songs.contains(where: {
                    if let lhs = $0.localFileName, let rhs = librarySong.localFileName {
                        return lhs == rhs
                    }
                    return $0.trackName == librarySong.trackName
                })

                if exists {
                    let duplicateAlert = UIAlertController(title: "Already Added", message: "This song is already in the current mode playlist.", preferredStyle: .alert)
                    duplicateAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(duplicateAlert, animated: true)
                    return
                }

                self.songs.append(librarySong)
                self.table.reloadData()
                self.saveCurrentModePlaylist()
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: 120, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    @objc func resetCurrentModePlaylistTapped() {
        let alert = UIAlertController(
            title: "Reset Playlist",
            message: "Reset this \(currentModeKey.capitalized) mode playlist to default songs?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { [weak self] _ in
            self?.resetCurrentModePlaylistToDefault()
        }))

        present(alert, animated: true)
    }

    private func modeKey(for conditionText: String) -> String {
        let condition = conditionText.lowercased()
        if condition.contains("sunny") || condition.contains("clear") {
            return "energetic"
        } else if condition.contains("partly cloudy") || condition.contains("cloudy") || condition.contains("overcast") {
            return "chill"
        } else if condition.contains("thunder") || condition.contains("heavy rain") {
            return "intense"
        } else if condition.contains("rain") || condition.contains("drizzle") || condition.contains("sleet") {
            return "melancholic"
        } else if condition.contains("snow") || condition.contains("blizzard") || condition.contains("ice") || condition.contains("freezing") {
            return "cozy"
        } else if condition.contains("fog") || condition.contains("mist") || condition.contains("haze") {
            return "mysterious"
        }
        return "chill"
    }

    private func defaultSongs(for modeKey: String) -> [Song] {
        var defaults: [Song] = []

        switch modeKey {
        case "energetic":
            defaults.append(Song(name: "Ninth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song9"))
            defaults.append(Song(name: "Tenth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song10"))
            defaults.append(Song(name: "Eleventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song11"))
            defaults.append(Song(name: "Fourth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song4"))
            defaults.append(Song(name: "Fifth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song5"))
            defaults.append(Song(name: "Sixth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song6"))
            defaults.append(Song(name: "Seventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song7"))
            defaults.append(Song(name: "Eighth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song8"))
        case "intense":
            defaults.append(Song(name: "Sixth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song6"))
            defaults.append(Song(name: "Seventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song7"))
            defaults.append(Song(name: "Tenth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song10"))
            defaults.append(Song(name: "Fifth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song5"))
            defaults.append(Song(name: "Fifth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song5"))
            defaults.append(Song(name: "Fourth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song4"))
        case "melancholic":
            defaults.append(Song(name: "Ninth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song9"))
            defaults.append(Song(name: "Tenth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song10"))
            defaults.append(Song(name: "Eleventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song11"))
            defaults.append(Song(name: "Twelfth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song12"))
            defaults.append(Song(name: "Second Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song2"))
            defaults.append(Song(name: "Fourth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song4"))
            defaults.append(Song(name: "Fifth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song5"))
        case "cozy":
            defaults.append(Song(name: "First Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song1"))
            defaults.append(Song(name: "Third Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song3"))
            defaults.append(Song(name: "Eighth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song8"))
            defaults.append(Song(name: "Seventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song7"))
            defaults.append(Song(name: "Eleventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song11"))
            defaults.append(Song(name: "Twelfth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song12"))
        case "mysterious":
            defaults.append(Song(name: "Eighth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song8"))
            defaults.append(Song(name: "Seventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song7"))
            defaults.append(Song(name: "Sixth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song6"))
            defaults.append(Song(name: "Second Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song2"))
            defaults.append(Song(name: "Ninth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song9"))
            defaults.append(Song(name: "Tenth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song10"))
        default:
            defaults.append(Song(name: "Fourth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song4"))
            defaults.append(Song(name: "Ninth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song9"))
            defaults.append(Song(name: "Tenth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song10"))
            defaults.append(Song(name: "Eleventh Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song11"))
            defaults.append(Song(name: "Twelfth Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song12"))
            defaults.append(Song(name: "First Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song1"))
            defaults.append(Song(name: "Third Song", albumName:"", artistName: "", imageName: "song_cover", trackName: "song3"))
        }

        return defaults
    }

    private func loadPlaylistForCurrentMode() {
        guard let uid = Auth.auth().currentUser?.uid else {
            songs = defaultSongs(for: currentModeKey)
            table.reloadData()
            return
        }

        db.collection("users")
            .document(uid)
            .collection("modePlaylists")
            .document(currentModeKey)
            .getDocument { [weak self] document, error in
                guard let self else { return }

                if let error = error {
                    print("Error loading mode playlist: \(error.localizedDescription)")
                    self.songs = self.defaultSongs(for: self.currentModeKey)
                    self.table.reloadData()
                    return
                }

                if let data = document?.data(),
                   let songDicts = data["songs"] as? [[String: Any]] {
                    let parsedSongs = songDicts.compactMap { Song.fromDictionary($0) }
                    self.songs = parsedSongs.isEmpty ? self.defaultSongs(for: self.currentModeKey) : parsedSongs
                } else {
                    self.songs = self.defaultSongs(for: self.currentModeKey)
                }

                self.table.reloadData()
            }
    }

    private func saveCurrentModePlaylist() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let payload: [String: Any] = [
            "mode": currentModeKey,
            "songs": songs.map { $0.toDictionary() },
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("users")
            .document(uid)
            .collection("modePlaylists")
            .document(currentModeKey)
            .setData(payload, merge: true) { error in
                if let error = error {
                    print("Error saving mode playlist: \(error.localizedDescription)")
                }
            }
    }

    private func resetCurrentModePlaylistToDefault() {
        songs = defaultSongs(for: currentModeKey)
        table.reloadData()

        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        db.collection("users")
            .document(uid)
            .collection("modePlaylists")
            .document(currentModeKey)
            .delete { [weak self] error in
                if let error = error {
                    print("Error deleting custom mode playlist: \(error.localizedDescription)")
                    // Fallback: store defaults explicitly if document delete fails.
                    self?.saveCurrentModePlaylist()
                }
            }
    }
    
    @objc func profileTapped() {
        let profileVC = ProfileViewController()
        profileVC.modalPresentationStyle = .fullScreen
        present(profileVC, animated: true)
    }
    
    func transitionToHome() {
        let ViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.ViewController) as? ViewController
        view.window?.rootViewController = ViewController
        view.window?.makeKeyAndVisible()
    }
}
