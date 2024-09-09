import UIKit

class ViewController: UIViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var searchBar: UISearchBar!
    var collectionView: UICollectionView!
    var segmentedControl: UISegmentedControl!
    var searchResults: [Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Создание UISearchBar
        searchBar = UISearchBar()
        searchBar.placeholder = "Введите запрос для поиска"
        searchBar.delegate = self
        navigationItem.titleView = searchBar
        
        // Создание и настройка UISegmentedControl
        segmentedControl = UISegmentedControl(items: ["2 плитки", "1 плитка"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        navigationItem.titleView = segmentedControl
        
        // Настройка макета UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        // Создание UICollectionView
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView.backgroundColor = .white
        
        // Добавление UICollectionView на экран
        view.addSubview(collectionView)
    }
    
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData() // Перезагружаем данные, чтобы отобразить их с новыми размерами
    }

    // UISearchBarDelegate: Начало поиска
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchBar.resignFirstResponder()
        
        // Отправка запроса на Unsplash API
        let apiClient = UnsplashAPIClient()
        apiClient.searchPhotos(query: query) { [weak self] result in
            switch result {
            case .success(let photos):
                self?.searchResults = photos
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            case .failure(let error):
                print("Ошибка: \(error)")
            }
        }
    }
    
    // UICollectionViewDataSource: Количество элементов
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    // UICollectionViewDataSource: Создание ячейки
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        let photo = searchResults[indexPath.item]
        cell.configure(with: photo)
        return cell
    }
    
    // UICollectionViewDelegateFlowLayout: Размеры ячеек
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if segmentedControl.selectedSegmentIndex == 0 {
            let width = (view.bounds.width - 30) / 2
            return CGSize(width: width, height: width)
        } else {
            let width = view.bounds.width - 20
            let height = width * 1.5
            return CGSize(width: width, height: height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPhoto = searchResults[indexPath.item]
        let detailVC = PhotoDetailViewController()
        detailVC.photo = selectedPhoto
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
