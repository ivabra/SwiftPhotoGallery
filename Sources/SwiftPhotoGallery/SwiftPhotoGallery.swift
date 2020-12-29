//
//  SwiftPhotoGallery.swift
//  Pods
//
//  Created by Justin Vallely on 8/25/15.
//
//

import Foundation
import UIKit

@objc public protocol SwiftPhotoGalleryDataSource {
    func numberOfImagesInGallery(gallery:SwiftPhotoGallery) -> Int
    func imageInGallery(gallery:SwiftPhotoGallery, forIndex:Int) -> UIImage?
}

@objc public protocol SwiftPhotoGalleryDelegate {
    func galleryDidTapToClose(gallery:SwiftPhotoGallery)
}


// MARK: ------ SwiftPhotoGallery ------

public class SwiftPhotoGallery: UIViewController {

    fileprivate var animateImageTransition = false

    public weak var dataSource: SwiftPhotoGalleryDataSource?
    public weak var delegate: SwiftPhotoGalleryDelegate?

    public lazy var imageCollectionView: UICollectionView = self.setupCollectionView()

    public var numberOfImages: Int {
        return collectionView(imageCollectionView, numberOfItemsInSection: 0)
    }

    public var backgroundColor: UIColor {
        get {
            return view.backgroundColor!
        }
        set(newBackgroundColor) {
            view.backgroundColor = newBackgroundColor
        }
    }

    public var currentPageIndicatorTintColor: UIColor {
        get {
            return pageControl.currentPageIndicatorTintColor!
        }
        set(newCurrentPageIndicatorTintColor) {
            pageControl.currentPageIndicatorTintColor = newCurrentPageIndicatorTintColor
        }
    }

    public var pageIndicatorTintColor: UIColor {
        get {
            return pageControl.pageIndicatorTintColor!
        }
        set(newPageIndicatorTintColor) {
            pageControl.pageIndicatorTintColor = newPageIndicatorTintColor
        }
    }

    public var currentPage: Int {
      set {
        if newValue < numberOfImages {
            scrollToImage(index: newValue, animated: true)
        } else {
            scrollToImage(index: numberOfImages - 1, animated: true)
        }
        updatePageControl()
      }
      get {
        Int(imageCollectionView.contentOffset.x / imageCollectionView.frame.size.width)
      }
    }

    #if os(iOS)
    public var hideStatusBar: Bool = true {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    #endif

    public var isSwipeToDismissEnabled: Bool = true
    public var isRevolvingCarouselEnabled: Bool = true

  //  private var pageBeforeRotation: Int = 0
    private var currentIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    private var flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    fileprivate var pageControl: UIPageControl = UIPageControl()
    private var pageControlBottomConstraint: NSLayoutConstraint?
    private var pageControlCenterXConstraint: NSLayoutConstraint?
    private var needsLayout = true

    // MARK: Public Interface
    public init(delegate: SwiftPhotoGalleryDelegate, dataSource: SwiftPhotoGalleryDataSource) {
        super.init(nibName: nil, bundle: nil)

        self.dataSource = dataSource
        self.delegate = delegate
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public func reload(imageIndexes:Int...) {

        if imageIndexes.isEmpty {
            imageCollectionView.reloadData()

        } else {
            let indexPaths: [IndexPath] = imageIndexes.map({IndexPath(item: $0, section: 0)})
            imageCollectionView.reloadItems(at: indexPaths)
        }
    }


    // MARK: Lifecycle methods


    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black

        pageControl.currentPageIndicatorTintColor = UIColor.white
        pageControl.pageIndicatorTintColor = UIColor(white: 0.75, alpha: 0.35) //Dim Gray

        isRevolvingCarouselEnabled = numberOfImages > 1
        setupPageControl()
    }
  
  
    #if os(iOS)
    public override var prefersStatusBarHidden: Bool {
        get {
            return hideStatusBar
        }
    }
    #endif


    // MARK: Rotation Handling
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
      //  deviceInRotation = true
        needsLayout = true
    }

    #if os(iOS)
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .allButUpsideDown
        }
    }
    #endif

    #if os(iOS)
    public override var shouldAutorotate: Bool {
        get {
            return true
        }
    }
    #endif

    // MARK: - Internal Methods

    func updatePageControl() {
        pageControl.currentPage = currentPage
    }

    @objc public func singleTapAction(recognizer: UITapGestureRecognizer) {
        delegate?.galleryDidTapToClose(gallery: self)
    }


    // MARK: Private Methods

    private func setupCollectionView() -> UICollectionView {
        // Set up flow layout
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0

        // Set up collection view
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(SwiftPhotoGalleryCell.self, forCellWithReuseIdentifier: "SwiftPhotoGalleryCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        #if os(iOS)
            collectionView.isPagingEnabled = true
        #endif

        // Set up collection view constraints
        var imageCollectionViewConstraints: [NSLayoutConstraint] = []
        imageCollectionViewConstraints.append(NSLayoutConstraint(item: collectionView,
                                                                 attribute: .leading,
                                                                 relatedBy: .equal,
                                                                 toItem: view,
                                                                 attribute: .leading,
                                                                 multiplier: 1,
                                                                 constant: 0))

        imageCollectionViewConstraints.append(NSLayoutConstraint(item: collectionView,
                                                                 attribute: .top,
                                                                 relatedBy: .equal,
                                                                 toItem: view,
                                                                 attribute: .top,
                                                                 multiplier: 1,
                                                                 constant: 0))

        imageCollectionViewConstraints.append(NSLayoutConstraint(item: collectionView,
                                                                 attribute: .trailing,
                                                                 relatedBy: .equal,
                                                                 toItem: view,
                                                                 attribute: .trailing,
                                                                 multiplier: 1,
                                                                 constant: 0))

        imageCollectionViewConstraints.append(NSLayoutConstraint(item: collectionView,
                                                                 attribute: .bottom,
                                                                 relatedBy: .equal,
                                                                 toItem: view,
                                                                 attribute: .bottom,
                                                                 multiplier: 1,
                                                                 constant: 0))

        view.addSubview(collectionView)
        view.addConstraints(imageCollectionViewConstraints)

        collectionView.contentSize = CGSize(width: 1000.0, height: 1.0)

        return collectionView
    }
  
  private func scrollToImage(index: Int, animated: Bool) {
    imageCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: [.centeredHorizontally, .top], animated: animated)
  }

    private func setupPageControl() {

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.isUserInteractionEnabled = false

        pageControl.numberOfPages = numberOfImages
        pageControl.currentPage = 0

        pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor
        pageControl.pageIndicatorTintColor = pageIndicatorTintColor

        pageControl.alpha = 1
        //pageControl.isHidden = hidePageControl

        view.addSubview(pageControl)
      
       

        pageControlCenterXConstraint = NSLayoutConstraint(item: pageControl,
                                                          attribute: NSLayoutConstraint.Attribute.centerX,
                                                          relatedBy: NSLayoutConstraint.Relation.equal,
                                                          toItem: view,
                                                          attribute: NSLayoutConstraint.Attribute.centerX,
                                                          multiplier: 1.0,
                                                          constant: 0)

        pageControlBottomConstraint = NSLayoutConstraint(item: view as Any,
                                                         attribute: NSLayoutConstraint.Attribute.bottom,
                                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                                         toItem: pageControl,
                                                         attribute: NSLayoutConstraint.Attribute.bottom,
                                                         multiplier: 1.0,
                                                         constant: 15)

        view.addConstraints([pageControlCenterXConstraint!, pageControlBottomConstraint!])
    }

    fileprivate func getImage(currentPage: Int) -> UIImage {
        let imageForPage = dataSource?.imageInGallery(gallery: self, forIndex: currentPage)
        return imageForPage!
    }

}


// MARK: UICollectionViewDataSource Methods
extension SwiftPhotoGallery: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ imageCollectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfImagesInGallery(gallery: self) ?? 0
    }

    public func collectionView(_ imageCollectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = imageCollectionView.dequeueReusableCell(withReuseIdentifier: "SwiftPhotoGalleryCell", for: indexPath) as! SwiftPhotoGalleryCell
        cell.image = getImage(currentPage: indexPath.row)
        return cell
    }
  
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
      collectionView.safeAreaBounds
    }
}


extension UIView {
  
  var safeAreaBounds: CGSize {
    bounds.inset(by: safeAreaInsets).size
  }
  
}


// MARK: UICollectionViewDelegate Methods
extension SwiftPhotoGallery: UICollectionViewDelegate {

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        animateImageTransition = true
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        animateImageTransition = false
        updatePageControl()
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? SwiftPhotoGalleryCell {
            cell.configureForNewImage(animated: animateImageTransition)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if let cell = view as? SwiftPhotoGalleryCell {
            collectionView.layoutIfNeeded()
            cell.configureForNewImage(animated: animateImageTransition)
        }
    }
  
}


// MARK: UIGestureRecognizerDelegate Methods
extension SwiftPhotoGallery: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return otherGestureRecognizer is UITapGestureRecognizer &&
            gestureRecognizer is UITapGestureRecognizer &&
            otherGestureRecognizer.view is SwiftPhotoGalleryCell &&
            gestureRecognizer.view == imageCollectionView
    }
}
