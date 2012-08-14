//
//  DetailTableViewCell.m
//  Beatbox
//
//  Created by Ryan Gerard on 8/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailTableViewCell.h"
#import "ServerRequest.h"

static NSDateFormatter *preDateFormatter = nil;
static NSDateFormatter *postDateFormatter = nil;

@interface DetailTableViewCell ()
@property(strong, nonatomic) UIImageView *userImage;
@property(strong, nonatomic) UILabel *userName;
@property(strong, nonatomic) UITextView *userPost;
@property(strong, nonatomic) UILabel *postDate;

@property(strong, nonatomic) NSTimer *photoTimer;
@property(strong, nonatomic) ServerRequest *photoRequest;
@end

@implementation DetailTableViewCell

@synthesize postData = postData_;
@synthesize userImage, userName, userPost, postDate, photoTimer, photoRequest;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
		self.userImage = [[UIImageView alloc] initWithFrame:CGRectMake(1, 1, 50, 50)];
		[self.contentView addSubview:self.userImage];
		
		self.userName = [[UILabel alloc] initWithFrame:CGRectMake(1, 1, 50, 50)];
		[self.contentView addSubview:self.userName];
		
		self.userPost = [[UITextView alloc] initWithFrame:CGRectMake(1, 1, 50, 50)];
		[self.userPost setEditable:NO];
		[self.userPost setScrollEnabled:NO];
		[self.contentView addSubview:self.userPost];
		
		self.postDate = [[UILabel alloc] initWithFrame:CGRectMake(1, 1, 50, 50)];
		[self.postDate setFont:[UIFont systemFontOfSize:12.0]];
		[self.contentView addSubview:self.postDate];
    }
    return self;
}

- (void)dealloc {
    if(self.photoTimer) {
        [self.photoTimer invalidate];
    }
    self.photoTimer = nil;
    
    if(self.photoRequest) {
        [self.photoRequest cancelRequest];
    }
    self.photoRequest = nil;
}

- (void)setPostData:(NSDictionary *)postData {
	postData_ = postData;

	NSString *created = [postData objectForKey:@"created_at"];
	NSDictionary *user = [postData objectForKey:@"user"];
	NSDictionary *avatar = [user objectForKey:@"avatar_image"];
	NSString *avatarUrl = [avatar objectForKey:@"url"];
	NSString *name = [user objectForKey:@"username"];	
	NSString *text = [postData objectForKey:@"text"];
	
	if(!preDateFormatter) {
		preDateFormatter = [[NSDateFormatter alloc] init];
		[preDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
		[preDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	}
	// Convert the date object to a user-visible date string.
	NSDate *date = [preDateFormatter dateFromString:created];
	
	if(!postDateFormatter) {
		postDateFormatter = [[NSDateFormatter alloc] init];
		[postDateFormatter setDateStyle:NSDateFormatterShortStyle];
		[postDateFormatter setTimeStyle:NSDateFormatterShortStyle];
	}
	[self.postDate setText:[postDateFormatter stringFromDate:date]];
	
	if(name) {
		[self.userName setText:name];
	}
	
	if(text) {
		[self.userPost setText:text];
	}
	
	if(avatarUrl) {
		// Set the default avatar first
		[self.userImage setImage:[UIImage imageNamed:@"default_avatar"]];
        
        // Set a timer to fire in 0.5 seconds -- allows you to scroll a list of people and not have your device constantly pulling down photos
        self.photoTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_timerFired:) userInfo:nil repeats:NO];
	}
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect contentBounds = [self.contentView bounds];
    
    [self.userImage setFrame:CGRectMake(contentBounds.origin.x + 5, contentBounds.origin.y + 5, 50, 50)];
	[self.userName setFrame:CGRectMake(contentBounds.origin.x + 60, contentBounds.origin.y, contentBounds.size.width - 60, 30)];
	[self.userPost setFrame:CGRectMake(contentBounds.origin.x + 55, contentBounds.origin.y + 30, contentBounds.size.width - 55, 50)];
	[self.postDate setFrame:CGRectMake(contentBounds.origin.x + contentBounds.size.width - 100, contentBounds.origin.y, 100, 30)];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)_timerFired:(NSTimer *)timer {
    // Try to pull down the profile photo
	NSDictionary *user = [self.postData objectForKey:@"user"];
	NSDictionary *avatar = [user objectForKey:@"avatar_image"];
	NSString *avatarUrl = [avatar objectForKey:@"url"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:avatarUrl]];
	
    self.photoRequest = [[ServerRequest alloc] init];
    [self.photoRequest createConnection:request usingBlock:^(NSData *responseData, NSError *error){
        if(!responseData || error) {
            NSLog(@"Error!  No response data");
            return;
        }
        
        UIImage *picture = [UIImage imageWithData:responseData];
        
        // Checking for errors
        if(picture) {
            [self.userImage setImage:picture];
            [self setNeedsLayout];
        } else {
            NSLog(@"Error! Picture is nil");			
        }
    }]; 
}


@end