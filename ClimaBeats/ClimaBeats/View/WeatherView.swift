//
//  WeatherViewController.swift
//  ClimaBeats
//
//

import UIKit
import CoreLocation

class WeatherViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var updatetimeLabel: UILabel!
    @IBOutlet var regionLabel: UILabel!
    @IBOutlet var countryLabel: UILabel!
    @IBOutlet var temperatureLabel: UILabel!
    @IBOutlet var windLabel: UILabel!
    @IBOutlet var humidityLabel: UILabel!
    
    @IBOutlet var refreshData: UIButton!
    
    @IBOutlet var imageview: UIImageView!
    
    @IBOutlet var conditionLabel: UILabel!
    var fullWeatherData: WeatherData?
    private let viewModel = WeatherViewModel()
    
    let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let bangladeshFallbackQuery = "Dhaka,Bangladesh"
    private let bangladeshISOCode = "BD"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        requestCurrentWeather()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations
            .reversed()
            .first(where: { $0.horizontalAccuracy > 0 && abs($0.timestamp.timeIntervalSinceNow) <= 120 }) ?? locations.last else {
            fetchData(for: bangladeshFallbackQuery)
            return
        }

        resolveWeatherQuery(from: location) { [weak self] query in
            self?.fetchData(for: query)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        // Fallback to default location
        fetchData(for: bangladeshFallbackQuery)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied, .restricted:
            // Fallback to Bangladesh if permission denied
            fetchData(for: bangladeshFallbackQuery)
        default:
            break
        }
    }

    private func requestCurrentWeather() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            fetchData(for: bangladeshFallbackQuery)
        @unknown default:
            fetchData(for: bangladeshFallbackQuery)
        }
    }

    private func resolveWeatherQuery(from location: CLLocation, completion: @escaping (String) -> Void) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else {
                completion("\(location.coordinate.latitude),\(location.coordinate.longitude)")
                return
            }

            let isBangladesh = placemarks?.first?.isoCountryCode == self.bangladeshISOCode
            if isBangladesh {
                completion("\(location.coordinate.latitude),\(location.coordinate.longitude)")
            } else {
                completion(self.bangladeshFallbackQuery)
            }
        }
    }
   
    private func fetchData(for query: String) {
            viewModel.fetchWeather(query: query) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let weatherData):
                    self.fullWeatherData = weatherData

                    DispatchQueue.main.async {
                        self.updatetimeLabel.text = "\(weatherData.current.last_updated)"
                        self.regionLabel.text = "\(weatherData.location.region)"
                        self.countryLabel.text = "\(weatherData.location.country)"
                        self.conditionLabel.text = "\(weatherData.current.condition.text)"
                        self.temperatureLabel.text = "\(weatherData.current.temp_c)°C"
                        self.humidityLabel.text = "Humidity : \(weatherData.current.humidity)"
                        self.windLabel.text = "\(weatherData.current.wind_kph) Km/Hr"
                        if let iconURL = URL(string: "https:\(weatherData.current.condition.icon)") {
                            if let imageData = try? Data(contentsOf: iconURL) {
                                self.imageview.image = UIImage(data: imageData)
                            }
                        }
                    }

                case .failure(let error):
                    print("Error fetching weather data: \(error.localizedDescription)")
                }
            }
    }

    @IBAction func refreshData(_ sender: Any) {
        requestCurrentWeather()
    }
    
    @IBAction func suggestSongs(_ sender: Any) {
        guard let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController else {
                    return
                }
                homeViewController.receivedWeatherData = fullWeatherData
                view.window?.rootViewController = homeViewController
                view.window?.makeKeyAndVisible()
    }
}
