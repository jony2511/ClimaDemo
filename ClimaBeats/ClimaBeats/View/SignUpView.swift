//
//  SignUpViewController.swift
//  ClimaBeats
//
// 
//

import UIKit

class SignUpViewController: UIViewController {

    private let viewModel = SignUpViewModel()

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet var logo: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpElements()
        passwordTextField.isSecureTextEntry = true
    }
    func setUpElements ()
    {
        errorLabel.alpha = 0
        Utilities.styleTextField(firstNameTextField)
        Utilities.styleTextField(lastNameTextField)
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(signUpButton)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func validateFields() -> String? {
        return viewModel.validateFields(
            firstName: firstNameTextField.text ?? "",
            lastName: lastNameTextField.text ?? "",
            email: emailTextField.text ?? "",
            password: passwordTextField.text ?? ""
        )
    }

    @IBAction func signUpTapped(_ sender: Any) {
        
        let error = validateFields()
        
        if error != nil{
            showError(error!)           }
        else
        {
            let firstName = firstNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let lastName = lastNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            viewModel.signUp(firstName: firstName, lastName: lastName, email: email, password: password) { [weak self] errorMessage in
                guard let self else { return }
                if let errorMessage {
                    self.showError(errorMessage)
                } else {
                    self.transitionToHome()
                }
            }
            
        }
    }
    func showError(_ message:String){
        errorLabel.text = message
        errorLabel.alpha = 1

    }
    
    func transitionToHome(){
        
        
        let weatherViewController =   self.storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.weatherViewController) as? WeatherViewController
        
        self.view.window?.rootViewController = weatherViewController
        self.view.window?.makeKeyAndVisible()
              
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        
        
            let ViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.ViewController) as? ViewController
            view.window?.rootViewController = ViewController
            view.window?.makeKeyAndVisible()
        
    }
    
}

