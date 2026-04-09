//
//  FavoritesViewController.swift
//  ClimaBeats
//
// 
//

import UIKit

class FavoritesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "favCell")
        return table
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No favorite songs yet!\nTap ❤️ in the player to add songs."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .gray
        label.font = UIFont(name: "Helvetica", size: 16)
        label.isHidden = true
        return label
    }()
    
    var favoriteSongs: [Song] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "❤️ My Favorites"
        titleLabel.font = UIFont(name: "Helvetica-Bold", size: 24)
        titleLabel.textAlignment = .center
        titleLabel.frame = CGRect(x: 0, y: 60, width: view.frame.size.width, height: 40)
        view.addSubview(titleLabel)
        
        // Back button
        let backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 16)
        backButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        backButton.frame = CGRect(x: 16, y: 60, width: 80, height: 40)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Table view
        tableView.frame = CGRect(x: 0, y: 110, width: view.frame.size.width, height: view.frame.size.height - 110)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        // Empty label
        emptyLabel.frame = CGRect(x: 20, y: 0, width: view.frame.size.width - 40, height: 100)
        emptyLabel.center = view.center
        view.addSubview(emptyLabel)
        
        fetchFavorites()
    }
    
    func fetchFavorites() {
        FavoritesManager.shared.fetchFavorites { [weak self] songs in
            self?.favoriteSongs = songs
            self?.tableView.reloadData()
            self?.emptyLabel.isHidden = !songs.isEmpty
            self?.tableView.isHidden = songs.isEmpty
        }
    }
    
    // MARK: - TableView DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteSongs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favCell", for: indexPath)
        let song = favoriteSongs[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = song.name
        content.secondaryText = "\(song.artistName) • \(song.albumName)"
        content.image = UIImage(named: song.imageName) ?? UIImage(named: "song_cover")
        content.textProperties.font = UIFont(name: "Helvetica-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        content.secondaryTextProperties.font = UIFont(name: "Helvetica", size: 15) ?? .systemFont(ofSize: 15)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = mainStoryboard.instantiateViewController(withIdentifier: "player") as? PlayerViewController else {
            return
        }
        vc.songs = favoriteSongs
        vc.position = indexPath.row
        present(vc, animated: true)
    }
    
    // Swipe to delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let song = favoriteSongs[indexPath.row]
            FavoritesManager.shared.removeFavorite(song: song) { [weak self] success in
                if success {
                    self?.favoriteSongs.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    if self?.favoriteSongs.isEmpty == true {
                        self?.emptyLabel.isHidden = false
                        self?.tableView.isHidden = true
                    }
                }
            }
        }
    }
    
    @objc func backTapped() {
        dismiss(animated: true)
    }
}
