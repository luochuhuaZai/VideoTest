//
//  VideoViewController.m
//  VideoTest
//
//  Created by lkk on 13-11-25.
//  Copyright (c) 2013年 lkk. All rights reserved.
//

#import "VideoViewController.h"
#import "ASIHTTPRequest.h"
#import "AudioButton.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VideoViewController ()

@end

@implementation VideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //视频播放结束通知
        //添加一个消息推送
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFinished) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Audiobtn是自己写的btn,
    AudioButton *musicBt = [[AudioButton alloc]initWithFrame:CGRectMake(135, 210, 50, 50)];
    [musicBt addTarget:self action:@selector(videoPlay) forControlEvents:UIControlEventTouchUpInside];
    [musicBt setTag:1];
    [self.view addSubview:musicBt];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)videoPlay{
    
    //设定文件下载完了之后的存放路径和临时存放路径
    /*  NSHomeDirectory() 获得根目录路径;
     */
    
    NSString *webPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Private Documents/Temp"];
    NSString *cachePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Private Documents/Cache"];
    
    NSFileManager *fileManager=[NSFileManager defaultManager];
    
    //视频存放的目录是否存在，不存在就创建出来。
    if(![fileManager fileExistsAtPath:cachePath])
    {
        [fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //判断有没有下载过该视频。
    if ([fileManager fileExistsAtPath:[cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"vedioName.mp4"]]])
    {
        MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:[cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"vedioName.mp4"]]]];
        
        //调用这个方法去播放视频
        [self presentMoviePlayerViewControllerAnimated:playerViewController];
        //此时不需要再下载了，所以就直接设nil;
        videoRequest = nil;
    }else{
        //设定视频的下载地址
        ASIHTTPRequest *request=[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"]];

        //拿到前面的view的btn;
        AudioButton *musicBt = (AudioButton *)[self.view viewWithTag:1];
        //如果有延迟，会让btn呈现等待状态.
        [musicBt startSpin];
        
        
        //下载完存储目录
        [request setDownloadDestinationPath:[cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"vedi2.mp4"]]];
        //临时存储目录
        [request setTemporaryFileDownloadPath:[webPath stringByAppendingPathComponent:[NSString stringWithFormat:@"vedi2.mp4"]]];
        
        [request setBytesReceivedBlock:^(unsigned long long size, unsigned long long total) {
            
            //btn不用再进入等待状态了，因为此时进入了播放阶段了
            [musicBt stopSpin];
            
            //用file_length把total放到userDefault里面去;
            //这时userDefault里面的就是视频的总大小
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setDouble:total forKey:@"file_length"];
            
            Recordull += size;//Recordull全局变量，记录已下载的文件的大小
            
            //设置最大缓冲,最多400M
            if (!isPlay&&Recordull > 400000) {
                isPlay = !isPlay; //如果缓冲过了400M,直接开始播放
                [self playVideo];
            }
        }];
        
        //断点续载
        [request setAllowResumeForFileDownloads:YES];
        
        [request startAsynchronous]; //开始请求数据,即开始下载
        videoRequest = request;
    }
}
- (void)playVideo{
    //用的时MPMoviePlayer来播放视频
    MPMoviePlayerViewController *playerViewController =[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL URLWithString:@"http://127.0.0.1:12345/vedi2.mp4"]];
    [self presentMoviePlayerViewControllerAnimated:playerViewController];
}

- (void)videoFinished{
    
    if (videoRequest) {
        isPlay = !isPlay; //停止播放
        
        //ASIHTTPRequest里面的方法,用来删除进程用。
        [videoRequest clearDelegatesAndCancel];
        //设nil,以便ARC去管理内存,自动来回收videoRequesta;
        videoRequest = nil;
    }
}
@end
