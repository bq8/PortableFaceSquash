//
//  PFSVertexHandle.m
//  PortableFaceSquash
//
//  Created by Brian Quach on 2017/02/21.
//  Copyright © 2017 Brian Quach. All rights reserved.
//

#import "PFSVertexHandle.h"

@interface PFSVertexHandle ()

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation PFSVertexHandle

#pragma mark - Lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handlePanGesture)];
    [self addGestureRecognizer:self.panGestureRecognizer];
    self.backgroundColor = [UIColor redColor];
}

#pragma mark - Gesture Recognizers

- (void)handlePanGesture {
    [self.delegate vertexHandle:self
                         didPan:self.panGestureRecognizer];
}

@end
