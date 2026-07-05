//
//  Level.m
//  Tempra
//
//  Created by Che-Wei Wang on 9/17/14.
//
//

#import "Level.h"

@implementation Level


- (id)initWithFrame:(CGRect)theFrame {
    self = [super initWithFrame:theFrame];
    if (self) {
        
        self.label=[[UILabel alloc] initWithFrame:CGRectMake(-10, 50, 100, 20)];
        self.label.text=@"10s";
        self.label.textAlignment = NSTextAlignmentLeft;
        [self.label setTransform:CGAffineTransformMakeRotation(M_PI *2)];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.font = [UIFont fontWithName:@"DIN Condensed" size:10];
        [self addSubview:self.label];
        
        
    }
    return self;
}



@end
