import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: - UI Elements

    private var searchBar: UISearchBar!
    private var historyTableView: UITableView!
    private var collectionView: UICollectionView!
    private var activityIndicator: UIActivityIndicatorView!
    private var errorLabel: UILabel!

    private var searchHistory: [String] = []
    private var filteredHistory: [String] = []

    private var searchResults: [Photo] = []
    private var apiClient = UnsplashAPIClient()
    
    private var segmentedControl: UISegmentedControl!
    private var sortSegmentedControl: UISegmentedControl!
    private var currentSort: String = "relevant"

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSearchHistory()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white

        // Настройка UISearchBar
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.searchTextField.autocorrectionType = .yes
        searchBar.searchTextField.autocapitalizationType = .none
        searchBar.searchTextField.textContentType = .name
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // Настройка UISegmentedControl для выбора вида отображения
        segmentedControl = UISegmentedControl(items: ["2 плитки", "1 плитка"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(viewModeChanged), for: .valueChanged)
        segmentedControl.backgroundColor = .white
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        
        if let navigationBar = self.navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .white
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }

        // Настройка UISegmentedControl для сортировки
        sortSegmentedControl = UISegmentedControl(items: ["Популярные", "Новые"])
        sortSegmentedControl.selectedSegmentIndex = 0
        sortSegmentedControl.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
        sortSegmentedControl.backgroundColor = .white
        sortSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sortSegmentedControl)

        // Настройка индикатора загрузки
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        // Настройка UILabel для отображения ошибок
        errorLabel = UILabel()
        errorLabel.textAlignment = .center
        errorLabel.textColor = .red
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)

        // Настройка UITableView для истории запросов
        historyTableView = UITableView()
        historyTableView.dataSource = self
        historyTableView.delegate = self
        historyTableView.isHidden = true
        historyTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(historyTableView)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        // Настройка UICollectionView для результатов поиска
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            segmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            sortSegmentedControl.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            sortSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sortSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            historyTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            historyTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            historyTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            historyTableView.heightAnchor.constraint(equalToConstant: 200),
            
            collectionView.topAnchor.constraint(equalTo: sortSegmentedControl.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Search Functionality

    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
        historyTableView.isHidden = true
    }

    private func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: "searchHistory")
    }

    private func loadSearchHistory() {
        if let savedHistory = UserDefaults.standard.array(forKey: "searchHistory") as? [String] {
            searchHistory = savedHistory
        }
        filteredHistory = searchHistory
        historyTableView.reloadData()
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchHistory.insert(query, at: 0)
        searchHistory = Array(Set(searchHistory)).prefix(5).map { $0 }
        saveSearchHistory()
        searchPhotos(query: query)
        searchBar.resignFirstResponder()
        historyTableView.isHidden = true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredHistory = searchHistory
        } else {
            filteredHistory = searchHistory.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
        historyTableView.isHidden = filteredHistory.isEmpty
        historyTableView.reloadData()
    }

    // MARK: - Search Logic

    private func searchPhotos(query: String) {
        activityIndicator.startAnimating()
        errorLabel.isHidden = true
        collectionView.isHidden = true

        apiClient.searchPhotos(query: query, sort: currentSort) { result in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                switch result {
                case .success(let photos):
                    self.searchResults = photos
                    self.collectionView.isHidden = photos.isEmpty
                    self.collectionView.reloadData()
                    if photos.isEmpty {
                        self.errorLabel.text = "Нет результатов"
                        self.errorLabel.isHidden = false
                    }
                case .failure(let error):
                    self.errorLabel.text = "Произошла ошибка: \(error.localizedDescription)"
                    self.errorLabel.isHidden = false
                }
            }
        }
    }

    // MARK: - TableView DataSource & Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredHistory.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "HistoryCell")
        cell.textLabel?.text = filteredHistory[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedQuery = filteredHistory[indexPath.row]
        searchBar.text = selectedQuery
        searchPhotos(query: selectedQuery)
        searchBar.resignFirstResponder()
        historyTableView.isHidden = true
    }

    // MARK: - CollectionView DataSource & Delegate

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        let photo = searchResults[indexPath.item]
        cell.configure(with: photo)
        return cell
    }

    // MARK: - Actions

    @objc private func viewModeChanged() {
        collectionView.reloadData()
    }
    
    @objc private func sortChanged() {
        currentSort = sortSegmentedControl.selectedSegmentIndex == 0 ? "relevant" : "latest"
        if let query = searchBar.text, !query.isEmpty {
            searchPhotos(query: query)
        }
    }

    // MARK: - CollectionView Layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if segmentedControl.selectedSegmentIndex == 0 {
            let width = (collectionView.bounds.width - 30) / 2
            return CGSize(width: width, height: width)
        } else {
            let width = collectionView.bounds.width - 20
            return CGSize(width: width, height: width)
        }
    }
}
