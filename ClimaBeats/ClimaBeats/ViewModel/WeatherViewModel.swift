import Foundation

final class WeatherViewModel {
    func fetchWeather(query: String, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        var components = URLComponents(string: "https://api.weatherapi.com/v1/current.json")
        components?.queryItems = [
            URLQueryItem(name: "key", value: "61af11bba9124212baf85419232611"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "aqi", value: "no")
        ]

        guard let url = components?.url else {
            completion(.failure(NSError(domain: "WeatherURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error creating weather API URL"])))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data else {
                completion(.failure(NSError(domain: "WeatherData", code: 0, userInfo: [NSLocalizedDescriptionKey: "No weather data received"])))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(WeatherData.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
