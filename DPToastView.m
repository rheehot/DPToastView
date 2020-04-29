//
//  DPToastView.m
//  DPToastViewDemo
//
//  Created by Baker, Eric on 2/15/13.
//  Copyright (c) 2013 DuneParkSoftware, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "DPToastView.h"

static id _DP_PreviousToastView = nil;

@interface DPToastView ()
@property (strong, nonatomic) UIView *toastView;
@property (strong, nonatomic) NSMutableArray *windowConstraints;
@property (assign, nonatomic) BOOL cancelNotifications;
@end

@implementation DPToastView
@synthesize message;
@synthesize textAlignment;
@synthesize lineBreakMode;
@synthesize gravity;
@synthesize duration;
@synthesize textColor, backgroundColor, borderColor, shadowColor;
@synthesize font;
@synthesize borderWidth, cornerRadius, shadowOpacity, shadowRadius, fadeInDuration, fadeOutDuration;
@synthesize shadowOffset;
@synthesize innerEdgeInsets;
@synthesize yOffset;
@synthesize horizontalMargin;
@synthesize rightView;

@synthesize toastView;
@synthesize windowConstraints;
@synthesize cancelNotifications;

+ (id)makeToast:(id)message {
    return [[self class] makeToast:message gravity:DPToastGravityBottom duration:DPToastDurationNormal];
}

+ (id)makeToast:(id)message gravity:(DPToastGravity)gravity {
    return [[self class] makeToast:message gravity:gravity duration:DPToastDurationNormal];
}

+ (id)makeToast:(id)message duration:(NSTimeInterval)duration {
    return [[self class] makeToast:message gravity:DPToastGravityBottom duration:duration];
}

+ (id)makeToast:(id)message gravity:(DPToastGravity)gravity duration:(NSTimeInterval)duration {
    return [[[self class] alloc] initWithMessage:message gravity:gravity duration:duration];
}

+ (void)dismissToast {
    if (_DP_PreviousToastView) {
        [[_DP_PreviousToastView toastView] removeFromSuperview];
        [_DP_PreviousToastView setCancelNotifications:YES];
        [[NSNotificationCenter defaultCenter] removeObserver:_DP_PreviousToastView];
        [[NSNotificationCenter defaultCenter] postNotificationName:DPToastViewDidDismissNotification object:_DP_PreviousToastView userInfo:@{ DPToastViewUserInfoKey : _DP_PreviousToastView, DPToastViewStringUserInfoKey : [_DP_PreviousToastView messageString] }];
        _DP_PreviousToastView = nil;
    }
}

- (id)initWithMessage:(id)theMessage gravity:(DPToastGravity)theGravity duration:(NSTimeInterval)theDuration {
    if ((self = [super init])) {
        [self setMessage:theMessage];
        [self setTextAlignment:NSTextAlignmentCenter];
        [self setLineBreakMode:NSLineBreakByWordWrapping];
        [self setGravity:theGravity];
        [self setDuration:theDuration];
        [self setTextColor:[UIColor whiteColor]];
        [self setFont:[UIFont systemFontOfSize:16.0]];
        [self setBackgroundColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8]];
        [self setBorderColor:[[UIColor whiteColor] colorWithAlphaComponent:0.8]];
        [self setBorderWidth:1.5];
        [self setCornerRadius:4.0];
        [self setShadowColor:[UIColor blackColor]];
        [self setShadowOpacity:0.8];
        [self setShadowRadius:5.0];
        [self setShadowOffset:CGSizeZero];
        [self setInnerEdgeInsets:UIEdgeInsetsMake(6, 10, 6, 10)];
        [self setYOffset:(theGravity == DPToastGravityCenter ? 0 : 60)];
        [self setFadeInDuration:0.15];
        [self setFadeOutDuration:0.5];
        [self setHorizontalMargin:16];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toastWasDismissed:) name:DPToastViewDidDismissNotification object:self];
        [self setCancelNotifications:NO];
    }
    return self;
}

- (void)show {
    UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
    [self showInView:window];
}

- (void)showInView:(UIView *)view {
    if (nil == view) return;

    if (nil != _DP_PreviousToastView) {
        [DPToastView dismissToast];
        [self setFadeInDuration:0.0];
    }

    [self buildToastViewForView:view];
    if (nil == toastView) return;

    [[NSNotificationCenter defaultCenter] postNotificationName:DPToastViewWillAppearNotification object:self userInfo:@{ DPToastViewUserInfoKey : self, DPToastViewStringUserInfoKey : [self messageString] }];

    [toastView setAlpha:0.0];
    _DP_PreviousToastView = self;
    [UIView animateWithDuration:[self fadeInDuration]
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self->toastView setAlpha:1.0];
                     }
                     completion:^(BOOL finished) {
                         if (NO == [self cancelNotifications]) {
                             [[NSNotificationCenter defaultCenter] postNotificationName:DPToastViewDidAppearNotification object:self userInfo:@{ DPToastViewUserInfoKey : self, DPToastViewStringUserInfoKey : [self messageString] }];
                         }

                         if (finished) {
                             [self performSelector:@selector(postWillDisappearNotification:) withObject:self afterDelay:[self duration]];

                             [UIView animateWithDuration:[self fadeOutDuration]
                                                   delay:[self duration]
                                                 options:UIViewAnimationOptionCurveEaseIn
                                              animations:^{
                                                  [self->toastView setAlpha:0.0];
                                              }
                                              completion:^(BOOL finished) {

                                                  if (finished) {
                                                      if (NO == [self cancelNotifications]) {
                                                          [[NSNotificationCenter defaultCenter] postNotificationName:DPToastViewDidDisappearNotification object:self userInfo:@{ DPToastViewUserInfoKey : self, DPToastViewStringUserInfoKey : [self messageString] }];
                                                      }
                                                      [DPToastView dismissToast];
                                                  }
                                              }];
                         }
                     }];
}

- (NSString *)messageString {
    if ([[self message] isKindOfClass:[NSString class]]) {
        return (NSString *)[self message];
    } else if ([[self message] isKindOfClass:[NSAttributedString class]]) {
        return [(NSAttributedString *)[self message] string];
    }
    return nil;
}

- (void)toastWasDismissed:(NSNotification *)notification {
    [self setCancelNotifications:YES];
}

- (void)postWillDisappearNotification:(id)sender {
    if (NO == [self cancelNotifications]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DPToastViewWillDisappearNotification object:self userInfo:@{ DPToastViewUserInfoKey : self, DPToastViewStringUserInfoKey : [self messageString] }];
    }
}

- (void)statusBarOrientationChanged:(NSNotification *)notification {
    [self defineConstraintsForToastInView:[self.toastView superview]];
}

- (UIView *)buildToastViewForView:(UIView *)parentView {
    UILabel *label = nil;
    if ([self message]) {
        if ([[self message] isKindOfClass:[NSString class]]) {
            if ([[(NSString *)message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
                label = [[UILabel alloc] init];
                [label setText:(NSString *)message];
                [label setTextColor:[self textColor]];
                [label setTextAlignment:[self textAlignment]];
                [label setLineBreakMode:[self lineBreakMode]];
                [label setFont:[self font]];
            }
        } else if ([[self message] isKindOfClass:[NSAttributedString class]]) {
            if ([[[(NSAttributedString *)message string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
                label = [[UILabel alloc] init];
                [label setAttributedText:(NSAttributedString *)message];
            }
        }
    }
    if (nil == label) return nil;

    [label setBackgroundColor:[UIColor clearColor]];
    [label setNumberOfLines:0];
    [label setUserInteractionEnabled:NO];

    [self setToastView:[[UIView alloc] init]];

    [toastView setBackgroundColor:[self backgroundColor]];
    [toastView setUserInteractionEnabled:YES];
    [toastView.layer setBorderColor:[[self borderColor] CGColor]];
    [toastView.layer setBorderWidth:[self borderWidth]];
    [toastView.layer setCornerRadius:[self cornerRadius]];
    [toastView.layer setShadowColor:[[self shadowColor] CGColor]];
    [toastView.layer setShadowOpacity:[self shadowOpacity]];
    [toastView.layer setShadowRadius:[self shadowRadius]];
    [toastView.layer setShadowOffset:[self shadowOffset]];

    [toastView addSubview:label];
    [parentView addSubview:toastView];
    [parentView bringSubviewToFront:toastView];
    
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    [toastView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [toastView addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:toastView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1
                                                           constant:innerEdgeInsets.top]];
    [toastView addConstraint:[NSLayoutConstraint constraintWithItem:toastView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:label
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:innerEdgeInsets.bottom]];
    [toastView addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:toastView
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1
                                                           constant:innerEdgeInsets.left]];
    if (rightView == nil) {
        [toastView addConstraint:[NSLayoutConstraint constraintWithItem:toastView
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:label
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1
                                                               constant:innerEdgeInsets.right]];
    } else {
        [rightView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [rightView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [toastView addSubview:rightView];
        [label setTextAlignment:NSTextAlignmentLeft];
        NSLayoutConstraint *rightViewMaxWidthConstraint = [NSLayoutConstraint constraintWithItem:rightView
                                                                                       attribute:NSLayoutAttributeWidth
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:nil
                                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                                      multiplier:1
                                                                                        constant:100];
        rightViewMaxWidthConstraint.priority = UILayoutPriorityDefaultLow;
        [toastView addConstraint:rightViewMaxWidthConstraint];
        [toastView addConstraint:[NSLayoutConstraint constraintWithItem:rightView
                                                              attribute:NSLayoutAttributeCenterY
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:label
                                                              attribute:NSLayoutAttributeCenterY
                                                             multiplier:1
                                                               constant:0]];
        [toastView addConstraint:[NSLayoutConstraint constraintWithItem:toastView
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:rightView
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1
                                                               constant:innerEdgeInsets.right]];
        [toastView addConstraint:[NSLayoutConstraint constraintWithItem:rightView
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:label
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1
                                                               constant:16]];
        [toastView addConstraint:[NSLayoutConstraint constraintWithItem:rightView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                 toItem:toastView
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1
                                                               constant:0]];
        [toastView addConstraint:[NSLayoutConstraint constraintWithItem:toastView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                 toItem:rightView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:0]];
    }

    [self defineConstraintsForToastInView:parentView];
    return toastView;
}

- (void)defineConstraintsForToastInView:(UIView *)parentView {
    if (nil == windowConstraints) {
        windowConstraints = [[NSMutableArray alloc] init];

        if ([parentView isKindOfClass:[UIWindow class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        }
    } else {
        [parentView removeConstraints:windowConstraints];
        [parentView setNeedsUpdateConstraints];
        [windowConstraints removeAllObjects];
    }

    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:parentView
                                                              attribute:NSLayoutAttributeLeft
                                                             multiplier:1.0
                                                               constant:self.horizontalMargin]];
    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:parentView
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:toastView
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1.0
                                                               constant:self.horizontalMargin]];

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (NO == [parentView isKindOfClass:[UIWindow class]]) {
        orientation = UIInterfaceOrientationPortrait;
    } else if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
        // UIWindow itself is rotated from iOS 8.0
        orientation = UIInterfaceOrientationPortrait;
    }

    switch (orientation) {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortrait: {
            [toastView setTransform:CGAffineTransformMakeRotation(0)];

            [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                      attribute:NSLayoutAttributeCenterX
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:parentView
                                                                      attribute:NSLayoutAttributeCenterX
                                                                     multiplier:1.0
                                                                       constant:0.0]];

            switch ([self gravity]) {
                case DPToastGravityTop: {
                    CGFloat statusBarHeight = 0;
                    if ([parentView isKindOfClass:[UIWindow class]]) {
                        if (NO == [UIApplication sharedApplication].statusBarHidden) {
                            statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
                        }
                    }
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeTop
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeTop
                                                                             multiplier:1.0
                                                                               constant:ABS(self.yOffset) + statusBarHeight]];
                }
                    break;

                case DPToastGravityCenter: {
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeCenterY
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeCenterY
                                                                             multiplier:1.0
                                                                               constant:self.yOffset]];
                }
                    break;

                case DPToastGravityBottom: {
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeBottom
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeBottom
                                                                             multiplier:1.0
                                                                               constant:(ABS(self.yOffset) * -1)]];
                }
                    break;
            }
        }
            break;

        case UIInterfaceOrientationLandscapeLeft: {
            [toastView setTransform:CGAffineTransformMakeRotation(-M_PI_2)];

            [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:parentView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1.0
                                                                       constant:0.0]];

            switch ([self gravity]) {
                case DPToastGravityTop: {
                    CGFloat statusBarHeight = 0;
                    if ([parentView isKindOfClass:[UIWindow class]]) {
                        if (NO == [UIApplication sharedApplication].statusBarHidden) {
                            statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.width;
                        }
                    }
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeLeft
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeLeft
                                                                             multiplier:1.0
                                                                               constant:ABS(self.yOffset) + statusBarHeight]];
                }
                    break;

                case DPToastGravityCenter: {
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeCenterX
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeCenterX
                                                                             multiplier:1.0
                                                                               constant:self.yOffset]];
                }
                    break;

                case DPToastGravityBottom: {
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeRight
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeRight
                                                                             multiplier:1.0
                                                                               constant:(ABS(self.yOffset) * -1)]];
                }
                    break;
            }
        }
            break;

        case UIInterfaceOrientationLandscapeRight: {
            [toastView setTransform:CGAffineTransformMakeRotation(M_PI_2)];

            [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:parentView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1.0
                                                                       constant:0.0]];

            switch ([self gravity]) {
                case DPToastGravityTop: {
                    CGFloat statusBarHeight = 0;
                    if ([parentView isKindOfClass:[UIWindow class]]) {
                        if (NO == [UIApplication sharedApplication].statusBarHidden) {
                            statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.width;
                        }
                    }
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeRight
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeRight
                                                                             multiplier:1.0
                                                                               constant:-(ABS(self.yOffset) + statusBarHeight)]];
                }
                    break;

                case DPToastGravityCenter: {
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeCenterX
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeCenterX
                                                                             multiplier:1.0
                                                                               constant:-self.yOffset]];
                }
                    break;

                case DPToastGravityBottom: {
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeLeft
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeLeft
                                                                             multiplier:1.0
                                                                               constant:ABS(self.yOffset)]];
                }
                    break;
            }
        }
            break;

        case UIInterfaceOrientationPortraitUpsideDown: {
            [toastView setTransform:CGAffineTransformMakeRotation(M_PI)];

            [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                      attribute:NSLayoutAttributeCenterX
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:parentView
                                                                      attribute:NSLayoutAttributeCenterX
                                                                     multiplier:1.0
                                                                       constant:0.0]];

            switch ([self gravity]) {
                case DPToastGravityTop: {
                    CGFloat statusBarHeight = 0;
                    if ([parentView isKindOfClass:[UIWindow class]]) {
                        if (NO == [UIApplication sharedApplication].statusBarHidden) {
                            statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
                        }
                    }
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeBottom
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeBottom
                                                                             multiplier:1.0
                                                                               constant:-(ABS(self.yOffset) + statusBarHeight)]];
                }
                    break;

                case DPToastGravityCenter: {
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeCenterY
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeCenterY
                                                                             multiplier:1.0
                                                                               constant:-(self.yOffset)]];
                }
                    break;

                case DPToastGravityBottom: {
                    [windowConstraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                                              attribute:NSLayoutAttributeTop
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:parentView
                                                                              attribute:NSLayoutAttributeTop
                                                                             multiplier:1.0
                                                                               constant:ABS(self.yOffset)]];
                }
                    break;
            }
        }
            break;
    }

    [parentView addConstraints:windowConstraints];
}

@end
