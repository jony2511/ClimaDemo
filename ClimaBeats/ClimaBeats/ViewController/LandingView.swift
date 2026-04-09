//
//  ViewController.swift
//  ClimaBeats
//
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    
    @IBOutlet weak var bgimg: UIImageView!
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var namelabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ensureLandingLayerOrder()
        setUpElements()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Auto-login: Check if user is already signed in
        if Auth.auth().currentUser != nil {
            let weatherViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.weatherViewController) as? WeatherViewController
            view.window?.rootViewController = weatherViewController
            view.window?.makeKeyAndVisible()
        }
    }
    
    func setUpElements ()
    {
                Utilities.styleFilledButton(signUpButton)
        Utilities.styleHollowButton(loginButton)
    }

    private func ensureLandingLayerOrder() {
        // Keep the decorative background behind all interactive UI.
        if let backgroundImageView = view.subviews
            .compactMap({ $0 as? UIImageView })
            .first(where: { $0.image == UIImage(named: "bg") }) {
            view.sendSubviewToBack(backgroundImageView)
        }

        view.bringSubviewToFront(namelabel)
        view.bringSubviewToFront(signUpButton)
        view.bringSubviewToFront(loginButton)
    }
    
}

