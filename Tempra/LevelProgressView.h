//
//  LevelProgressView.h
//  Tempra
//
//  Created by Che-Wei Wang on 10/4/14.
//
//

#import <UIKit/UIKit.h>

@interface LevelProgressView : UIView
{
   
}
@property UIView * dotsContainer;
@property UILabel * centerMessage;
@property UILabel * subMessage;
@property UILabel * lowerMessage;
@property float shadowR;
@property float shadowO;
-(void)displayMessage:(NSString*)s;

@end
