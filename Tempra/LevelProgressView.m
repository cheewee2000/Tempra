//
//  LevelProgressView.m
//  Tempra
//
//  Created by Che-Wei Wang on 10/4/14.
//
//

#import "LevelProgressView.h"

@implementation LevelProgressView
- (id)initWithFrame:(CGRect)theFrame {
    self = [super initWithFrame:theFrame];
    if (self) {
        
         _shadowR=10.0;
        _shadowO=.4;
        
        self.dotsContainer=[[UIView alloc] init];
        self.dotsContainer.frame=CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.dotsContainer.clipsToBounds=YES;
        self.dotsContainer.userInteractionEnabled=NO;
        [self addSubview:self.dotsContainer];
        [self bringSubviewToFront:self.dotsContainer];
        
        self.centerMessage=[[UILabel alloc] initWithFrame:CGRectMake(0,0, self.frame.size.width, 160)];
        self.centerMessage.center=CGPointMake(self.frame.size.width/2.0, self.frame.size.height/5.0-80);
        self.centerMessage.text=@"";
        self.centerMessage.textAlignment = NSTextAlignmentCenter;
        self.centerMessage.backgroundColor = [UIColor clearColor];
        self.centerMessage.font = [UIFont fontWithName:@"DIN Condensed" size:140];
        self.centerMessage.textColor=[UIColor whiteColor];
        [self addSubview:self.centerMessage];
        [self bringSubviewToFront:self.centerMessage];
  
//        self.centerMessage.layer.shadowOpacity = _shadowO;
//        self.centerMessage.layer.shadowRadius = _shadowR;
//        self.centerMessage.layer.shadowColor = [UIColor blackColor].CGColor;
//        self.centerMessage.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        

        
        self.subMessage=[[UILabel alloc] initWithFrame:CGRectMake(0,0, self.frame.size.width, 80)];
        self.subMessage.center=CGPointMake(self.frame.size.width/2.0, self.centerMessage.center.y+90);
        self.subMessage.text=@"";
        self.subMessage.numberOfLines=2;
        self.subMessage.textAlignment = NSTextAlignmentCenter;
        self.subMessage.backgroundColor = [UIColor clearColor];
        self.subMessage.font = [UIFont fontWithName:@"DIN Condensed" size:24];
        self.subMessage.textColor=[UIColor whiteColor];
        [self addSubview:self.subMessage];
        [self bringSubviewToFront:self.subMessage];
        
//        self.subMessage.layer.shadowOpacity = _shadowO;
//        self.subMessage.layer.shadowRadius = _shadowR;
//        self.subMessage.layer.shadowColor = [UIColor blackColor].CGColor;
//        self.subMessage.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        
        
        self.lowerMessage=[[UILabel alloc] initWithFrame:CGRectMake(0,0, self.frame.size.width, 40)];
        self.lowerMessage.center=CGPointMake(self.frame.size.width/2.0, self.subMessage.center.y+90);
        self.lowerMessage.text=@"";
        self.lowerMessage.numberOfLines=1;
        self.lowerMessage.textAlignment = NSTextAlignmentCenter;
        self.lowerMessage.backgroundColor = [UIColor clearColor];
        self.lowerMessage.font = [UIFont fontWithName:@"DIN Condensed" size:24];
        self.subMessage.textColor=[UIColor whiteColor];
        [self addSubview:self.lowerMessage];
        [self bringSubviewToFront:self.lowerMessage];
 
        
//        self.lowerMessage.layer.shadowOpacity = _shadowO;
//        self.lowerMessage.layer.shadowRadius = _shadowR;
//        self.lowerMessage.layer.shadowColor = [UIColor blackColor].CGColor;
//        self.lowerMessage.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


-(void)displayMessage:(NSString*)s{
    [self bringSubviewToFront:self.centerMessage];

    self.centerMessage.text=s;
    self.centerMessage.alpha=0;
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.centerMessage.alpha=1;
                     }
                     completion:^(BOOL finished){
                         
                         [UIView animateWithDuration:0.4
                                               delay:0.2
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              self.centerMessage.alpha=0;
                                          }
                                          completion:^(BOOL finished){
                                              
                                          }];
                     }];
    
}

@end
