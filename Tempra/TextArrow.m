//
//  UIView+TextArrow.m
//  Tempra
//
//  Created by Che-Wei Wang on 9/10/14.
//
//

#import "TextArrow.h"
#define SLIDESPEED .10
@implementation TextArrow :UILabel


- (id)initWithFrame:(CGRect)theFrame {
    self = [super initWithFrame:theFrame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        //self.textAlignment=NSTextAlignmentLeft;
        //self.font = [UIFont fontWithName:@"DIN Condensed" size:38.0];
        self.text = @"";
        
        
        int h=self.frame.size.height;
            
        self.instructionText = [ [UILabel alloc ] initWithFrame:CGRectMake(h*.5, 0, self.frame.size.width, h*1.25) ];
        self.instructionText.textColor = [UIColor whiteColor];
        self.instructionText.backgroundColor = [UIColor clearColor];
        self.instructionText.font = [UIFont fontWithName:@"DIN Condensed" size:self.frame.size.height];
        self.instructionText.text = @"";
        self.instructionText.alpha=1;
        [self addSubview:self.instructionText];
        [self bringSubviewToFront:self.instructionText];
        
        self.rightLabel = [ [UILabel alloc ] initWithFrame:CGRectMake(h*.5, 0, self.frame.size.width-h*.5-5, h*1.25) ];
        self.rightLabel.textColor = [UIColor whiteColor];
        self.rightLabel.textAlignment=NSTextAlignmentRight;
        self.rightLabel.backgroundColor = [UIColor clearColor];
        self.rightLabel.font = [UIFont fontWithName:@"DIN Condensed" size:self.frame.size.height];
        self.rightLabel.text = @"";
        self.rightLabel.alpha=1;
        [self addSubview:self.rightLabel];
        [self bringSubviewToFront:self.rightLabel];
        
        self.color=[UIColor colorWithRed:1 green:1 blue:0 alpha:1];
        saveFrame=theFrame;
        self.drawArrow=true;
        self.drawArrowRight=false;

        
    }
    return self;
}



- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextBeginPath(ctx);
    if(self.drawArrowRight){
        CGContextMoveToPoint (ctx, CGRectGetMaxX(rect), CGRectGetMidY(rect));  // mid left
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect)-CGRectGetMaxY(rect)/2, CGRectGetMaxY(rect));  // bottom left
        CGContextAddLineToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));  // bottom left
        CGContextAddLineToPoint(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));  // top left
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect)-CGRectGetMaxY(rect)/2, CGRectGetMinY(rect));  // mid right
    }
    else if(self.drawArrow){
        CGContextMoveToPoint (ctx, CGRectGetMinX(rect), CGRectGetMidY(rect));  // mid left
        CGContextAddLineToPoint(ctx, CGRectGetMinX(rect)+CGRectGetMaxY(rect)/2, CGRectGetMaxY(rect));  // bottom left
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));  // bottom right
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect)-CGRectGetMaxY(rect)/2, CGRectGetMidY(rect));  // mid right
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));  // top right
        CGContextAddLineToPoint(ctx, CGRectGetMinX(rect)+CGRectGetMaxY(rect)/2, CGRectGetMinY(rect));  // top left
    }else{
        CGContextMoveToPoint (ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        CGContextAddLineToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    }
    
    
    
    CGContextClosePath(ctx);

    
    CGFloat r,g,b,a;
    [self.color getRed:&r green:&g blue:&b alpha:&a];
    
    CGContextSetRGBFillColor(ctx, r, g, b, a);
    CGContextFillPath(ctx);
    
    
    [super drawRect: rect];

}

-(void)resetFrame{
    self.frame=saveFrame;
}
-(void)resetFrameY{
    self.frame=CGRectMake(self.frame.origin.x, saveFrame.origin.y, self.frame.size.width, self.frame.size.height);
}

-(void)slideDown:(float) delay{
    
    if(self.frame.origin.y<[[UIScreen mainScreen] bounds].size.height){
        [UIView animateWithDuration:SLIDESPEED*2
                              delay:delay
             usingSpringWithDamping:.8
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             self.frame = CGRectMake(0,[[UIScreen mainScreen] bounds].size.height,self.frame.size.width,self.frame.size.height);
                         }
                         completion:^(BOOL finished){
                             //set arrow to below frame
                             self.frame = CGRectMake(0,[[UIScreen mainScreen] bounds].size.height,saveFrame.size.width,saveFrame.size.height);
                             
                         }];
    }
    else{
        self.frame = CGRectMake(0,[[UIScreen mainScreen] bounds].size.height,saveFrame.size.width,saveFrame.size.height);
    }

    [self setNeedsDisplay];
}

-(void)slideUp:(float) delay{
    
    if(self.frame.origin.y>=[[UIScreen mainScreen] bounds].size.height){
        [UIView animateWithDuration:SLIDESPEED
                              delay:delay
             usingSpringWithDamping:.8
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             self.frame = saveFrame;
                         }
                         completion:^(BOOL finished){
                             //set arrow to below frame
                             self.frame = saveFrame;
                             
                         }];
    }
    else{
        self.frame = saveFrame;
    }
    
    [self setNeedsDisplay];
}

-(void)slideUpTo:(float)yPos delay:(float) delay{
    
    if(self.frame.origin.y>=[[UIScreen mainScreen] bounds].size.height){
        [UIView animateWithDuration:SLIDESPEED
                              delay:delay
             usingSpringWithDamping:.8
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             self.frame = CGRectMake(self.frame.origin.x, yPos, self.frame.size.width, self.frame.size.height);
                         }
                         completion:^(BOOL finished){
                             //set arrow to below frame
                             self.frame = CGRectMake(self.frame.origin.x, yPos, self.frame.size.width, self.frame.size.height);
                         }];
    }
    else{
        self.frame = CGRectMake(self.frame.origin.x, yPos, self.frame.size.width, self.frame.size.height);
    }
    
    [self setNeedsDisplay];
}


-(void)slideOut:(float) delay{
    
    if(self.frame.origin.x<10 && self.frame.origin.x>=0 ){
    [UIView animateWithDuration:SLIDESPEED
                          delay:delay
         usingSpringWithDamping:.8
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.frame = CGRectMake(-self.frame.size.width*1.1,self.frame.origin.y,self.frame.size.width,self.frame.size.height);
                     }
                     completion:^(BOOL finished){
                         //set arrow to right of frame
                         self.frame = CGRectMake(saveFrame.size.width*1.1,saveFrame.origin.y,saveFrame.size.width,saveFrame.size.height);

                     }];
    }
    else{
        self.frame = CGRectMake(saveFrame.size.width*1.1,saveFrame.origin.y,saveFrame.size.width,saveFrame.size.height);
    }
    
    
    
    [self setNeedsDisplay];
}




-(void)slideIn:(float) delay{
    
    //set arrow to right of frame
    self.frame = CGRectMake(saveFrame.size.width*1.1,saveFrame.origin.y,saveFrame.size.width,saveFrame.size.height);

    [UIView animateWithDuration:SLIDESPEED
                           delay:delay
          usingSpringWithDamping:.8
           initialSpringVelocity:1.0
                         options:UIViewAnimationOptionCurveLinear
                      animations:^{
                          self.frame = CGRectMake(0,saveFrame.origin.y,saveFrame.size.width,saveFrame.size.height);
                      }
                      completion:^(BOOL finished){
                          self.frame = CGRectMake(0,saveFrame.origin.y,saveFrame.size.width,saveFrame.size.height);
                      }];
    
    [self setNeedsDisplay];
}

-(void)updateText:(NSString*) str animate:(BOOL) animate{

    if(animate){
    [UIView animateWithDuration:SLIDESPEED
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.frame = CGRectMake(-self.frame.size.width,self.frame.origin.y,self.frame.size.width,self.frame.size.height);
                     }
                     completion:^(BOOL finished){
                         self.instructionText.text=str;
                         self.frame = CGRectMake(self.frame.size.width*1.1,self.frame.origin.y,self.frame.size.width,self.frame.size.height);

                         [UIView animateWithDuration:SLIDESPEED
                                               delay:0.1
                              usingSpringWithDamping:.8
                               initialSpringVelocity:1.0
                                             options:UIViewAnimationOptionCurveLinear
                          
                                          animations:^{
                                              self.frame = CGRectMake(0,self.frame.origin.y,self.frame.size.width,self.frame.size.height);
                                          }
                                          completion:^(BOOL finished){
                                          }];
                         
                     }];
    }
    else{
        self.instructionText.text=str;
    }
    
    [self setNeedsDisplay];
}

-(void)update:(NSString*) str rightLabel:(NSString*) rStr color:(UIColor*)c animate:(BOOL) animate{
    
    if(animate){
        [UIView animateWithDuration:SLIDESPEED
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.frame = CGRectMake(-self.frame.size.width,self.frame.origin.y,self.frame.size.width,self.frame.size.height);
                         }
                         completion:^(BOOL finished){
                             self.instructionText.text=str;
                             self.rightLabel.text=rStr;
                             self.color=c;
                             [self setNeedsDisplay];

                             self.frame = CGRectMake(self.frame.size.width*1.25,self.frame.origin.y,self.frame.size.width,self.frame.size.height);
                             
                             [UIView animateWithDuration:SLIDESPEED
                                                   delay:0.1
                                  usingSpringWithDamping:.8
                                   initialSpringVelocity:1.0
                                                 options:UIViewAnimationOptionCurveLinear
                                              animations:^{
                                                  self.frame = CGRectMake(0,self.frame.origin.y,self.frame.size.width,self.frame.size.height);
                                              }
                                              completion:^(BOOL finished){
                                              }];
                             
                         }];
    }
    else{
        self.instructionText.text=str;
        self.rightLabel.text=rStr;
        self.color=c;
    }
    
    [self setNeedsDisplay];
}
-(void) setArrowColor:(UIColor *)c
{
    self.color=c;
    [self setNeedsDisplay];
}

-(void)bounce{
    [UIView animateWithDuration:SLIDESPEED
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.frame = CGRectMake(120,self.frame.origin.y,self.frame.size.width,self.frame.size.height);
                     }
                     completion:^(BOOL finished){
                         
                         [UIView animateWithDuration:SLIDESPEED*2
                                               delay:0
                              usingSpringWithDamping:.25
                               initialSpringVelocity:.1
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.frame = CGRectMake(0,self.frame.origin.y,self.frame.size.width,self.frame.size.height);
                                          }
                                          completion:^(BOOL finished){
                                          }];
                         
                     }];
   
}

@end
