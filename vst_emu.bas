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
  combined = b1*65536 + b2*256 + b3
'  print "got :"+b1+":"+b2+":"+b3
'  print "combined is "+combined
  ' bitshift ops?
  ' >> 22
  brightness = combined / 4194304
  ' >> 11
  ypos = (combined / 2048) & 2047
  ' & 2048
  xpos = combined & 2047

'  print "bright: "+brightness+" xp: "+xpos+" yp: "+ypos 

  ' frame end - draw everything out
  if brightness = 0 or new_frame
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
          my_lines_copy[1, 2] = my_lines[csprite, 2] 
          my_lines_copy[1, 3] = my_lines[csprite, 3]
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
  if brightness > 0 and vlist_pos < max_vlist
    ' clamp to (256, 256)
    xpos = xpos / 8
    ypos = ypos / 8
    vector_list[vlist_pos,1] = xpos 
    vector_list[vlist_pos,2] = ypos 
    vector_list[vlist_pos,3] = brightness 
    vlist_pos = vlist_pos + 1
  endif

endwhile

