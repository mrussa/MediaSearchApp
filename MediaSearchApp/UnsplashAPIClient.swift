import Foundation

struct UnsplashAPIClient {
    private let accessKey = "m9Rt6aY2G_jMImnpVYbbMD_kJBInYQ3F4LIikHdygqU"  

    func searchPhotos(query: String, completion: @escaping (Result<[Photo], Error>) -> Void) {
        guard let url = URL(string: "https://api.unsplash.com/search/photos?query=\(query)&client_id=\(accessKey)") else {
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                return
            }

            do {
                let result = try JSONDecoder().decode(SearchResult.self, from: data)
                completion(.success(result.results))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

struct SearchResult: Codable {
    let results: [Photo]
}

struct Photo: Codable {
    let id: String
    let description: String?
    let urls: PhotoURLs
}

struct PhotoURLs: Codable {
    let small: String
    let regular: String
}

