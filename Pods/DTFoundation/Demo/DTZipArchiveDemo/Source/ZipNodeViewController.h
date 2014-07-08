//
// ZipNodeViewController.m
// Zippo
//
// Created by Stefan Gugarel on 4/12/13.
// Copyright (c) 2013 Cocoanetics. All rights reserved
//


#import <Foundation/Foundation.h>
#import "DTZipArchiveNode.h"
#import "DTZipArchive.h"
#import <QuickLook/QLPreviewItem.h>



@interface ZipNodeViewController : UITableViewController

@property (nonatomic, strong) DTZipArchiveNode *node;

@property (nonatomic, strong) DTZipArchive *zipArchive;

@end