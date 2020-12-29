//
//  MainCollectionViewController.swift
//  SwiftPhotoGallery
//
//  Created by Justin Vallely on 8/1/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import SwiftPhotoGallery

private let reuseIdentifier = "Cell"

class MainCollectionViewController: UICollectionViewController {

    let imageNames = ["image1.jpeg", "image2.jpeg", "image3.jpeg"]
    let imageTitles = ["Image 1", "Image 2", "Image 3"]
    var index: Int = 0

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MainCollectionViewCell
        cell.imageView.image = UIImage(named: imageNames[indexPath.item])
        return cell
    }

    
    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        index = indexPath.item

        let gallery = SwiftPhotoGallery(delegate: self, dataSource: self)
        gallery.backgroundColor = UIColor.black
        gallery.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.5)
        gallery.currentPageIndicatorTintColor = UIColor(red: 0.0, green: 0.66, blue: 0.875, alpha: 1.0)
      
        let nav = UINavigationController(rootViewController: gallery)
        nav.modalPresentationStyle = .fullScreen

        /// Load the first page like this:

        /// Or load on a specific page like this:

      present(nav, animated: true) {
        gallery.currentPage = self.index
      }
    }

}


// MARK: SwiftPhotoGalleryDataSource Methods
extension MainCollectionViewController: SwiftPhotoGalleryDataSource {

    func numberOfImagesInGallery(gallery: SwiftPhotoGallery) -> Int {
        return imageNames.count
    }

    func imageInGallery(gallery: SwiftPhotoGallery, forIndex: Int) -> UIImage? {
        return UIImage(named: imageNames[forIndex])
    }
}


// MARK: SwiftPhotoGalleryDelegate Methods
extension MainCollectionViewController: SwiftPhotoGalleryDelegate {

    func galleryDidTapToClose(gallery: SwiftPhotoGallery) {
        self.index = gallery.currentPage
        dismiss(animated: true, completion: nil)
    }
}


// MARK: UIViewControllerTransitioningDelegate Methods
extension MainCollectionViewController: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let selectedCellFrame = self.collectionView?.cellForItem(at: IndexPath(item: index, section: 0))?.frame else { return nil }
        return PresentingAnimator(pageIndex: index, originFrame: selectedCellFrame)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let returnCellFrame = self.collectionView?.cellForItem(at: IndexPath(item: index, section: 0))?.frame else { return nil }
        return DismissingAnimator(pageIndex: index, finalFrame: returnCellFrame)
    }
}
