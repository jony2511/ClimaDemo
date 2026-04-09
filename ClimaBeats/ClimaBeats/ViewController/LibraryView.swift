//
//  LibraryViewController.swift
//  ClimaBeats
//

import UIKit
import UniformTypeIdentifiers

class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate {

    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "libraryCell")
        return table
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No local songs yet.\nTap Add Song to import from Files."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .gray
        label.font = UIFont(name: "Helvetica", size: 16)
        label.isHidden = true
        return label
    }()

    private var songs: [Song] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUI()
        reloadSongs()
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "My Library"
        titleLabel.font = UIFont(name: "Helvetica-Bold", size: 24)
        titleLabel.textAlignment = .center
        titleLabel.frame = CGRect(x: 0, y: 60, width: view.frame.size.width, height: 40)
        view.addSubview(titleLabel)

        let backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 16)
        backButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        backButton.frame = CGRect(x: 16, y: 60, width: 80, height: 40)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        let addButton = UIButton(type: .system)
        addButton.setTitle("+ Add Song", for: .normal)
        addButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 16)
        addButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        addButton.frame = CGRect(x: view.frame.size.width - 120, y: 60, width: 110, height: 40)
        addButton.addTarget(self, action: #selector(addSongTapped), for: .touchUpInside)
        view.addSubview(addButton)

        tableView.frame = CGRect(x: 0, y: 110, width: view.frame.size.width, height: view.frame.size.height - 110)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        emptyLabel.frame = CGRect(x: 20, y: 0, width: view.frame.size.width - 40, height: 100)
        emptyLabel.center = view.center
        view.addSubview(emptyLabel)
    }

    private func reloadSongs() {
        songs = LibraryManager.shared.fetchSongs()
        tableView.reloadData()
        emptyLabel.isHidden = !songs.isEmpty
        tableView.isHidden = songs.isEmpty
    }

    @objc private func addSongTapped() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio], asCopy: false)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        present(picker, animated: true)
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard !urls.isEmpty else { return }

        var hasFailure = false
        let group = DispatchGroup()

        for url in urls {
            let access = url.startAccessingSecurityScopedResource()
            group.enter()
            LibraryManager.shared.importSong(from: url) { result in
                if case .failure = result {
                    hasFailure = true
                }
                if access {
                    url.stopAccessingSecurityScopedResource()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.reloadSongs()
            if hasFailure {
                let alert = UIAlertController(title: "Import Failed", message: "Some files could not be imported.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "libraryCell", for: indexPath)
        let song = songs[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = song.name
        content.secondaryText = "\(song.artistName) • \(song.albumName)"
        content.image = UIImage(named: song.imageName) ?? UIImage(named: "song_cover")
        content.textProperties.font = UIFont(name: "Helvetica-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        content.secondaryTextProperties.font = UIFont(name: "Helvetica", size: 15) ?? .systemFont(ofSize: 15)
        content.imageProperties.maximumSize = CGSize(width: 50, height: 50)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = mainStoryboard.instantiateViewController(withIdentifier: "player") as? PlayerViewController else {
            return
        }

        vc.songs = songs
        vc.position = indexPath.row
        present(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let song = songs[indexPath.row]
            let didDelete = LibraryManager.shared.deleteSong(song)

            if didDelete {
                songs.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)

                if songs.isEmpty {
                    emptyLabel.isHidden = false
                    tableView.isHidden = true
                }
            } else {
                let alert = UIAlertController(
                    title: "Delete Failed",
                    message: "The song could not be removed. Please try again.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }
}
