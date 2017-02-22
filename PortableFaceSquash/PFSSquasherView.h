//
//  PFSSquasherView.h
//  PortableFaceSquash
//
//  Created by Brian Quach on 2017/02/22.
//  Copyright © 2017 Brian Quach. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PFSSquasherView : UIView

- (void)render;
- (void)updateHandle:(NSUInteger)handle position:(CGPoint)position;

@end
