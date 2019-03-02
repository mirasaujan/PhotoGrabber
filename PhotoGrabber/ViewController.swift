//
//  ViewController.swift
//  PhotoGrabber
//
//  Created by Miras Karazhigitov on 2019-02-28.
//  Copyright © 2019 Miras Karazhigitov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    enum Constant {
        static let cellID = "cellID"
        static let thumbnailSize = CGSize(width: 300, height: 300)
    }
    
    let collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = Constant.thumbnailSize
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let photoService = PhotoGrabber()

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePhotoService()
        configureCollectionView()
    }
    
    private func configurePhotoService() {
        photoService.collectionView = collectionView
        photoService.thumbnailSize = Constant.thumbnailSize
    }
    
    private func configureCollectionView() {
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Constant.cellID)
        collectionView.dataSource = self
        collectionView.delegate = self
        layout()
    }

    private func layout() {
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoService.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constant.cellID, for: indexPath)
        photoService.getImage(at: indexPath.item) { (image) in
            cell.backgroundView = UIImageView(image: image)
        }
        
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        photoService.updateCachedAssets()
    }
}
