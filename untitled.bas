TYPE barrier
    x AS INTEGER
    y AS INTEGER
    health AS _FLOAT
END TYPE

SCREEN _NEWIMAGE(500, 500, 32)

REDIM SHARED barrier(0) AS barrier
REDIM SHARED AS _FLOAT barriersize, containersize, centerx, centery
REDIM SHARED AS INTEGER barriercount
barriercount = 100
containersize = _HEIGHT(0) / 6
barriersize = containersize / (barriercount / 4) * 4
centerx = _WIDTH(0) / 2
centery = _HEIGHT(0) / 2

restorebarrier
displaybarrier

SUB restorebarrier
    REDIM _PRESERVE barrier(barriercount) AS barrier
    b = 1: DO
        containerhalf = containersize / 2
        gapsize = 3.5
        sidecounter = (b - 1) / 4
        barrier(b).x = centerx - containerhalf + (sidecounter * barriersize) + (sidecounter * gapsize)
        barrier(b).y = centery - containerhalf
        barrier(b).health = 1
        barrier(b + 1).x = centerx + containerhalf
        barrier(b + 1).y = centery - containerhalf + (sidecounter * barriersize) + (sidecounter * gapsize)
        barrier(b + 1).health = 1
        barrier(b + 2).x = centerx + containerhalf - (sidecounter * barriersize) - (sidecounter * gapsize)
        barrier(b + 2).y = centery + containerhalf
        barrier(b + 2).health = 1
        barrier(b + 3).x = centerx - containerhalf
        barrier(b + 3).y = centery + containerhalf - (sidecounter * barriersize) - (sidecounter * gapsize)
        barrier(b + 3).health = 1
        b = b + 4
    LOOP UNTIL b = (UBOUND(barrier) / 4) - 4
END SUB

SUB displaybarrier
    DO: b = b + 1
        displaybarrierblock barrier(b).x, barrier(b).y, barrier(b).health
    LOOP UNTIL b = UBOUND(barrier)
END SUB

SUB displaybarrierblock (x AS INTEGER, y AS INTEGER, health AS _FLOAT)
    LINE (x, y)-(x + barriersize, y + barriersize), alphamod&(col&("barrier"), health * 255), BF
END SUB

FUNCTION alphamod& (colour&, alpha AS _FLOAT)
    alphamod& = _RGBA(_RED(colour&), _GREEN(colour&), _BLUE(colour&), alpha)
END FUNCTION

FUNCTION col& (colour$)
    SELECT CASE colour$
        CASE "barrier"
            col& = _RGBA(127, 200, 127, 255)
    END SELECT
END FUNCTION
