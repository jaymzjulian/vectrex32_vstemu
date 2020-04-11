' This implements the v.st protocol, which is documented at
' https://trmm.net/V.st - it's a simple serial protocol with:
' 0 bytes are skipped for synchronization
' 3 bytes MSB first, arranged:
' (brightness & 0x3) << 22 | (x & 0x3FF) << 11 | (y & 0x3FF) << 0
'
' brightness levels:
'   0 -> end of frame
'   1 -> end of current vector list
'   2 -> normal
'   3 -> bright

controls = WaitForFrame(JoystickNone, Controller2, JoystickNone)
' anythinmg bigger than this will crash anyhow :)
max_vlist = 1024
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
  combined = b1*65536 + b2*256 + b3
  print "got :"+b1+":"+b2+":"+b3
  print "combined is "+combined
  ' bitshift ops?
  ' >> 22
  brightness = combined / 4194304
  ' >> 11
  ypos = (combined / 2048) & 2047
  ' & 2048
  xpos = combined & 2047

  print "bright: "+brightness+" xp: "+xpos+" yp: "+ypos 

  ' frame end - draw everything out
  if brightness = 0 or new_frame
    if vlist_pos > 1
      ' form a lines sprite
      dim my_lines[vlist_pos - 1, 3]
      for i = 1 to (vlist_pos - 1)
        if brightness = 1
          my_lines[i, 1] = MoveTo
        else
          my_lines[i, 1] = DrawTo
        endif
        my_lines[i, 2] = vector_list[i, 1]
        my_lines[i, 3] = vector_list[i, 2]
      next
      ' start with a MoveTo
      my_lines[1, 1] = MoveTo
      call ReturnToOriginSprite()
      call LinesSprite(my_lines)
      controls = WaitForFrame(JoystickNone, Controller2, JoystickNone)
      call clearscreen()
      vlist_pos = 1
    endif
  endif

  ' lets clamp to max 128 vectors for now...
  if brightness > 0 and vlist_pos < 128
    ' clamp to (256, 256)
    xpos = xpos / 8
    ypos = ypos / 8
    vector_list[vlist_pos,1] = xpos 
    vector_list[vlist_pos,2] = ypos 
    vector_list[vlist_pos,3] = brightness 
    vlist_pos = vlist_pos + 1
  endif

endwhile

