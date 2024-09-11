import UIKit

// MARK: - PhotoDetailViewController

class PhotoDetailViewController: UIViewController {
    
    var imageView: UIImageView!
    var descriptionLabel: UILabel!
    var authorLabel: UILabel!
    
    var photo: Photo?
    var loadedImage: UIImage?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        // MARK: - UIImageView Setup
        imageView = UIImageView(frame: CGRect(x: 0, y: 100, width: view.bounds.width, height: view.bounds.height / 2))
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        // MARK: - UILabel for Description Setup
        descriptionLabel = UILabel(frame: CGRect(x: 20, y: imageView.frame.maxY + 20, width: view.bounds.width - 40, height: 100))
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(descriptionLabel)
        
        // MARK: - UILabel for Author Setup
        authorLabel = UILabel(frame: CGRect(x: 20, y: descriptionLabel.frame.maxY + 10, width: view.bounds.width - 40, height: 30))
        authorLabel.font = UIFont.boldSystemFont(ofSize: 16)
        view.addSubview(authorLabel)
        
        // MARK: - Data Loading
        if let photo = photo {
            descriptionLabel.text = photo.description ?? "Нет описания"
            authorLabel.text = "Автор: \(photo.author)"
            
            if let url = URL(string: photo.urls.regular) {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data {
                        DispatchQueue.main.async {
                            let image = UIImage(data: data)
                            self.imageView.image = image
                            self.loadedImage = image
                        }
                    }
                }.resume()
            }
        }
        
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareImage))
        navigationItem.rightBarButtonItem = shareButton
        
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Сохранить изображение", for: .normal)
        saveButton.addTarget(self, action: #selector(saveImageToGallery), for: .touchUpInside)
        saveButton.frame = CGRect(x: 20, y: view.bounds.height - 80, width: view.bounds.width - 40, height: 50)
        view.addSubview(saveButton)
    }
    
    // MARK: - Share Image Action
    @objc private func shareImage() {
        guard let imageToShare = loadedImage else { return }
        let activityVC = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
    
    // MARK: - Save Image to Gallery
    @objc private func saveImageToGallery() {
        guard let imageToSave = loadedImage else {
            let alert = UIAlertController(title: "Ошибка", message: "Изображение не загружено", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default))
            present(alert, animated: true)
            return
        }
        UIImageWriteToSavedPhotosAlbum(imageToSave, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    // MARK: - Image Saving Callback
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default))
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Успех", message: "Изображение сохранено в галерею", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default))
            present(alert, animated: true)
        }
    }
}
