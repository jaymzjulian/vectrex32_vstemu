' This implements the v.st protocol, which is documented at
' https://trmm.net/V.st - it's a simple serial protocol with:
' 0 bytes are skipped for synchronization
' 3 bytes MSB first, arranged:
' (brightness & 0x3) << 22 | (x & 0x3FF) << 11 | (y & 0x3FF) << 0
'
' brightness levels:
'   0 -> end of frame
'   1 -> Move - no pen
'   2 -> normal
'   3 -> bright
'
' Sadly, there are _two_ protocol versions.  Protocol 1 is as above, protocol _2_ is:
'
' (command << 30) | (bright & 0x3f << 24) | (x << 12) | (y << 0)
'
' command:
'   is always 2 for vectormame - have not found doco on what else it can be yet!
'   i suspect there is a command 1 for draw point...
'   command will awlays be 0 for the 1,1,1,1 case, so we just use that for next frame!
'
' for the processing demos:
'
' protocol_version = 1 
'
' for vectormame:
'
' protocol_version = 2
'

protocol_version = 2
display_enabled = true
controls = WaitForFrame(JoystickNone, Controller2, JoystickNone)
' anythinmg bigger than this will crash anyhow :)
max_vlist = 1024
max_sprite = 64
dim vector_list[max_vlist,3]
vlist_pos = 1

while controls[1,3] = 0
  ' this is horribly inefficient
  ' data comes in MSB first, 24 bits
  new_frame = false
  b1 = 0
  while b1 = 0
    b1 = fgetc(Stdin)
    if b1 = 0
      new_frame = true
    endif
  endwhile
  b2 = fgetc(Stdin)
  b3 = fgetc(Stdin)
  if protocol_version = 2
    b4 = fgetc(Stdin)
  else
    b4 = 0
  endif
  if protocol_version = 1
    combined = b1*65536 + b2*256 + b3
    print "got :"+b1+":"+b2+":"+b3
  '  print "combined is "+combined
    ' bitshift ops?
    ' >> 22
    brightness = combined / 4194304
    ' >> 11
    ypos = (combined / 2048) & 2047
    ' & 2048
    xpos = combined & 2047
    ' we don't have commands in v1 protocol!
    command = 2
  else
    combined = b2*65536 + b3*256+b4
    command = (b1 / 64)
    brightness = (b1 & 63)
    ypos = (combined / 4096) & 4095
    xpos = combined & 4095
  endif

  'print "command: "+command+"bright: "+brightness+" xp: "+xpos+" yp: "+ypos 

if display_enabled
  ' frame end - draw everything out
  if (brightness = 0 and protocol_version = 1) or (command = 0 and protocol_version = 2) or new_frame
    print "FRAME with "+vlist_pos+" vectors"
    call clearscreen()
    if vlist_pos > 1
      csprite = 1
      ' form a lines sprite
      dim my_lines[max_sprite, 3]
      for i = 1 to (vlist_pos - 1)
        if vector_list[i, 3] = 1
          my_lines[csprite, 1] = MoveTo
        else
          my_lines[csprite, 1] = DrawTo
        endif
        my_lines[csprite, 2] = vector_list[i, 1]
        my_lines[csprite, 3] = vector_list[i, 2]
        csprite = csprite + 1
        ' do a reset if we hit our origin
        if csprite > max_sprite
          dim my_lines_copy[max_sprite, 3]
          call ReturnToOriginSprite()
          call LinesSprite(my_lines)
'          print "Adding "+my_lines
          my_lines_copy[1, 1] = MoveTo
          my_lines_copy[1, 2] = my_lines[csprite - 1, 2] 
          my_lines_copy[1, 3] = my_lines[csprite - 1, 3]
          my_lines = my_lines_copy
          csprite = 2
        endif
      next

'      print "csprite is "+csprite
      ' copy to new array and place the remainder
      call ReturnToOriginSprite()
      dim worklines[csprite - 1, 3]
      for i = 1 to (csprite - 1)
        worklines[i, 1] = my_lines[i, 1]
        worklines[i, 2] = my_lines[i, 2]
        worklines[i, 3] = my_lines[i, 3]
      next
      call LinesSprite(worklines)
'      print "Adding "+worklines

      controls = WaitForFrame(JoystickNone, Controller2, JoystickNone)
      vlist_pos = 1
    endif
  endif

  ' lets clamp to max 128 vectors for now...
  if ((protocol_version = 1 and brightness > 0) or (protocol_version = 2 and command > 0)) and vlist_pos < max_vlist
    ' clamp to (256, 256)
    if protocol_version = 1
      xpos = xpos / 8
      ypos = ypos / 8
    else
      xpos = xpos / 16
      ypos = ypos / 16
    endif
    xpos = xpos - 128
    ypos = ypos - 128
    vector_list[vlist_pos,1] = xpos 
    vector_list[vlist_pos,2] = ypos 
    vector_list[vlist_pos,3] = brightness 
    vlist_pos = vlist_pos + 1
  endif
endif

endwhile

