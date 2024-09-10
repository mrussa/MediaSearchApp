import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegateFlowLayout {
    
    private var searchBar: UISearchBar!
    private var historyTableView: UITableView!
    private var collectionView: UICollectionView!
    
    private var searchHistory: [String] = []
    private var filteredHistory: [String] = [] // Для хранения отфильтрованной истории

    private var searchResults: [Photo] = []
    private var apiClient = UnsplashAPIClient()
    
    private var segmentedControl: UISegmentedControl!
    private var sortSegmentedControl: UISegmentedControl!
    private var currentSort: String = "relevant" // Сортировка по умолчанию
    
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    private var isLoadingMoreData = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSearchHistory()
    }

    private func setupUI() {
        // Установка фона для основного view контроллера
        view.backgroundColor = .white

        // Настройка UISearchBar
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.searchTextField.autocorrectionType = .yes
        searchBar.searchTextField.autocapitalizationType = .none
        searchBar.searchTextField.textContentType = .name
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // Отказ от клавиатуры при перетаскивании или нажатии вне поля поиска
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // Настройка UISegmentedControl для выбора вида отображения
        segmentedControl = UISegmentedControl(items: ["2 плитки", "1 плитка"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(viewModeChanged), for: .valueChanged)
        segmentedControl.backgroundColor = .white
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentTintColor = .systemGray // Изменение фона для выделенного сегмента
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal) // Цвет текста невыделенного сегмента
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected) // Цвет текста выделенного сегмента
        view.addSubview(segmentedControl)
        
        // Настройка UINavigationBar
        if let navigationBar = self.navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .white // Цвет фона для UINavigationBar
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }

        // Настройка UISegmentedControl для сортировки
        sortSegmentedControl = UISegmentedControl(items: ["Популярные", "Новые"])
        sortSegmentedControl.selectedSegmentIndex = 0
        sortSegmentedControl.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
        sortSegmentedControl.backgroundColor = .white
        sortSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        sortSegmentedControl.selectedSegmentTintColor = .systemGray // Изменение фона выделенного сегмента
        sortSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal) // Цвет текста невыделенного сегмента
        sortSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected) // Цвет текста выделенного сегмента
        view.addSubview(sortSegmentedControl)

        // Настройка UITableView для истории запросов
        historyTableView = UITableView()
        historyTableView.dataSource = self
        historyTableView.delegate = self
        historyTableView.isHidden = true
        historyTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(historyTableView)

        // Настройка UICollectionView для результатов поиска
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        // Добавляем констрейнты для размещения элементов друг под другом
        NSLayoutConstraint.activate([
            // Констрейнты для UISearchBar
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Констрейнты для UISegmentedControl для выбора формата отображения
            segmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Констрейнты для UISegmentedControl для сортировки
            sortSegmentedControl.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            sortSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sortSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Констрейнты для UITableView (historyTableView)
            historyTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            historyTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            historyTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            historyTableView.heightAnchor.constraint(equalToConstant: 200), // Установим фиксированную высоту для истории
            
            // Констрейнты для UICollectionView
            collectionView.topAnchor.constraint(equalTo: sortSegmentedControl.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
        historyTableView.isHidden = true // Скрываем историю поиска при нажатии вне поля
    }

    // Сохранение истории поиска в UserDefaults
    private func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: "searchHistory")
    }

    // Загрузка истории поиска из UserDefaults
    private func loadSearchHistory() {
        if let savedHistory = UserDefaults.standard.array(forKey: "searchHistory") as? [String] {
            searchHistory = savedHistory
        }
        filteredHistory = searchHistory
        historyTableView.reloadData()
    }
    
    // UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
           guard let query = searchBar.text, !query.isEmpty else { return }
           searchHistory.insert(query, at: 0)
           searchHistory = Array(Set(searchHistory)).prefix(5).map { $0 }
           saveSearchHistory()
           searchPhotos(query: query)
           searchBar.resignFirstResponder()
           historyTableView.isHidden = true
       }
    
    // Фильтрация истории поиска при изменении текста в поисковой строке
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredHistory = searchHistory
        } else {
            filteredHistory = searchHistory.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
        historyTableView.isHidden = filteredHistory.isEmpty
        historyTableView.reloadData()
    }
    
    private func searchPhotos(query: String, page: Int = 1) {
        apiClient.searchPhotos(query: query, page: page, sort: currentSort) { result in
            switch result {
            case .success(let photos):
                if page == 1 {
                    self.searchResults = photos
                } else {
                    self.searchResults.append(contentsOf: photos)
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                self.isLoadingMoreData = false
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredHistory.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "HistoryCell")
        cell.textLabel?.text = filteredHistory[indexPath.row]
        return cell
    }

    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedQuery = filteredHistory[indexPath.row]
        searchBar.text = selectedQuery
        searchPhotos(query: selectedQuery)
        searchBar.resignFirstResponder()
        historyTableView.isHidden = true
    }

    // UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        let photo = searchResults[indexPath.item]
        cell.configure(with: photo)
        return cell
    }
    
    // UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 10
        let availableWidth = view.frame.width - padding * 3
        let isGridMode = segmentedControl.selectedSegmentIndex == 0
        let width = isGridMode ? availableWidth / 2 : availableWidth
        return CGSize(width: width, height: width)
    }

    // UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let selectedPhoto = searchResults[indexPath.item]
    let detailVC = PhotoDetailViewController()
    detailVC.photo = selectedPhoto
    navigationController?.pushViewController(detailVC, animated: true)
        }
    
    // Обработка UISegmentedControl для изменения вида
    @objc private func viewModeChanged() {
        collectionView.reloadData()
    }
    
    // Обработка изменения сортировки
    @objc private func sortChanged() {
        currentSort = sortSegmentedControl.selectedSegmentIndex == 0 ? "relevant" : "latest"
        if let query = searchBar.text, !query.isEmpty {
            searchPhotos(query: query)
        }
    }

    // Пагинация
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height

        if position > (contentHeight - scrollViewHeight - 100), !isLoadingMoreData, currentPage < totalPages {
            isLoadingMoreData = true
            currentPage += 1
            if let query = searchBar.text, !query.isEmpty {
                searchPhotos(query: query, page: currentPage)
            }
        }
    }
}
