//
//  UIScrollView+SEmptyDataSet.m
//  TestEmptyData
//
//  Created by liqi on 2018/6/1.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "UIScrollView+SEmptyDataSet.h"
#import <objc/runtime.h>

@interface UIView (SContraintBasedLayoutExtensions)

- (NSLayoutConstraint *)equallyRelatedConstraintWithView:(UIView *)view
                                               attribute:(NSLayoutAttribute)attribute;

@end

@interface SWeakObjectContainer : NSObject

@property (nonatomic, readonly, weak) id weakObject;

- (instancetype)initWithWeakObject:(id)object;

@end

@interface SEmptyDataSetView : UIView

@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *detailLabel;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIButton *button;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, assign) CGFloat verticalOffset;
@property (nonatomic, assign) CGFloat verticalSpace;

@property (nonatomic, assign) BOOL fadeInOnDisplay;

- (void)setupConstraints;
- (void)prepareForReuse;

@end

#pragma mark - UIScrollView+EmptyDataSet

static char const * const kEmptyDataSetSource = "emptyDataSetSource";
static char const * const kEmptyDataSetDelegate = "emptyDataSetDelegate";
static char const * const kEmptyDataSetView = "emptyDataSetView";

#define kEmptyImageViewAnimationKey @"com.s.emptyDataSet.imageViewAnimation"

@interface UIScrollView () <UIGestureRecognizerDelegate>
@property (nonatomic, readonly) SEmptyDataSetView *emptyDataSetView;
@end

@implementation UIScrollView (SEmptyDataSet)

#pragma mark - Getters (Public)

- (id<SEmptyDataSetSource>)s_emptyDataSetSource
{
    SWeakObjectContainer *container = objc_getAssociatedObject(self, kEmptyDataSetSource);
    return container.weakObject;
}

- (id<SEmptyDataSetDelegate>)s_emptyDataSetDelegate
{
    SWeakObjectContainer *container = objc_getAssociatedObject(self, kEmptyDataSetDelegate);
    return container.weakObject;
}

- (BOOL)s_isEmptyDataSetVisible
{
    UIView *view = objc_getAssociatedObject(self, kEmptyDataSetView);
    return view ? !view.hidden : NO;
}

#pragma mark - Getters (Private)

- (SEmptyDataSetView *)emptyDataSetView
{
    SEmptyDataSetView *view = objc_getAssociatedObject(self, kEmptyDataSetView);
    if (!view) {
        view = [SEmptyDataSetView new];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.hidden = YES;
        view.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(s_didTapContentView:)];
        view.tapGesture.delegate = self;
        [view addGestureRecognizer:view.tapGesture];
        
        [self setEmptyDataSetView:view];
    }
    return view;
}

- (BOOL)s_canDisplay
{
    if (self.s_emptyDataSetSource && [self.s_emptyDataSetDelegate conformsToProtocol:@protocol(SEmptyDataSetSource)]) {
        if ([self isKindOfClass:[UITableView class]] ||
            [self isKindOfClass:[UICollectionView class]] ||
            [self isKindOfClass:[UIScrollView class]]) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)s_itemsCount
{
    NSInteger items = 0;
    
    // UIScrollView 没有dataSource 方法
    if (![self respondsToSelector:@selector(dataSource)]) {
        return items;
    }
    
    // UITableView
    if ([self isKindOfClass:[UITableView class]]) {
        
        UITableView *tableView = (UITableView *)self;
        id<UITableViewDataSource> dataSource = tableView.dataSource;
        
        NSInteger sections = 1;
        
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
            sections = [dataSource numberOfSectionsInTableView:tableView];
        }
        
        if (dataSource && [dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource tableView:tableView numberOfRowsInSection:section];
            }
        }
    }
    // UICollectionView
    else if ([self isKindOfClass:[UICollectionView class]]) {
        
        UICollectionView *collectionView = (UICollectionView *)self;
        id<UICollectionViewDataSource> dataSource = collectionView.dataSource;
        
        NSInteger sections = 1;
        
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
            sections = [dataSource numberOfSectionsInCollectionView:collectionView];
        }
        
        if (dataSource && [dataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource collectionView:collectionView numberOfItemsInSection:section];
            }
        }
    }
    return items;
}

#pragma mark - Data Source Getters

- (NSAttributedString *)s_titleLabelString
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_titleForEmptyDataSet:)]) {
        NSAttributedString *string = [self.s_emptyDataSetSource s_titleForEmptyDataSet:self];
        if (string) {
            NSAssert([string isKindOfClass:[NSAttributedString class]], @"你必须返回一个 NSAttributedString 类型对象 -- s_titleForEmptyDataSet:");
        }
        return string;
    }
    return nil;
}

- (NSAttributedString *)s_detailLabelString
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_descriptionForEmptyDataSet:)]) {
        NSAttributedString *string = [self.s_emptyDataSetSource s_descriptionForEmptyDataSet:self];
        if (string) {
            NSAssert([string isKindOfClass:[NSAttributedString class]], @"你必须返回一个 NSAttributedString 类型对象 -- s_descriptionForEmptyDataSet:");
        }
        return string;
    }
    return nil;
}

- (UIImage *)s_image
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_imageForEmptyDataSet:)]) {
        UIImage *image = [self.s_emptyDataSetSource s_imageForEmptyDataSet:self];
        if (image) {
            NSAssert([image isKindOfClass:[UIImage class]], @"你必须返回一个 NSAttributedString 类型对象 -- s_imageForEmptyDataSet:");
        }
        return image;
    }
    return nil;
}

- (CAAnimation *)s_imageAnimation
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_imageAnimationForEmptyDataSet:)]) {
        CAAnimation *imageAnimation = [self.s_emptyDataSetSource s_imageAnimationForEmptyDataSet:self];
        if (imageAnimation) {
            NSAssert([imageAnimation isKindOfClass:[CAAnimation class]], @"你必须返回一个 CAAnimation 类型对象 -- s_imageAnimationForEmptyDataSet:");
        }
        return imageAnimation;
    }
    return nil;
}

- (UIColor *)s_imageTintColor
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_imageTintColorForEmptyDataSet:)]) {
        UIColor *color = [self.s_emptyDataSetSource s_imageTintColorForEmptyDataSet:self];
        if (color) {
            NSAssert([color isKindOfClass:[UIColor class]], @"你必须返回一个 UIColor 类型对象 -- s_imageTintColorForEmptyDataSet:");
        }
        return color;
    }
    return nil;
}

- (NSAttributedString *)s_buttonTitleForState:(UIControlState)state
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_buttonTitleForEmptyDataSet:forState:)]) {
        NSAttributedString *string = [self.s_emptyDataSetSource s_buttonTitleForEmptyDataSet:self forState:state];
        if (string) {
             NSAssert([string isKindOfClass:[NSAttributedString class]], @"你必须返回一个 NSAttributedString 类型对象 -- s_buttonTitleForEmptyDataSet:forState:");
        }
        return string;
    }
    return nil;
}

- (UIImage *)s_buttonImageForState:(UIControlState)state
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_buttonImageForEmptyDataSet:forState:)]) {
        UIImage *image = [self.s_emptyDataSetSource s_buttonImageForEmptyDataSet:self forState:state];
        if (image) {
            NSAssert([image isKindOfClass:[UIImage class]], @"你必须返回一个 UIImage 类型对象 -- s_buttonImageForEmptyDataSet:forState:");
        }
        return image;
    }
    return nil;
}

- (UIImage *)s_buttonBackgroundImageForState:(UIControlState)state
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_buttonBackgroundImageForEmptyDataSet:forState:)]) {
        UIImage *image = [self.s_emptyDataSetSource s_buttonBackgroundImageForEmptyDataSet:self forState:state];
        if (image) {
            NSAssert([image isKindOfClass:[UIImage class]], @"你必须返回一个 UIImage 类型对象 -- s_buttonBackgroundImageForEmptyDataSet:forState:");
        }
        return image;
    }
    return nil;
}

- (UIColor *)s_dataSetBackgroundColor
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_backgroundColorForEmptyDataSet:)]) {
        UIColor *color = [self.s_emptyDataSetSource s_backgroundColorForEmptyDataSet:self];
        if (color) {
            NSAssert([color isKindOfClass:[UIColor class]], @"你必须返回一个 UIColor 类型对象 -- s_backgroundColorForEmptyDataSet:");
        }
        return color;
    }
    return [UIColor clearColor];
}

- (UIView *)s_customView
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_customViewForEmptyDataSet:)]) {
        UIView *view = [self.s_emptyDataSetSource s_customViewForEmptyDataSet:self];
        if (view) {
            NSAssert([view isKindOfClass:[UIView class]], @"你必须返回一个 UIView 类型对象 -- s_customViewForEmptyDataSet:");
        }
        return view;
    }
    return nil;
}

- (CGFloat)s_verticalOffset
{
    CGFloat offset = 0.0;
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_verticalOffsetForEmptyDataSet:)]) {
        offset = [self.s_emptyDataSetSource s_verticalOffsetForEmptyDataSet:self];
    }
    return offset;
}

- (CGFloat)s_verticalSpace
{
    if (self.s_emptyDataSetSource &&
        [self.s_emptyDataSetSource respondsToSelector:@selector(s_spaceHeightForEmptyDataSet:)]) {
        return [self.s_emptyDataSetSource s_spaceHeightForEmptyDataSet:self];
    }
    return 0.0;
}

#pragma mark - Delegate Getters & Events (Private)

- (BOOL)s_shouldFadeIn
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSetShouldFadeIn:)]) {
        return [self.s_emptyDataSetDelegate s_emptyDataSetShouldFadeIn:self];
    }
    return YES;
}

- (BOOL)s_shouldDisplay
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSetShouldDisplay:)]) {
        return [self.s_emptyDataSetDelegate s_emptyDataSetShouldDisplay:self];
    }
    return YES;
}

- (BOOL)s_shouldBeForcedToDisplay
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSetShouldBeForcedToDisplay:)]) {
        return [self.s_emptyDataSetDelegate s_emptyDataSetShouldBeForcedToDisplay:self];
    }
    return NO;
}

- (BOOL)s_isTouchAllowed
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSetShouldAllowTouch:)]) {
        return [self.s_emptyDataSetDelegate s_emptyDataSetShouldAllowTouch:self];
    }
    return NO;
}

- (BOOL)s_isScrollAllowed
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSetShouldAllowScroll:)]) {
        return [self.s_emptyDataSetDelegate s_emptyDataSetShouldAllowScroll:self];
    }
    return NO;
}

- (BOOL)s_isImageViewAnimateAllowed
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSetShouldAnimateImageView:)]) {
        return [self.s_emptyDataSetDelegate s_emptyDataSetShouldAnimateImageView:self];
    }
    return NO;
}

- (void)s_willAppear
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSetWillAppear:)]) {
        [self.s_emptyDataSetDelegate s_emptyDataSetWillAppear:self];
    }
}

- (void)s_didAppear
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSetDidAppear:)]) {
        [self.s_emptyDataSetDelegate s_emptyDataSetDidAppear:self];
    }
}

- (void)s_willDisappear
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSetWillDisappear:)]) {
        [self.s_emptyDataSetDelegate s_emptyDataSetWillDisappear:self];
    }
}

- (void)s_didDisappear
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSetDidDisappear:)]) {
        [self.s_emptyDataSetDelegate s_emptyDataSetDidDisappear:self];
    }
}

- (void)s_didTapContentView:(id)sender
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSet:didTapView:)]) {
        [self.s_emptyDataSetDelegate s_emptyDataSet:self didTapView:sender];
    }
}

- (void)s_didTapDataButton:(id)sender
{
    if (self.s_emptyDataSetDelegate &&
        [self.s_emptyDataSetDelegate respondsToSelector:@selector(s_emptyDataSet:didTapButton:)]) {
        [self.s_emptyDataSetDelegate s_emptyDataSet:self didTapButton:sender];
    }
}

#pragma mark - Setters (Public)

- (void)setS_emptyDataSetSource:(id<SEmptyDataSetSource>)dataSource
{
    if (!dataSource || ![self s_canDisplay]) {
        [self s_invalidate];
    }
    objc_setAssociatedObject(self, kEmptyDataSetSource, [[SWeakObjectContainer alloc] initWithWeakObject:dataSource], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self s_swizzleIfPossible:@selector(reloadData)];
    
    if ([self isKindOfClass:[UITableView class]]) {
        [self s_swizzleIfPossible:@selector(endUpdates)];
    }
    
}

- (void)setS_emptyDataSetDelegate:(id<SEmptyDataSetDelegate>)delegate
{
    if (!delegate) {
        [self s_invalidate];
    }
    
    objc_setAssociatedObject(self, kEmptyDataSetDelegate, [[SWeakObjectContainer alloc] initWithWeakObject:delegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Setters (Private)

- (void)setEmptyDataSetView:(SEmptyDataSetView *)emptyDataSetView
{
    objc_setAssociatedObject(self, kEmptyDataSetView, emptyDataSetView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Reload APIs (Private)

- (void)s_reloadEmptyDataSet
{
    if (![self s_canDisplay]) {
        return;
    }
    
    if (([self s_shouldDisplay] && [self s_itemsCount] == 0) || [self s_shouldBeForcedToDisplay]) {
        [self s_willAppear];
        
        SEmptyDataSetView *view = self.emptyDataSetView;
        
        if (!view.superview) {
            [self setContentOffset:CGPointZero];
            if (([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]]) &&
                self.subviews.count > 0) {
                if ([self isKindOfClass:[UITableView class]]) {
                    UITableView *tableView = (UITableView *)self;
                    tableView.tableFooterView = [UIView new];
                }
                [self insertSubview:view atIndex:0];
            }
            else {
                [self addSubview:view];
            }
//            [view didMoveToSuperview];
        }
        
        [view prepareForReuse];
        
        UIView *customView = [self s_customView];
        
        if (customView) {
            view.customView = customView;
        }
        else {
            NSAttributedString *titleLabelString = [self s_titleLabelString];
            NSAttributedString *detailLabelString = [self s_detailLabelString];
            
            UIImage *buttonImage = [self s_buttonImageForState:UIControlStateNormal];
            NSAttributedString *buttonTitle = [self s_buttonTitleForState:UIControlStateNormal];
            
            UIImage *image = [self s_image];
            UIColor *imageTintColor = [self s_imageTintColor];
            
            UIImageRenderingMode renderingMode = imageTintColor ? UIImageRenderingModeAlwaysTemplate : UIImageRenderingModeAlwaysOriginal;
            
            view.verticalSpace = [self s_verticalSpace];
            
            if (image) {
                if ([image respondsToSelector:@selector(imageWithRenderingMode:)]) {
                    view.imageView.image = [image imageWithRenderingMode:renderingMode];
                    view.imageView.tintColor = imageTintColor;
                }
                else {
                    view.imageView.image = image;
                }
            }
            
            if (titleLabelString) {
                view.titleLabel.attributedText = titleLabelString;
            }
            
            if (detailLabelString) {
                view.detailLabel.attributedText = detailLabelString;
            }
            
            if (buttonImage) {
                [view.button setImage:buttonImage forState:UIControlStateNormal];
                [view.button setImage:[self s_buttonImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            }
            else if (buttonTitle) {
                [view.button setAttributedTitle:buttonTitle forState:UIControlStateNormal];
                [view.button setAttributedTitle:[self s_buttonTitleForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
                [view.button setBackgroundImage:[self s_buttonBackgroundImageForState:UIControlStateNormal] forState:UIControlStateNormal];
                [view.button setBackgroundImage:[self s_buttonBackgroundImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            }
        }
        
        view.verticalOffset = [self s_verticalOffset];
        
        view.backgroundColor = [self s_dataSetBackgroundColor];
        view.hidden = NO;
        view.clipsToBounds = YES;
        
        view.userInteractionEnabled = [self s_isTouchAllowed];
        
        view.fadeInOnDisplay = [self s_shouldFadeIn];
        
        [view setupConstraints];
        
        [UIView performWithoutAnimation:^{
            [view layoutIfNeeded];
        }];
        
        self.scrollEnabled = [self s_isScrollAllowed];
        
        if ([self s_isImageViewAnimateAllowed]) {
            CAAnimation *animation = [self s_imageAnimation];
            if (animation) {
                [self.emptyDataSetView.imageView.layer addAnimation:animation forKey:kEmptyImageViewAnimationKey];
            }
        }
        else if ([self.emptyDataSetView.imageView.layer animationForKey:kEmptyImageViewAnimationKey]) {
            [self.emptyDataSetView.imageView.layer removeAnimationForKey:kEmptyImageViewAnimationKey];
        }
        
        [self s_didAppear];
    }
    else if (self.s_isEmptyDataSetVisible) {
        [self s_invalidate];
    }
}

- (void)s_invalidate
{
    [self s_willDisappear];
    
    if (self.emptyDataSetView) {
        [self.emptyDataSetView prepareForReuse];
        [self.emptyDataSetView removeFromSuperview];
        
        [self setEmptyDataSetView:nil];
    }
    
    self.scrollEnabled = YES;
    
    [self s_didDisappear];
}

#pragma mark - Method Swizzling

static NSMutableDictionary *_impLookupTable;
static NSString * const SSwizzleInfoPointerKey = @"pointer";
static NSString * const SSwizzleInfoOwnerKey = @"owner";
static NSString * const SSwizzleInfoSelectorKey = @"selector";

void s_original_implementation(id self, SEL _cmd) {
    
    Class baseClass = s_baseClassToSwizzleForTarget(self);
    NSString *key = s_implementationKey(baseClass, _cmd);
    
    NSDictionary *swizzleInfo = [_impLookupTable objectForKey:key];
    NSValue *impValue = [swizzleInfo valueForKey:SSwizzleInfoPointerKey];
    
    IMP impPointer = [impValue pointerValue];
    
    [self s_reloadEmptyDataSet];
    
    if (impPointer) {
        ((void(*)(id, SEL))impPointer)(self, _cmd);
    }
}

NSString *s_implementationKey(Class class, SEL selector) {
    
    if (!class || !selector) {
        return nil;
    }
    NSString *className = NSStringFromClass([class class]);
    NSString *selectorName = NSStringFromSelector(selector);
    return [NSString stringWithFormat:@"%@_%@", className, selectorName];
}

Class s_baseClassToSwizzleForTarget(id target) {
    
    if ([target isKindOfClass:[UITableView class]]) {
        return [UITableView class];
    }
    else if ([target isKindOfClass:[UICollectionView class]]) {
        return [UICollectionView class];
    }
    else if ([target isKindOfClass:[UIScrollView class]]) {
        return [UIScrollView class];
    }
    return nil;
}

- (void)s_swizzleIfPossible:(SEL)selector
{
    if (![self respondsToSelector:selector]) {
        return;
    }
    
    if (!_impLookupTable) {
        _impLookupTable = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    for (NSDictionary *info in [_impLookupTable allValues]) {
        Class class = [info objectForKey:SSwizzleInfoOwnerKey];
        NSString *selectorName = [info objectForKey:SSwizzleInfoSelectorKey];
        
        if ([selectorName isEqualToString:NSStringFromSelector(selector)]) {
            if ([self isKindOfClass:class]) {
                return;
            }
        }
    }
    
    Class baseClass = s_baseClassToSwizzleForTarget(self);
    NSString *key = s_implementationKey(baseClass, selector);
    NSValue *impValue = [[_impLookupTable objectForKey:key] valueForKey:SSwizzleInfoSelectorKey];
    
    if (impValue || !key || !baseClass) {
        return;
    }
    
    Method method = class_getInstanceMethod(baseClass, selector);
    IMP s_newImplementation = method_setImplementation(method, (IMP)s_original_implementation);
    
    NSDictionary *swizzledInfo = @{SSwizzleInfoOwnerKey:baseClass,
                                   SSwizzleInfoSelectorKey:NSStringFromSelector(selector),
                                   SSwizzleInfoPointerKey:[NSValue valueWithPointer:s_newImplementation]
                                   };
    
    [_impLookupTable setObject:swizzledInfo forKey:key];
}

#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.view isEqual:self.emptyDataSetView]) {
        return [self s_isTouchAllowed];
    }
    return [super gestureRecognizerShouldBegin:gestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    UIGestureRecognizer *tapGesture = self.emptyDataSetView.tapGesture;
    
    if ([gestureRecognizer isEqual:tapGesture] || [otherGestureRecognizer isEqual:tapGesture]) {
        return YES;
    }
    
    if ((self.s_emptyDataSetDelegate != (id)self &&
         [self.s_emptyDataSetDelegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)])) {
        return [(id)self.s_emptyDataSetDelegate gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }
    
    return NO;
}

@end

@interface SEmptyDataSetView ()
@end

@implementation SEmptyDataSetView

@synthesize contentView = _contentView;
@synthesize titleLabel = _titleLabel;
@synthesize detailLabel = _detailLabel;
@synthesize imageView = _imageView;
@synthesize button = _button;

#pragma mark - Initialization Methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)didMoveToSuperview
{
    self.frame = self.superview.bounds;
    
    void(^fadeInBlock)(void) = ^ {
        _contentView.alpha = 1.0;
    };
    
    if (self.fadeInOnDisplay) {
        [UIView animateWithDuration:0.25 animations:fadeInBlock completion:NULL];
    }
    else {
        fadeInBlock();
    }
}

#pragma mark - Getters

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.userInteractionEnabled = YES;
        _contentView.alpha = 0;
    }
    return _contentView;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = NO;
        _imageView.accessibilityIdentifier = @"empty set background image";
        
        [_contentView addSubview:_imageView];
    }
    return _imageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.backgroundColor = [UIColor clearColor];
        
        _titleLabel.font = [UIFont systemFontOfSize:27.0];
        _titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
        _titleLabel.accessibilityIdentifier = @"empty set little";
        
        [_contentView addSubview:_titleLabel];
        
    }
    return _titleLabel;
}

- (UILabel *)detailLabel
{
    if (!_detailLabel) {
        _detailLabel = [UILabel new];
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _detailLabel.backgroundColor = [UIColor clearColor];
        
        _detailLabel.font = [UIFont systemFontOfSize:17.0];
        _detailLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        _detailLabel.textAlignment = NSTextAlignmentCenter;
        _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _detailLabel.numberOfLines = 0;
        _detailLabel.accessibilityIdentifier = @"empty set detail label";
        
        [_contentView addSubview:_detailLabel];
    }
    return _detailLabel;
}

- (UIButton *)button
{
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        _button.backgroundColor = [UIColor clearColor];
        _button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _button.accessibilityIdentifier = @"empty set buttom";
        
        [_button addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [_contentView addSubview:_button];
    }
    return _button;
}

- (BOOL)canShowImage
{
    return (_imageView.image && _imageView.superview);
}

- (BOOL)canShowTitle
{
    return (_titleLabel.attributedText.string.length > 0 && _titleLabel.superview);
}

- (BOOL)canShowDetail
{
    return (_detailLabel.attributedText.string.length > 0 && _detailLabel.superview);
}

- (BOOL)canShowButton
{
    if ([_button attributedTitleForState:UIControlStateNormal].string.length > 0 ||
        [_button imageForState:UIControlStateNormal]) {
        return (_button.superview != nil);
    }
    return NO;
}

#pragma mark - Setters

- (void)setCustomView:(UIView *)customView
{
    if (!customView) {
        return;
    }
    if (_customView) {
        [_customView removeFromSuperview];
        _customView = nil;
    }
    _customView = customView;
    _customView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_customView];
}

#pragma mark - Action Methods

- (void)didTapButton:(id)sender
{
    SEL selector = NSSelectorFromString(@"s_didTapDataButton:");
    if ([self.superview respondsToSelector:selector]) {
        [self.superview performSelector:selector withObject:sender afterDelay:0.0f];
    }
}

- (void)removeAllConstraints
{
    [self removeConstraints:self.constraints];
    [_contentView removeConstraints:_contentView.constraints];
}

- (void)prepareForReuse
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _titleLabel = nil;
    _detailLabel = nil;
    _imageView = nil;
    _button = nil;
    _customView = nil;
    
    [self removeAllConstraints];
}

#pragma mark - Auto-Layout Configuration

- (void)setupConstraints
{
    NSLayoutConstraint *centerXConstraint = [self equallyRelatedConstraintWithView:self.contentView attribute:NSLayoutAttributeCenterX];
    NSLayoutConstraint *centerYConstraint = [self equallyRelatedConstraintWithView:self.contentView attribute:NSLayoutAttributeCenterY];
    
    [self addConstraint:centerXConstraint];
    [self addConstraint:centerYConstraint];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:nil views:@{@"contentView":self.contentView}]];
    
    // 垂直方向上的偏移
    if (self.verticalOffset != 0 && self.constraints.count > 0) {
        centerYConstraint.constant = self.verticalOffset;
    }
    
    if (_customView) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[customView]|" options:0 metrics:nil views:@{@"customView":_customView}]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[customView]|" options:0 metrics:nil views:@{@"customView":_customView}]];
    }
    else {
        CGFloat width = CGRectGetWidth(self.frame) ? : CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat padding = roundf(width/16.0);
        CGFloat verticalSpace = self.verticalSpace ? : 11.0; // Default is 11 pts
        
        NSMutableArray *subviewsStrings = [NSMutableArray array];
        NSMutableDictionary *views = [NSMutableDictionary dictionary];
        NSDictionary *metrics = @{@"padding":@(padding)};
        
        //_imageView水平方向的布局
        if (_imageView.superview) {
            [subviewsStrings addObject:@"imageView"];
            views[subviewsStrings.lastObject] = _imageView;
            [self.contentView addConstraint:[self.contentView equallyRelatedConstraintWithView:_imageView attribute:NSLayoutAttributeCenterX]];
        }
        
        //_titleLabel水平方向的布局
        if ([self canShowTitle]) {
            [subviewsStrings addObject:@"titleLabel"];
            views[subviewsStrings.lastObject] = _titleLabel;
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding@750)-[titleLabel(>=0)]-(padding@750)-|" options:0 metrics:metrics views:views]];
        }
        // 否则移除掉_titleLabel
        else {
            [_titleLabel removeFromSuperview];
            _titleLabel = nil;
        }
        
        //_detailLabel水平方向的布局
        if ([self canShowDetail]) {
            [subviewsStrings addObject:@"detailLabel"];
            views[subviewsStrings.lastObject] = _detailLabel;
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding@750)-[detailLabel(>=0)]-(padding@750)-|" options:0 metrics:metrics views:views]];
        }
        // 否则移除掉_detailLabel
        else {
            [_detailLabel removeFromSuperview];
            _detailLabel = nil;
        }
        
        //_detailLabel水平方向的布局
        if ([self canShowButton]) {
            [subviewsStrings addObject:@"button"];
            views[subviewsStrings.lastObject] = _button;
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding@750)-[button(>=0)]-(padding@750)-|" options:0 metrics:metrics views:views]];
        }
        // 否则移除掉_button
        else {
            [_button removeFromSuperview];
            _button = nil;
        }
        
        NSMutableString *verticalFormat = [NSMutableString new];
        for (int i = 0; i < subviewsStrings.count; i++) {
            NSString *string = subviewsStrings[i];
            [verticalFormat appendFormat:@"[%@]", string];
            if (i < subviewsStrings.count - 1) {
                [verticalFormat appendFormat:@"-(%.f@750)-", verticalSpace];
            }
        }
        
        //垂直方向的布局
        if (verticalFormat.length > 0) {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|%@|", verticalFormat] options:0 metrics:metrics views:views]];
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    
    if ([hitView isKindOfClass:[UIControl class]]) {
        return hitView;
    }
    
    if ([hitView isEqual:_contentView] || [hitView isEqual:_customView]) {
        return hitView;
    }
    
    return nil;
}

@end

@implementation UIView (SContraintBasedLayoutExtensions)

- (NSLayoutConstraint *)equallyRelatedConstraintWithView:(UIView *)view
                                               attribute:(NSLayoutAttribute)attribute
{
    return [NSLayoutConstraint constraintWithItem:view
                                        attribute:attribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:self
                                        attribute:attribute
                                       multiplier:1.0
                                         constant:0.0];
}

@end

@implementation SWeakObjectContainer

- (instancetype)initWithWeakObject:(id)object
{
    self = [super init];
    if (self) {
        _weakObject = object;
    }
    return self;
}

@end
