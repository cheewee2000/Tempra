//
//  UIView+Dots.m
//  Tempra
//
//  Created by Che-Wei Wang on 9/8/14.
//
//

#import "Dots.h"

@implementation Dots:UIView 

- (id)initWithFrame:(CGRect)theFrame {
    self = [super initWithFrame:theFrame];
    if (self) {
        startFrame=self.frame;

        
        self.clipsToBounds=NO;

        self.dotColor=[UIColor blackColor];
        
        self.label=[[UILabel alloc] initWithFrame:CGRectMake(0, 42, 100, 20)];
        self.label.text=@"";
        self.label.textAlignment = NSTextAlignmentLeft;
        [self.label setTransform:CGAffineTransformMakeRotation(M_PI *.25)];
        [self addSubview:self.label];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];

        self.level=[[UILabel alloc] initWithFrame:CGRectMake(0, 42, 100, 20)];
        self.level.text=@"";
        self.level.textAlignment = NSTextAlignmentLeft;
        [self.level setTransform:CGAffineTransformMakeRotation(M_PI *.25)];
        [self addSubview:self.level];
        self.level.backgroundColor = [UIColor clearColor];
        self.level.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];

    
        int starSize=43;
        stars=[NSArray array];
        UIImageView* starLeft=[[UIImageView alloc] init];
        [starLeft setImage:[[UIImage imageNamed: @"starLeft"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        starLeft.frame=CGRectMake(0,0,starSize,starSize);
        starLeft.center=CGPointMake(self.frame.size.width/2.0, self.frame.size.height/2.0);
        [self addSubview:starLeft];
        starLeft.alpha=0;
        stars = [stars arrayByAddingObject:starLeft];
        
        UIImageView* starMiddle=[[UIImageView alloc] init];
        [starMiddle setImage:[[UIImage imageNamed: @"starMiddle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        starMiddle.frame=CGRectMake(0,0,starSize,starSize);
        starMiddle.center=CGPointMake(self.frame.size.width/2.0, self.frame.size.height/2.0);
        [self addSubview:starMiddle];
        starMiddle.alpha=0;
        stars = [stars arrayByAddingObject:starMiddle];
        
        UIImageView* starRight=[[UIImageView alloc] init];
        [starRight setImage:[[UIImage imageNamed: @"starRight"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        starRight.frame=CGRectMake(0,0,starSize,starSize);
        starRight.center=CGPointMake(self.frame.size.width/2.0, self.frame.size.height/2.0);
        [self addSubview:starRight];
        starRight.alpha=0;
        stars = [stars arrayByAddingObject:starRight];

        
    }
    return self;
}



- (void) animateAlongPath:(CGRect)orbit rotate:(float) radians speed:(float)speed{
    // Set up path movement
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.calculationMode = kCAAnimationPaced;
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.repeatCount = INFINITY;
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    pathAnimation.duration = 3.0;
    pathAnimation.speed =speed;
    
    // Create a circle path
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    CGRect circleContainer = orbit; // create a circle from this square, it could be the frame of an UIView
    
    CGPathAddEllipseInRect(curvedPath, NULL, circleContainer);
    
    CGRect bounds = CGPathGetBoundingBox(curvedPath); // might want to use CGPathGetPathBoundingBox
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, center.x, center.y);
    transform = CGAffineTransformRotate(transform, radians);
    transform = CGAffineTransformTranslate(transform, -center.x, -center.y);
    CGPathRef rotatedPath=CGPathCreateCopyByTransformingPath(curvedPath, &transform);

    pathAnimation.path = rotatedPath;
    CGPathRelease(curvedPath);
    
    [self.layer addAnimation:pathAnimation forKey:@"myCircleAnimation"];
}


- (void)drawRect:(CGRect)rect
{
    CGFloat lineWidth = 1;
    CGRect borderRect = CGRectInset(rect, lineWidth , lineWidth );
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat r,g,b,a;
    [self.dotColor getRed:&r green:&g blue:&b alpha:&a];
    
    CGContextSetRGBStrokeColor(context, r, g, b, a);
    CGContextSetRGBFillColor(context, r, g, b, a);

//    CGContextSetRGBStrokeColor(context, 0,0,0, 1.0);
//     CGContextSetRGBFillColor(context, 0, 0, 0, 1.0);
    CGContextSetLineWidth(context, lineWidth);
    if(fill) CGContextFillEllipseInRect (context, borderRect);
    CGContextStrokeEllipseInRect(context, borderRect);
    CGContextFillPath(context);
}
-(void) resetPosition
{
    self.frame=startFrame;
    [self setNeedsDisplay];
}

-(void) setFill:(bool) b
{
    fill=b;
    [self setNeedsDisplay];
}
-(void) setColor:(UIColor *)color
{
    self.dotColor=color;
    for(int i=0; i<[stars count]; i++){
        UIImageView*s=[stars objectAtIndex:i];
        s.tintColor=color;
    }
    self.label.textColor=color;
    self.level.textColor=color;
}
-(void) setText:(NSString *) s level:(NSString *)l
{
    self.label.text=s;
    self.label.alpha=0.0;
    
    self.level.text=l;
    self.level.alpha=0.0;


    self.label.alpha=1.0;
    self.level.alpha=1.0;
    [self setNeedsDisplay];
}

-(void) setStars:(int)s{
    if(s==0){
        for(int i=0; i<[stars count]; i++){
            UIImageView *star=[stars objectAtIndex:i];
            star.alpha=0;
        }
        [self setNeedsDisplay];

    }
    
    for(int i=0; i<s; i++){
        UIImageView *star=[stars objectAtIndex:i];

        if(star.alpha<1){
            star.alpha=1;
            star.transform = CGAffineTransformScale(CGAffineTransformIdentity, .001, .001);
        [UIView animateWithDuration:0.4
                              delay:0.2*i
             usingSpringWithDamping:.5
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             star.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
                         }
                         completion:^(BOOL finished){
                        }];
      }
        [self setNeedsDisplay];
    }
    
}

@end
