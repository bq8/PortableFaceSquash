//
//  PFSVertexHandle.h
//  PortableFaceSquash
//
//  Created by Brian Quach on 2017/02/21.
//  Copyright © 2017 Brian Quach. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFSVertexHandle;

@protocol PFSVertexHandleDelegate <NSObject>

- (void)vertexHandle:(PFSVertexHandle *)vertexHandle didPan:(UIPanGestureRecognizer *)gestureRecognizer;

@end

@interface PFSVertexHandle : UIView

@property (nonatomic, weak) id<PFSVertexHandleDelegate> delegate;

@end
