//
//  UIScrollView+SEmptyDataSet.h
//  TestEmptyData
//
//  Created by liqi on 2018/6/1.
//  Copyright © 2018年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SEmptyDataSetSource;
@protocol SEmptyDataSetDelegate;

@interface UIScrollView (SEmptyDataSet)

@property (nonatomic, weak) IBOutlet id<SEmptyDataSetSource> s_emptyDataSetSource;

@property (nonatomic, weak) IBOutlet id<SEmptyDataSetDelegate> s_emptyDataSetDelegate;

@property (nonatomic, readonly, getter=s_isEmptyDataSetVisible) BOOL s_emptyDataSetVisible;

- (void)s_reloadEmptyDataSet;

@end

@protocol SEmptyDataSetSource <NSObject>
@optional

/**
 设置标题

 @param scrollView 当前滚动视图
 @return 标题
 */
- (NSAttributedString *)s_titleForEmptyDataSet:(UIScrollView *)scrollView;

/**
 设置详情描述

 @param scrollView 当前滚动视图
 @return 详情描述
 */
- (NSAttributedString *)s_descriptionForEmptyDataSet:(UIScrollView *)scrollView;

/**
 设置图片

 @param scrollView 当前滚动视图
 @return 图片
 */
- (UIImage *)s_imageForEmptyDataSet:(UIScrollView *)scrollView;

/**
 设置图片底部颜色

 @param scrollView 当前滚动视图
 @return 图片底部颜色
 */
- (UIColor *)s_imageTintColorForEmptyDataSet:(UIScrollView *)scrollView;

/**
 设置图片动画

 @param scrollView 当前滚动视图
 @return 图片动画
 */
- (CAAnimation *)s_imageAnimationForEmptyDataSet:(UIScrollView *)scrollView;

/**
 设置按钮标题

 @param scrollView 当前滚动视图
 @param state UIControlState
 @return 按钮标题
 */
- (NSAttributedString *)s_buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state;

/**
 设置按钮图片

 @param scrollView 当前滚动视图
 @param state UIControlState
 @return 按钮图片
 */
- (UIImage *)s_buttonImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state;

/**
 设置按钮背景图片

 @param scrollView 当前滚动视图
 @param state UIControlState
 @return 按钮背景图片
 */
- (UIImage *)s_buttonBackgroundImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state;

/**
 设置背景颜色

 @param scrollView 当前滚动视图
 @return 背景颜色
 */
- (UIColor *)s_backgroundColorForEmptyDataSet:(UIScrollView *)scrollView;

/**
 设置自定义视图

 @param scrollView 当前滚动视图
 @return 自定义视图
 */
- (UIView *)s_customViewForEmptyDataSet:(UIScrollView *)scrollView;

/**
 设置整体垂直方向中心的偏移的间距(默认为垂直居中, verticalOffset = 0)

 @param scrollView 当前滚动视图
 @return 垂直方向中心的偏移
 */
- (CGFloat)s_verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView;

/**
 各部件垂直方向的间距(默认 spaceHeight = 11)

 @param scrollView 当前滚动视图
 @return 垂直方向的间距
 */
- (CGFloat)s_spaceHeightForEmptyDataSet:(UIScrollView *)scrollView;

@end

@protocol SEmptyDataSetDelegate <NSObject>
@optional

/**
 添加时是否执行动画

 @param scrollView 当前滚动视图
 @return 是否执行动画
 */
- (BOOL)s_emptyDataSetShouldFadeIn:(UIScrollView *)scrollView;

/**
 emptyView 是否强制显示

 @param scrollView 当前滚动视图
 @return 是否强制显示
 */
- (BOOL)s_emptyDataSetShouldBeForcedToDisplay:(UIScrollView *)scrollView;

/**
 emptyView 是否可以显示

 @param scrollView 当前滚动视图
 @return 是否可以显示
 */
- (BOOL)s_emptyDataSetShouldDisplay:(UIScrollView *)scrollView;

/**
 emptyView 设置 userInteractionEnabled

 @param scrollView 当前滚动视图
 @return userInteractionEnabled
 */
- (BOOL)s_emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView;

/**
 当前滚动视图是否能滚动

 @param scrollView 当前滚动视图
 @return 是否能滚动
 */
- (BOOL)s_emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView;

/**
 图片是否执行动画

 @param scrollView 当前滚动视图
 @return 是否执行动画
 */
- (BOOL)s_emptyDataSetShouldAnimateImageView:(UIScrollView *)scrollView;

/**
 单击emptyView事件

 @param scrollView 当前滚动视图
 @param view 当前点击的emptyView
 */
- (void)s_emptyDataSet:(UIScrollView *)scrollView didTapView:(UIView *)view;

/**
 按钮事件

 @param scrollView 当前滚动视图
 @param button 按钮
 */
- (void)s_emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button;

/**
 将要显示时调用

 @param scrollView 当前滚动视图
 */
- (void)s_emptyDataSetWillAppear:(UIScrollView *)scrollView;

/**
 已经显示时调用

 @param scrollView 当前滚动视图
 */
- (void)s_emptyDataSetDidAppear:(UIScrollView *)scrollView;

/**
 将要消失时调用

 @param scrollView 当前滚动视图
 */
- (void)s_emptyDataSetWillDisappear:(UIScrollView *)scrollView;

/**
 已经消失时调用

 @param scrollView 当前滚动视图
 */
- (void)s_emptyDataSetDidDisappear:(UIScrollView *)scrollView;

@end
