//
//  PhotoGrabber.swift
//  PhotoBrowse iOS
//
//  Created by Miras Karazhigitov on 2019-02-28.
//  Copyright © 2019 Apple. All rights reserved.
//

import Photos

class PhotoGrabber: NSObject {
    
    /// TODO: Add options to all get methods to allow to override retireve data options 
    
    /// Public variables
    
    /// Fetch items (Images, Photos, Audio)
    public var fetchResult: PHFetchResult<PHAsset>!
    
    /// CollectionView to represent data.
    public var collectionView: UICollectionView?
    
    /// Number of fetched items
    public var count: Int {
        return fetchResult.count
    }
    
    /// MARK: Configuration Items
    
    /// Default options to get video data
    public var videoRequestOptions: PHVideoRequestOptions?
    
    /// Default options to get image data
    public var photoRequestOptions: PHImageRequestOptions?
    
    /// Target size of an asset to retrieve
    public var thumbnailSize: CGSize = .zero
    
    /// Private variables
    private let imageManager = PHCachingImageManager()
    private var previousPreheatRect = CGRect.zero
    
    override init() {
        if self.fetchResult == nil {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            self.fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        }
        super.init()
        
        resetCachedAssets()
        PHPhotoLibrary.shared().register(self)
        updateCachedAssets()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}
    
extension PhotoGrabber {
    /// Retrieve image from provided fetchResult
    ///
    /// - Parameters:
    ///   - index: Item's index in fetchResult
    ///   - completion: UIImage
    public func getImage(at index: Int, completion: @escaping (UIImage) -> Void) {
        let asset = fetchResult.object(at: index)
        imageManager.requestImage(for: asset,
                                  targetSize: thumbnailSize,
                                  contentMode: .aspectFill,
                                  options: photoRequestOptions,
                                  resultHandler: { image, _ in
            guard let checkedImage = image else { return }
            completion(checkedImage)
        })
    }
    
    /// Retrieve video and audio from provided fetchResult
    ///
    /// - Parameters:
    ///   - index: Item's index in fetchResult
    ///   - completion: AVAsset and AVAudioMix
    public func getVideo(at index: Int, completion: @escaping (AVAsset, AVAudioMix) -> Void) {
        let asset = fetchResult.object(at: index)
        imageManager.requestAVAsset(forVideo: asset, options: videoRequestOptions) { (video, audio, _) in
            guard let checkedVideo = video, let checkedAudio = audio else { return }
            completion(checkedVideo, checkedAudio)
        }
    }
    
    /// Retrieve player item from fetch cached items
    ///
    /// - Parameters:
    ///   - index: Item's index in fetchResult
    ///   - completion: AVPlayerItem
    public func getPlayerItem(at index: Int, completion: @escaping (AVPlayerItem) -> Void) {
        let asset = fetchResult.object(at: index)
        imageManager.requestPlayerItem(forVideo: asset, options: videoRequestOptions) { (playerItem, _) in
            guard let checkedPlayerItem = playerItem else { return }
            completion(checkedPlayerItem)
        }
    }
}

extension PhotoGrabber {
    /// Retrieve image from fetch cached items
    ///
    /// - Parameters:
    ///   - asset: Data model object
    ///   - completion: UIImage
    public func getImage(asset: PHAsset, completion: @escaping (UIImage) -> Void) {
        imageManager.requestImage(for: asset,
                                  targetSize: thumbnailSize,
                                  contentMode: .aspectFill,
                                  options: photoRequestOptions,
                                  resultHandler: { image, _ in
                                    guard let checkedImage = image else { return }
                                    completion(checkedImage)
        })
    }
    
    /// Retrieve video and audio from fetch cached items
    ///
    /// - Parameters:
    ///   - asset: Data model object
    ///   - completion: AVAsset and AVAudioMix
    public func getVideo(asset: PHAsset, completion: @escaping (AVAsset, AVAudioMix) -> Void) {
        imageManager.requestAVAsset(forVideo: asset, options: videoRequestOptions) { (video, audio, _) in
            guard let checkedVideo = video, let checkedAudio = audio else { return }
            completion(checkedVideo, checkedAudio)
        }
    }
    
    /// Retrieve player item from fetch cached items
    ///
    /// - Parameters:
    ///   - index: Data model object
    ///   - completion: AVPlayerItem
    public func getPlayerItem(asset: PHAsset, completion: @escaping (AVPlayerItem) -> Void) {
        imageManager.requestPlayerItem(forVideo: asset, options: videoRequestOptions) { (playerItem, _) in
            guard let checkedPlayerItem = playerItem else { return }
            completion(checkedPlayerItem)
        }
    }
}

extension PhotoGrabber: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: fetchResult)
            else { return }
        
        DispatchQueue.main.async {
            self.fetchResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                self.collectionView?.performBatchUpdates({
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        self.collectionView?.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    
                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        self.collectionView?.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    
                    changes.enumerateMoves { fromIndex, toIndex in
                        self.collectionView?.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
                
                if let changed = changes.changedIndexes, !changed.isEmpty {
                    self.collectionView?.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                }
                
            } else {
                self.collectionView?.reloadData()
            }
            
            self.resetCachedAssets()
        }
    }
    
    /// Add this method to scrollViewDidScroll() of your collectionView
    public func updateCachedAssets() {
        guard collectionView != nil else { return }
        
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > collectionView!.bounds.height / 3 else { return }
        
        let (addedRects, removedRects) = previousPreheatRect.differencesBetweenRects(preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize,
                                        contentMode: .aspectFill,
                                        options: photoRequestOptions)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize,
                                       contentMode: .aspectFill,
                                       options: photoRequestOptions)
        previousPreheatRect = preheatRect
    }
    
    public func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
}

private extension CGRect {
    func differencesBetweenRects(_ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if self.intersects(new) {
            var added = [CGRect]()
            if new.maxY > self.maxY {
                added += [CGRect(x: new.origin.x, y: self.maxY,
                                 width: new.width, height: new.maxY - self.maxY)]
            }
            if self.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: self.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < self.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: self.maxY - new.maxY)]
            }
            if self.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: self.minY,
                                   width: new.width, height: new.minY - self.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [self])
        }
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}
