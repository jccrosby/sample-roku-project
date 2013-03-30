Sub main()
    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    'display a fake screen while the real one initializes. this screen
    'has to live for the duration of the whole app to prevent flashing
    'back to the roku home screen.
    screenFacade = CreateObject("roPosterScreen")
    screenFacade.show()

    itemHLSLive = {
               ContentType:"episode"
               SDPosterUrl:"file://pkg:/images/sd-poster.jpg"
               HDPosterUrl:"file://pkg:/images/hd-poster.jpg"
               IsHD:True
               HDBranded:False
               Live: true
               Description:"The stunning one-million-gallon exhibit is home to one of the most diverse communities of open-ocean animals to be found in any aquarium."
               ShortDescriptionLine1:"Look into a mysterious, mesmerizing world where life looms large."
               ShortDescriptionLine2:"You'll see giant bluefin tuna power their way through the water, while hammerhead sharks, pelagic rays and giant green sea turtles swim just inches away."
               Rating:"NR"
               StarRating:"100"
               Categories:["live"]
               Title:"Open Sea Cam - v0.0.15"
            }

    showSpringboardScreen(itemHLSLive)

    'exit the app gently so that the screen doesn't flash to black
    screenFacade.showMessage("")
    sleep(25)
End Sub

Sub initTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangPrimaryLogoOffsetSD_X = "72"
    theme.OverhangPrimaryLogoOffsetSD_Y = "11"
    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    theme.OverhangPrimaryLogoSD  = "pkg:/images/Logo_Overhang_SD43.png"

    theme.OverhangSecondaryLogoOffsetSD_X = "970"
    theme.OverhangSecondaryLogoOffsetSD_Y = "11"
    theme.OverhangSecondaryLogoSD  = "pkg:/images/enabledByAdobe.png"

    theme.OverhangPrimaryLogoOffsetHD_X = "123"
    theme.OverhangPrimaryLogoOffsetHD_Y = "17"
    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.OverhangPrimaryLogoHD  = "pkg:/images/Logo_Overhang_HD.png"

    theme.OverhangSecondaryLogoOffsetHD_X = "1080"
    theme.OverhangSecondaryLogoOffsetHD_Y = "11"
    theme.OverhangSecondaryLogoHD  = "pkg:/images/enabledByAdobe.png"

    app.SetTheme(theme)

End Sub

Function showSpringboardScreen(item as object) As Boolean
    port = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")

    'print "showSpringboardScreen"

    screen.SetMessagePort(port)
    screen.AllowUpdates(false)
    if item <> invalid and type(item) = "roAssociativeArray"
        print "Setting item..." + item.HDPosterUrl
        screen.SetContent(item)
    endif

    screen.SetDescriptionStyle("video") 'audio, movie, video, generic
                                        ' generic+episode=4x3,
    screen.ClearButtons()
    screen.AddButton(1,"Play")
    screen.AddButton(2,"Go Back")
    screen.SetStaticRatingEnabled(false)
    screen.AllowUpdates(true)
    screen.Show()

    downKey=3
    selectKey=6
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roSpringboardScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            else if msg.isButtonPressed()
                    print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                    if msg.GetIndex() = 1
                         displayVideo()
                    else if msg.GetIndex() = 2
                         return true
                    endif
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        else
            print "wrong type.... type=";msg.GetType(); " msg: "; msg.GetMessage()
        endif
    end while

    return true
End Function

Function displayVideo()
    print "Displaying video: "
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)

    'bitrates  = [0]          ' 0 = no dots, adaptive bitrate
    'bitrates  = [348]    ' <500 Kbps = 1 dot
    'bitrates  = [664]    ' <800 Kbps = 2 dots
    'bitrates  = [996]    ' <1.1Mbps  = 3 dots
    'bitrates  = [2048]    ' >=1.1Mbps = 4 dots
    bitrates  = [300, 500, 1500]

    'AMS Live pkgr m3u8 streams
    ' 300
    'urls = ["http://dorycdn.alldigital.net/hls-live-clear/_definst_/liveevent/livestream3.m3u8"]
    ' 700
    'urls = ["http://dorycdn.alldigital.net/hls-live-clear/_definst_/liveevent/livestream2.m3u8"]
    '1500
    'urls = ["http://dorycdn.alldigital.net/hls-live-clear/_definst_/liveevent/livestream1.m3u8"]

    'Adaptive
    urls = [
        "http://dorycdn.alldigital.net/hls-live-clear/_definst_/liveevent/livestream3.m3u8",
        "http://dorycdn.alldigital.net/hls-live-clear/_definst_/liveevent/livestream2.m3u8",
        "http://dorycdn.alldigital.net/hls-live-clear/_definst_/liveevent/livestream1.m3u8"
    ]

    qualities = ["SD","HD","HD"]

    streamformat = "hls"
    title = "Open Sea Cam"
    'srt = ""

    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = urls
    videoclip.StreamQualities = qualities
    videoclip.StreamFormat = streamformat
    videoclip.Title = title

    'print "srt = ";srt
    'if srt <> invalid and srt <> "" then
    '    videoclip.SubtitleUrl = srt
    'end if



    video.SetContent(videoclip)
    video.show()

    lastSavedPos   = 0
    statusInterval = 10 'position must change by more than this number of seconds before saving

    while true
        msg = wait(0, video.GetMessagePort())
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event
                print "Closing video screen"
                exit while
            else if msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                if nowpos > 10000

                end if
                if nowpos > 0
                    if abs(nowpos - lastSavedPos) > statusInterval
                        lastSavedPos = nowpos
                    end if
                end if
            else if msg.isRequestFailed()
                print "play failed: "; msg.GetMessage()
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        end if
    end while
End Function