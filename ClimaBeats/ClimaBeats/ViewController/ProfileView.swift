//
//  ProfileViewController.swift
//  ClimaBeats
//
//  
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "Helvetica-Bold", size: 24)
        label.text = "Loading..."
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "Helvetica", size: 16)
        label.textColor = .gray
        return label
    }()
    
    private let favCountLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "Helvetica", size: 16)
        label.textColor = .darkGray
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        loadUserData()
        loadFavoritesCount()
    }
    
    func setupUI() {
        let screenWidth = view.frame.size.width
        
        // Back button
        let backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 16)
        backButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        backButton.frame = CGRect(x: 16, y: 60, width: 80, height: 40)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "My Profile"
        titleLabel.font = UIFont(name: "Helvetica-Bold", size: 22)
        titleLabel.textAlignment = .center
        titleLabel.frame = CGRect(x: 0, y: 60, width: screenWidth, height: 40)
        view.addSubview(titleLabel)
        
        // Profile image
        profileImageView.frame = CGRect(x: screenWidth/2 - 50, y: 130, width: 100, height: 100)
        view.addSubview(profileImageView)
        
        // Name
        nameLabel.frame = CGRect(x: 20, y: 245, width: screenWidth - 40, height: 30)
        view.addSubview(nameLabel)
        
        // Email
        emailLabel.frame = CGRect(x: 20, y: 280, width: screenWidth - 40, height: 25)
        view.addSubview(emailLabel)
        
        // Divider
        let divider = UIView()
        divider.backgroundColor = .lightGray
        divider.frame = CGRect(x: 40, y: 325, width: screenWidth - 80, height: 1)
        view.addSubview(divider)
        
        // Favorites count
        favCountLabel.frame = CGRect(x: 20, y: 340, width: screenWidth - 40, height: 30)
        view.addSubview(favCountLabel)
        
        // Change Password button
        let changePasswordButton = UIButton(type: .system)
        changePasswordButton.setTitle("🔑 Reset Password", for: .normal)
        changePasswordButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 16)
        changePasswordButton.tintColor = .white
        changePasswordButton.backgroundColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        changePasswordButton.layer.cornerRadius = 25
        changePasswordButton.frame = CGRect(x: 40, y: 400, width: screenWidth - 80, height: 50)
        changePasswordButton.addTarget(self, action: #selector(resetPasswordTapped), for: .touchUpInside)
        view.addSubview(changePasswordButton)
        
        // Logout button
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("🚪 Logout", for: .normal)
        logoutButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 16)
        logoutButton.tintColor = .red
        logoutButton.layer.borderWidth = 2
        logoutButton.layer.borderColor = UIColor.red.cgColor
        logoutButton.layer.cornerRadius = 25
        logoutButton.frame = CGRect(x: 40, y: 470, width: screenWidth - 80, height: 50)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        view.addSubview(logoutButton)

        // Bottom quick actions (only place for Library/Favorites)
        let libraryButton = UIButton(type: .system)
        libraryButton.setTitle("Library", for: .normal)
        libraryButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 14)
        libraryButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        libraryButton.frame = CGRect(x: 20, y: view.frame.size.height - 80, width: 140, height: 40)
        libraryButton.backgroundColor = .white
        libraryButton.layer.cornerRadius = 20
        libraryButton.layer.borderWidth = 1.5
        libraryButton.layer.borderColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1).cgColor
        libraryButton.addTarget(self, action: #selector(libraryTapped), for: .touchUpInside)
        view.addSubview(libraryButton)

        let favoritesButton = UIButton(type: .system)
        favoritesButton.setTitle("Favorites", for: .normal)
        favoritesButton.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 14)
        favoritesButton.tintColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        favoritesButton.frame = CGRect(x: screenWidth - 160, y: view.frame.size.height - 80, width: 140, height: 40)
        favoritesButton.backgroundColor = .white
        favoritesButton.layer.cornerRadius = 20
        favoritesButton.layer.borderWidth = 1.5
        favoritesButton.layer.borderColor = UIColor(red: 30/255, green: 10/255, blue: 87/255, alpha: 1).cgColor
        favoritesButton.addTarget(self, action: #selector(favoritesTapped), for: .touchUpInside)
        view.addSubview(favoritesButton)
    }
    
    func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        emailLabel.text = user.email
        
        // Fetch name from Firestore
        let db = Firestore.firestore()
        db.collection("users").whereField("uid", isEqualTo: user.uid).getDocuments { [weak self] snapshot, error in
            if let document = snapshot?.documents.first {
                let firstName = document.data()["firstname"] as? String ?? ""
                let lastName = document.data()["lastname"] as? String ?? ""
                self?.nameLabel.text = "\(firstName) \(lastName)"
            } else {
                self?.nameLabel.text = "User"
            }
        }
    }
    
    func loadFavoritesCount() {
        FavoritesManager.shared.fetchFavorites { [weak self] songs in
            self?.favCountLabel.text = "❤️ \(songs.count) Favorite Song\(songs.count == 1 ? "" : "s")"
        }
    }
    
    @objc func resetPasswordTapped() {
        guard let email = Auth.auth().currentUser?.email else { return }
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            let alert: UIAlertController
            if let error = error {
                alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            } else {
                alert = UIAlertController(title: "Success", message: "Password reset email sent to \(email)", preferredStyle: .alert)
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    @objc func logoutTapped() {
        do {
            try Auth.auth().signOut()
            // Go back to root landing screen
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: Constants.Storyboard.ViewController)
                window.rootViewController = vc
                window.makeKeyAndVisible()
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    @objc func backTapped() {
        dismiss(animated: true)
    }

    @objc func libraryTapped() {
        let libraryVC = LibraryViewController()
        libraryVC.modalPresentationStyle = .fullScreen
        present(libraryVC, animated: true)
    }

    @objc func favoritesTapped() {
        let favoritesVC = FavoritesViewController()
        favoritesVC.modalPresentationStyle = .fullScreen
        present(favoritesVC, animated: true)
    }
}
