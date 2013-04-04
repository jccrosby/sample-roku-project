' ********************************************************************
' ********************************************************************
' **  Roku Custom Video Player Channel (BrightScript)
' **
' **  May 2010
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' ********************************************************************
' ********************************************************************

Sub RunUserInterface()
    o = Setup()
    o.setup()
    o.paint()
    o.eventloop()
End Sub

Sub Setup() As Object
    this = {
        port:      CreateObject("roMessagePort")
        progress:  0 'buffering progress
        position:  0 'playback position (in seconds)
        paused:    false 'is the video currently paused?
        fonts:     CreateObject("roFontRegistry") 'global font registry
        canvas:    CreateObject("roImageCanvas") 'user interface
        player:    CreateObject("roVideoPlayer")
        setup:     SetupFramedCanvas
        paint:     PaintFramedCanvas
        eventloop: EventLoop
        timer:  CreateObject("roTimespan")
    }

    'Static help text:
    this.help = "[ Press up/down to toggle fullscreen ]"

    'Register available fonts:
    this.fonts.Register("pkg:/fonts/LeagueGothic.otf")
    this.textcolor = "#50bfc9d5"

    'Setup image canvas:
    this.canvas.SetMessagePort(this.port)
    this.canvas.SetLayer(0, { Color: "#000000" })
    this.canvas.Show()
    
    device = CreateObject("roDeviceInfo")
    'Resolution-specific settings:
    mode = device.GetDisplayMode()
    size = device.GetDisplaySize()
    
    if mode = "720p" then
        this.layout = {
            full:   this.canvas.GetCanvasRect()
            top:    { x:   0, y:   0, w:1075, h: 150 }
            left:   { x: 100, y: 200, w: 540, h: 303 }
            right:  { x: 700, y: 177, w: 350, h: 291 }
            bottom: { x: 249, y: 650, w: 780, h: 300 }
        }
        this.background = "pkg:/images/back-hd.jpg"
        this.headerfont = this.fonts.get("League Gothic Regular", 50, 50, false)
          print ">> DISPLAY MODE - 720 Executed "
    else 
        this.layout = {
            full:   this.canvas.GetCanvasRect()
            top:    { x:   0, y:   20, w: 640, h:  80 }
            left:   { x: 65, y: 150, w: 360, h: 180 }
            right:  { x: 400, y: 100, w: 220, h: 210 }
            bottom: { x: 100, y: 400, w: 520, h: 140 }
        }
        this.background = "pkg:/images/back-sd.jpg"
        this.headerfont = this.fonts.get("lmroman10 caps", 30, 50, false)
          print ">> DISPLAY MODE - Other Executed "
    end if
    
    print "DISPLAY MODE: " + mode
    
    
   ''print "DISPLAY SIZE: " + size.Lookup("w")

    
    this.player.SetMessagePort(this.port)
    this.player.SetLoop(true)
    this.player.SetPositionNotificationPeriod(1)
    this.player.SetDestinationRect(this.layout.left)
    this.player.SetContentList([{
        Stream: { url: "http://dorycdn.alldigital.net/hls-live-clear/_definst_/liveevent/livestream1.m3u8" }
        StreamFormat: "hls"
        SwitchingStrategy: "full-adaptation"
    }])
    this.player.Play()

    return this
End Sub

Sub EventLoop()
    while true
        msg = wait(0, m.port)
        if msg <> invalid
            'If this is a startup progress status message, record progress
            'and update the UI accordingly:
            if msg.isStatusMessage() and msg.GetMessage() = "startup progress"
                m.paused = false
                progress% = msg.GetIndex() / 10
                if m.progress <> progress%
                    m.progress = progress%
                    m.paint()
                end if

            'Playback progress (in seconds):
            else if msg.isPlaybackPosition()
                m.position = msg.GetIndex()
                m.paint()

            'If the <UP> key is pressed, jump out of this context:
            else if msg.isRemoteKeyPressed()
                index = msg.GetIndex()
                print "Remote button pressed: " + index.tostr()
                 if index = 2 or index = 3 ''<UP> or <DOWN> (toggle fullscreen)
                    if m.paint = PaintFullscreenCanvas
                        m.setup = SetupFramedCanvas
                        m.paint = PaintFramedCanvas
                        rect = m.layout.left
                    else
                        m.setup = SetupFullscreenCanvas
                        m.paint = PaintFullscreenCanvas
                        rect = { x:0, y:0, w:0, h:0 } 'fullscreen
                        m.player.SetDestinationRect(0, 0, 0, 0) 'fullscreen
                    end if
                    m.setup()
                    m.player.SetDestinationRect(rect)
                else if index = 4 or index = 8  '<LEFT> or <REV>
                    m.position = m.position - 60
                    m.player.Seek(m.position * 1000)
                else if index = 5 or index = 9  '<RIGHT> or <FWD>
                    m.position = m.position + 60
                    m.player.Seek(m.position * 1000)
                else if index = 13  '<PAUSE/PLAY>
                    if m.paused m.player.Resume() else m.player.Pause()
                end if

            else if msg.isPaused()
                m.paused = true
                m.paint()

            else if msg.isResumed()
                m.paused = false
                m.paint()

            end if
            'Output events for debug
            print msg.GetType(); ","; msg.GetIndex(); ": "; msg.GetMessage()
            if msg.GetInfo() <> invalid print msg.GetInfo();
        end if
    end while
End Sub

Sub SetupFullscreenCanvas()
    m.canvas.AllowUpdates(false)
    m.paint()
    m.canvas.AllowUpdates(true)
End Sub

Sub PaintFullscreenCanvas()
    list = []

    if m.progress < 100
        color = "#000000" 'opaque black
        list.Push({
            Text: "Loading..." + m.progress.tostr() + "%"
            TextAttrs: { font: "huge" }
            TargetRect: m.layout.full
        })
    else if m.paused
        color = "#80000000" 'semi-transparent black
        list.Push({
            Text: "Paused"
            TextAttrs: { font: "huge" }
            TargetRect: m.layout.full
        })
    else
        color = "#00000000" 'fully transparent
    end if

    m.canvas.SetLayer(0, { Color: color, CompositionMode: "Source" })
    m.canvas.SetLayer(1, list)
End Sub

Sub SetupFramedCanvas()
    m.canvas.AllowUpdates(false)
    m.canvas.Clear()
    m.canvas.SetLayer(0, [
        { 'Background:
            Url: m.background
            CompositionMode: "Source"
        },
        { 'The title:
            Text: "Open Sea Cam"
            TargetRect: m.layout.top
            TextAttrs: { valign: "bottom", halign:"right", font: m.headerfont, color: m.textcolor }
        }',
        '{ 'Help text:
       '     Text: m.help
       '     TargetRect: m.layout.bottom
       '     TextAttrs: { halign: "center", valign: "top", color: m.textcolor }
       ' }
    ])
    m.paint()
    m.canvas.AllowUpdates(true)
    
    
    m.timer.Mark()
    
    
End Sub

Sub PaintFramedCanvas()
    list = []
    if m.progress < 100  'Video is currently buffering
        list.Push({
            Color: "#80000000"
            TargetRect: m.layout.left
        })
        list.Push({
            Text: "Loading..." + m.progress.tostr() + "%"
            TargetRect: m.layout.left
        })
    else  'Video is currently playing
        if m.paused
            list.Push({
                Color: "#80000000"
                TargetRect: m.layout.left
                CompositionMode: "Source"
            })
            list.Push({
                Text: "Paused"
                TargetRect: m.layout.left
            })
        else  'not paused
            list.Push({
                Color: "#00000000"
                TargetRect: m.layout.left
                CompositionMode: "Source"
            })
        end if
       ' list.Push({
        '    Text: m.position.tostr() + " s"
       '     TargetRect: m.layout.left
       '     TextAttrs: { halign: "right", valign: "bottom", color: "#50ffffff",  }
       ' })
    end if
    
    if m.timer.TotalSeconds() < 10
       list.Push({ 'Help text:
            Text: m.help
            TargetRect: m.layout.bottom
            TextAttrs: { halign: "center", valign: "top", color: m.textcolor }
        })
      else
      ' m.timer.delete
        
    end if
    
    m.canvas.SetLayer(1, list)
End Sub
