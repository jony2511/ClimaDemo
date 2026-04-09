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
    
    
    @IBOutlet weak var weather: UIButton!
    @IBOutlet weak var logout: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        songss.text = "\(receivedWeatherData!.current.condition.text)"
        
        // Expanded weather-to-mood mapping (Phase 7)
        let condition = receivedWeatherData!.current.condition.text.lowercased()
        
        if condition.contains("sunny") || condition.contains("clear") {
            configureSongsEnergetic()
        } else if condition.contains("partly cloudy") || condition.contains("cloudy") || condition.contains("overcast") {
            configureSongsChill()
        } else if condition.contains("thunder") || condition.contains("heavy rain") {
            configureSongsIntense()
        } else if condition.contains("rain") || condition.contains("drizzle") || condition.contains("sleet") {
            configureSongsMelancholic()
        } else if condition.contains("snow") || condition.contains("blizzard") || condition.contains("ice") || condition.contains("freezing") {
            configureSongsCozy()
        } else if condition.contains("fog") || condition.contains("mist") || condition.contains("haze") {
            configureSongsMysterious()
        } else {
            configureSongsChill()
        }
       
        table.delegate = self
        table.dataSource = self
        
        // Add Favorites button programmatically
        let favButton = UIButton(type: .system)
        favButton.setTitle("❤️ Favorites", for: .normal)
        favButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 14)
        favButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        favButton.frame = CGRect(x: view.frame.size.width / 2 - 60, y: view.frame.size.height - 80, width: 120, height: 40)
        favButton.backgroundColor = .white
        favButton.layer.cornerRadius = 20
        favButton.layer.borderWidth = 1.5
        favButton.layer.borderColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1).cgColor
        favButton.addTarget(self, action: #selector(favoritesTapped), for: .touchUpInside)
        view.addSubview(favButton)

        // Add Library button for local imported songs
        let libraryButton = UIButton(type: .system)
        libraryButton.setTitle("📚 Library", for: .normal)
        libraryButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 14)
        libraryButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        libraryButton.frame = CGRect(x: 20, y: view.frame.size.height - 80, width: 110, height: 40)
        libraryButton.backgroundColor = .white
        libraryButton.layer.cornerRadius = 20
        libraryButton.layer.borderWidth = 1.5
        libraryButton.layer.borderColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1).cgColor
        libraryButton.addTarget(self, action: #selector(libraryTapped), for: .touchUpInside)
        view.addSubview(libraryButton)
        
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
        cell.detailTextLabel?.text = song.albumName
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
