$RESIZE:STRETCH
REM $DYNAMIC
$EXEICON:'vacuuflower_icon.ico'
_TITLE "Vacuuflower"

TYPE rectangle
    AS _FLOAT x, y, w, h
END TYPE
TYPE barrier
    AS rectangle coord
    health AS _FLOAT
END TYPE
TYPE molecule
    name AS STRING
    AS rectangle coord
    AS _FLOAT vx, vy
    AS _FLOAT rotation
    AS _BYTE display
END TYPE
TYPE mouse
    AS rectangle coord
    AS _BYTE left, right, leftrelease, rightrelease
    AS INTEGER scroll
    AS _FLOAT offsetx, offsety
END TYPE

SCREEN _NEWIMAGE(700, 700, 32)

REDIM SHARED mouse AS mouse
REDIM SHARED barrier(0) AS barrier
REDIM SHARED vacuum AS rectangle
moleculecount = 25
REDIM SHARED molecules(moleculecount) AS molecule
REDIM SHARED AS _FLOAT barriersize, containersize, centerx, centery, atomdistance, starttime, levelprogress, prevlp
REDIM SHARED AS INTEGER barriercount, lockmouse, gamestate, leveltreshhold
REDIM SHARED AS _UNSIGNED _INTEGER64 level, score, finalscore, calcium, gold
barriercount = 100
atomdistance = 20
leveltreshhold = 20

REDIM SHARED AS LONG plant, atom_C, atom_O, atom_Ca, atom_Ag, bsprite(6)
loadsprites

REDIM SHARED AS LONG font_normal, font_big
loadfonts

RANDOMIZE TIMER

setglobals -1
DO
    checkkeys
    COLOR col&("ui"), col&("black")
    CLS
    setscore
    checkmouse
    displaybarrier
    checkmolecules
    displaymolecules
    displaysprite plant&, centerx, centery, 3, -1
    displayui
    _DISPLAY
    _LIMIT 60
LOOP

SUB loadfonts
    fontpath$ = "data\fonts\"
    fontr$ = fontpath$ + "PTMono-Regular.ttf"
    fonteb$ = fontpath$ + "OpenSans-ExtraBold.ttf"
    font_normal = _LOADFONT(fontr$, 16, "MONOSPACE")
    font_big = _LOADFONT(fonteb$, 48)
    _FONT font_normal
END SUB

SUB checkkeys
    keyhit = _KEYHIT
    SELECT CASE keyhit
        CASE 82
            setglobals -1
        CASE 16128
            setglobals -1
        CASE 27
            SYSTEM
    END SELECT
END SUB

SUB setglobals (resetstate AS _BYTE)
    containersize = _HEIGHT(0) / 4
    barriersize = containersize / (barriercount / 4) * 4
    centerx = _WIDTH(0) / 2
    centery = _HEIGHT(0) / 2
    vacuum.x = centerx - (containersize / 2)
    vacuum.y = centery - (containersize / 2)
    vacuum.w = containersize
    vacuum.h = containersize
    IF resetstate THEN
        gamestate = 1
        finalscore = 0
        score = 0
        level = 0
        prevlp = 0
        restorebarrier
        resetmolecules
        starttime = TIMER
    END IF
END SUB

SUB setscore
    score = (TIMER - starttime)
END SUB

SUB checkmouse
    mouse.scroll = 0
    startx = mouse.coord.x
    starty = mouse.coord.y
    DO
        mouse.coord.x = _MOUSEX
        mouse.coord.y = _MOUSEY
        mouse.scroll = mouse.scroll + _MOUSEWHEEL
        mouse.left = _MOUSEBUTTON(1)
        IF NOT mouse.left THEN
            lockmouse = 0
        END IF
        mouse.offsetx = mouse.coord.x - startx
        mouse.offsety = mouse.coord.y - starty
        mouse.right = _MOUSEBUTTON(2)
    LOOP WHILE _MOUSEINPUT
END SUB

SUB checkresize
    IF _RESIZE THEN
        DO
            winresx = _RESIZEWIDTH
            winresy = _RESIZEHEIGHT
        LOOP WHILE _RESIZE
        IF (winresx <> _WIDTH(0) OR winresy <> _HEIGHT(0)) THEN
            repositionmolecules winresx / _WIDTH(0), winresy / _HEIGHT(0)
            SCREEN _NEWIMAGE(winresx, winresy, 32)
            DO: LOOP UNTIL _SCREENEXISTS
            setglobals 0
        END IF
    END IF
END SUB

SUB displayprogress (x AS _FLOAT, y AS _FLOAT, w AS _FLOAT, h AS _FLOAT, progress AS _FLOAT, orientation AS STRING)
    IF orientation = "v" THEN
        LINE (x, y)-(x + w, y + (h * progress)), col&("ui"), BF
    ELSE
        LINE (x, y)-(x + (w * progress), y + h), col&("ui"), BF
    END IF
END SUB

SUB loadsprites
    spritepath$ = "data\sprites\"
    plant = _LOADIMAGE(spritepath$ + "plant.png")
    atom_C = _LOADIMAGE(spritepath$ + "C.png")
    atom_O = _LOADIMAGE(spritepath$ + "O.png")
    atom_Ca = _LOADIMAGE(spritepath$ + "Ca.png")
    atom_Ag = _LOADIMAGE(spritepath$ + "Ag.png")
    DO: i = i + 1
        bsprite(i) = _LOADIMAGE(spritepath$ + "barrier_" + lst$(i) + ".png")
    LOOP UNTIL i = 6
END SUB

SUB displaysprite (handle AS LONG, x AS _FLOAT, y AS _FLOAT, scale, adjust AS _BYTE)
    IF handle < -1 THEN
        IF adjust THEN
            _PUTIMAGE (x - ((_WIDTH(handle) / 2) * scale), y - ((_HEIGHT(handle) / 2) * scale))-(x + ((_WIDTH(handle) / 2) * scale), y + ((_HEIGHT(handle) / 2) * scale)), handle
        ELSE
            _PUTIMAGE (x, y)-(x + (_WIDTH(handle) * scale), y + (_HEIGHT(handle) * scale)), handle
        END IF
    END IF
END SUB

SUB repositionmolecules (xfactor, yfactor)
    IF UBOUND(molecules) > 0 THEN
        DO: m = m + 1
            molecules(m).coord.x = molecules(m).coord.x * xfactor
            molecules(m).coord.y = molecules(m).coord.y * yfactor
        LOOP UNTIL m = UBOUND(molecules)
    END IF
END SUB

SUB respeedmolecules (xfactor, yfactor)
    IF UBOUND(molecules) > 0 THEN
        DO: m = m + 1
            molecules(m).vx = molecules(m).vx * xfactor
            molecules(m).vy = molecules(m).vy * xfactor
        LOOP UNTIL m = UBOUND(molecules)
    END IF
END SUB

SUB displayui
    COLOR col&("ui"), col&("t")
    _PRINTSTRING (10, 10 + (0 * _FONTHEIGHT(font_normal))), "Score: " + lst$(score) + " / Level: " + lst$(level)
    speed$ = lst$(1.1 ^ level)
    IF INSTR(speed$, ".") THEN length = INSTR(speed$, ".") + 1 ELSE length = LEN(speed$)
    _PRINTSTRING (10, 10 + (1 * _FONTHEIGHT(font_normal))), "Speed: " + MID$(speed$, 1, length)
    displaysprite atom_Ca, 10, 10 + (3 * _FONTHEIGHT(font_normal)), 1.2, 0
    _PRINTSTRING (10 + _WIDTH(atom_Ca) + 10, 10 + (3 * _FONTHEIGHT(font_normal))), lst$(calcium)
    IF gold > 0 THEN
        displaysprite atom_Ag, 8, 8 + (5 * _FONTHEIGHT(font_normal)), 1, 0
        _PRINTSTRING (10 + _WIDTH(atom_Ca) + 10, 10 + (5 * _FONTHEIGHT(font_normal))), lst$(gold)
    END IF

    IF gamestate = 2 THEN
        _FONT font_big
        IF finalscore = 0 THEN finalscore = score + calcium + (10 * gold)
        LINE (vacuum.x, vacuum.y)-(vacuum.x + vacuum.w, vacuum.y + vacuum.h), col&("black"), BF
        COLOR col&("red"), col&("black")
        text$ = "GAMEOVER"
        _PRINTSTRING (vacuum.x + 10, vacuum.y + 10), text$
        text$ = "Score: " + lst$(finalscore)
        _PRINTSTRING (vacuum.x + 10, vacuum.y + 10 + _FONTHEIGHT(font_big)), text$
        _FONT font_normal
    END IF

    progressheight = 4
    levelprogress = (score MOD leveltreshhold) / leveltreshhold
    displayprogress 0, _HEIGHT(0) - progressheight, _WIDTH(0), progressheight, levelprogress, "h"
    IF levelprogress < prevlp THEN level = level + 1: respeedmolecules 1.1, 1.1
    prevlp = levelprogress
END SUB

SUB restorebarrier
    REDIM _PRESERVE barrier(barriercount) AS barrier
    b = 1: DO
        containerhalf = containersize / 2
        gapsize = (5 / 500) * _HEIGHT(0)
        sidecounter = (b - 1) / 4
        barrier(b).coord.x = centerx - containerhalf + (sidecounter * barriersize) + (sidecounter * gapsize)
        barrier(b).coord.y = centery - containerhalf
        barrier(b).coord.w = barriersize
        barrier(b).coord.h = barriersize
        barrier(b).health = 1

        barrier(b + 1).coord.x = centerx + containerhalf
        barrier(b + 1).coord.y = centery - containerhalf + (sidecounter * barriersize) + (sidecounter * gapsize)
        barrier(b + 1).coord.w = barriersize
        barrier(b + 1).coord.h = barriersize
        barrier(b + 1).health = 1

        barrier(b + 2).coord.x = centerx + containerhalf - (sidecounter * barriersize) - (sidecounter * gapsize)
        barrier(b + 2).coord.y = centery + containerhalf
        barrier(b + 2).coord.w = barriersize
        barrier(b + 2).coord.h = barriersize
        barrier(b + 2).health = 1

        barrier(b + 3).coord.x = centerx - containerhalf
        barrier(b + 3).coord.y = centery + containerhalf - (sidecounter * barriersize) - (sidecounter * gapsize)
        barrier(b + 3).coord.w = barriersize
        barrier(b + 3).coord.h = barriersize
        barrier(b + 3).health = 1
        b = b + 4
    LOOP UNTIL b = (UBOUND(barrier) / 4) - 4
    REDIM _PRESERVE barrier(b) AS barrier
END SUB

SUB resetmolecules
    DO: m = m + 1
        molecules(m).display = 0
        resetmolecule m
    LOOP UNTIL m = UBOUND(molecules)
END SUB

SUB checkmolecules
    DO: m = m + 1
        checkmolecule m
    LOOP UNTIL m = UBOUND(molecules)
END SUB

SUB checkmolecule (m AS INTEGER)
    REDIM hitbox AS rectangle
    hitbox.x = molecules(m).coord.x + (molecules(m).coord.w / 2)
    hitbox.y = molecules(m).coord.y + (molecules(m).coord.h / 2)
    hitbox.w = 0
    hitbox.h = 0
    DO: b = b + 1
        IF inbounds(hitbox, barrier(b).coord, 5) AND molecules(m).display THEN
            IF barrier(b).health > 0 AND molecules(m).name = "CO2" THEN
                barrier(b).health = barrier(b).health - 0.1
                molecules(m).display = 0
                resetmolecule m
            END IF
        END IF
    LOOP UNTIL b = UBOUND(barrier)
    IF (molecules(m).vx < 0 AND molecules(m).coord.x < 0) OR (molecules(m).vy < 0 AND molecules(m).coord.y < 0) OR (molecules(m).vx > 0 AND molecules(m).coord.x > _WIDTH(0)) OR (molecules(m).vx > 0 AND molecules(m).coord.x > _HEIGHT(0)) THEN
        molecules(m).display = 0
        resetmolecule m
    END IF
    IF (molecules(m).coord.x = 0 AND molecules(m).coord.y = 0) OR inbounds(molecules(m).coord, vacuum, 0) OR molecules(m).display = 0 THEN
        molecules(m).display = 0
        resetmolecule m
    ELSE
        molecules(m).coord.x = molecules(m).coord.x + molecules(m).vx
        molecules(m).coord.y = molecules(m).coord.y + molecules(m).vy
    END IF
    IF inbounds(mouse.coord, molecules(m).coord, 15 + (3 * LOG(level + 1))) AND mouse.left AND lockmouse = 0 AND molecules(m).name <> "CO2" AND molecules(m).display THEN
        SELECT CASE molecules(m).name
            CASE "Ca"
                calcium = calcium + 1
            CASE "Ag"
                gold = gold + 1
        END SELECT
        molecules(m).display = 0
        resetmolecule m
        lockmouse = -1
    END IF
END SUB

SUB resetmolecule (m AS INTEGER)
    spawn = RND * 100
    IF spawn > 99.65 THEN
        randomposrot = RND * 2 * _PI
        molecules(m).coord.x = centerx + SIN(randomposrot) * max(_WIDTH(0), _HEIGHT(0))
        molecules(m).coord.y = centery + COS(randomposrot) * max(_WIDTH(0), _HEIGHT(0))
        IF m > 1 THEN
            margin = 5
            DO: m2 = m2 + 1
                IF molecules(m).coord.x > molecules(m2).coord.x - margin AND molecules(m).coord.x < molecules(m2).coord.x + margin AND molecules(m).coord.y > molecules(m2).coord.y - margin AND molecules(m).coord.y < molecules(m2).coord.y + margin THEN
                    EXIT SUB
                END IF
            LOOP UNTIL m2 = m - 1
        END IF
        molecules(m).display = -1
        molecules(m).rotation = (RND * _PI) - (_PI / 2)
        randomname = RND * 100
        SELECT CASE randomname
            CASE IS < 0.5
                molecules(m).name = "Ag"
                molecules(m).coord.w = 20
                molecules(m).coord.h = 20
            CASE IS < 72 AND randomname >= 0.5
                molecules(m).name = "CO2"
                molecules(m).coord.w = COS(molecules(m).rotation) * atomdistance * 2
                molecules(m).coord.h = SIN(molecules(m).rotation) * atomdistance * 2
            CASE ELSE
                molecules(m).name = "Ca"
                molecules(m).coord.w = 10
                molecules(m).coord.h = 10
        END SELECT
        molecules(m).vx = -SIN(randomposrot) * (_WIDTH(0) / 500) * 1.1 ^ level
        molecules(m).vy = -COS(randomposrot) * (_HEIGHT(0) / 500) * 1.1 ^ level
    END IF
END SUB

SUB displaymolecules
    DO: m = m + 1
        IF molecules(m).display THEN
            mcorx = molecules(m).coord.x
            mcory = molecules(m).coord.y
            SELECT CASE molecules(m).name
                CASE "CO2"
                    changex = COS(molecules(m).rotation) * atomdistance
                    changey = SIN(molecules(m).rotation) * atomdistance
                    changex2 = COS(molecules(m).rotation + _PI) * atomdistance
                    changey2 = SIN(molecules(m).rotation + _PI) * atomdistance
                    displaysprite atom_C, mcorx, mcory, 2, -1
                    displaysprite atom_O, mcorx + changex, mcory + changey, 2, -1
                    displaysprite atom_O, mcorx + changex2, mcory + changey2, 2, -1
                CASE "Ca"
                    displaysprite atom_Ca, mcorx, mcory, 2, -1
                CASE "Ag"
                    displaysprite atom_Ag, mcorx, mcory, 2, -1
            END SELECT
        END IF
    LOOP UNTIL m = UBOUND(molecules)
END SUB

SUB drawcircle (x AS _FLOAT, y AS _FLOAT, size AS _FLOAT, colour&)
    CIRCLE (x, y), size, colour&
    PAINT (x, y), colour&, colour&
END SUB

SUB displaybarrier
    DO: b = b + 1
        IF barrier(b).coord.x > 0 AND barrier(b).coord.y > 0 THEN
            displaybarrierblock b
        END IF
    LOOP UNTIL b = UBOUND(barrier)
END SUB

SUB displaybarrierblock (b)
    IF barrier(b).health <= 0 THEN
        gamestate = 2 'GAMEOVER
    ELSE
        sprite = INT(1 + ((1 - barrier(b).health) * 5))
        scale = barriersize / _WIDTH(bsprite(sprite))
        displaysprite bsprite(sprite), barrier(b).coord.x, barrier(b).coord.y, scale, -1
        DIM hitbox AS rectangle
        hitbox.x = barrier(b).coord.x - ((_WIDTH(bsprite(sprite)) / 2) * scale)
        hitbox.y = barrier(b).coord.y - ((_HEIGHT(bsprite(sprite)) / 2) * scale)
        hitbox.w = barriersize
        hitbox.h = barriersize
    END IF
    IF inbounds(mouse.coord, hitbox, 2) AND calcium > 0 THEN
        IF mouse.left AND barrier(b).health < 1 AND lockmouse = 0 THEN
            barrier(b).health = 1
            calcium = calcium - 1
            lockmouse = -1
        END IF
        LINE (hitbox.x, hitbox.y)-(hitbox.x + barriersize, hitbox.y + barriersize), col&("highlight"), B
    END IF
END SUB

FUNCTION alphamod& (colour&, alpha AS _FLOAT)
    alphamod& = _RGBA(_RED(colour&), _GREEN(colour&), _BLUE(colour&), alpha)
END FUNCTION

FUNCTION lst$ (number)
    lst$ = LTRIM$(STR$(number))
END FUNCTION

FUNCTION min (a, b)
    IF a < b THEN min = a ELSE min = b
END FUNCTION

FUNCTION max (a, b)
    IF a > b THEN max = a ELSE max = b
END FUNCTION

FUNCTION inbounds (inner AS rectangle, outer AS rectangle, margin AS _FLOAT)
    IF inner.x > outer.x - margin AND inner.x + inner.w < outer.x + outer.w + margin AND inner.y > outer.y - margin AND inner.y + inner.h < outer.y + outer.h + margin THEN inbounds = -1 ELSE inbounds = 0
END FUNCTION

FUNCTION col& (colour$)
    SELECT CASE colour$
        CASE "E"
            col& = _RGBA(100, 100, 100, 255)
        CASE "C"
            col& = _RGBA(127, 127, 127, 255)
        CASE "O"
            col& = _RGBA(0, 166, 255, 255)
        CASE "Ca"
            col& = _RGBA(255, 255, 255, 255)
        CASE "t"
            col& = _RGBA(0, 0, 0, 0)
        CASE "ui"
            col& = _RGBA(255, 255, 255, 255)
        CASE "highlight"
            col& = _RGBA(78, 255, 0, 255)
        CASE "barrier"
            col& = _RGBA(127, 200, 127, 255)
        CASE "red"
            col& = _RGBA(255, 0, 33, 255)
        CASE "black"
            col& = _RGBA(15, 15, 20, 255)
    END SELECT
END FUNCTION
