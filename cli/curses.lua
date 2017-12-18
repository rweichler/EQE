-- this is basically just a giant header file,

local ffi = require( "ffi" )
local dll = ffi.load( 'curses' )
local shl = bit.lshift

ffi.cdef[[
typedef void* WINDOW;
typedef unsigned chtype;
int endwin();
int beep();
int echo(); int noecho();
int nl();   int nonl();
int raw();  int noraw();
int COLS;   int LINES;
WINDOW* initscr();
WINDOW* stdscr;
int waddch(WINDOW*,const chtype ch);
int wgetch(WINDOW*);
int wmove(WINDOW*,int,int);
int wclear(WINDOW*);
int wrefresh(WINDOW*);
int wattrset(WINDOW*,int);
int wclrtoeol(WINDOW*);
int meta(WINDOW*w,bool);
int intrflush(WINDOW*w,bool);
int keypad(WINDOW*w,bool);
void wtimeout(WINDOW*w,int);

int nodelay(WINDOW *win, bool bf); 

int wprintw(WINDOW*,const char *, ...);

int start_color(void);
int init_pair(short pair, short f, short b);
int init_color(short color, short r, short g, short b);
bool has_colors(void);
bool can_change_color(void);
int color_content(short color, short *r, short *g, short *b);
int pair_content(short pair, short *f, short *b);

int    COLOR_PAIR(int);
int COLORS;
int COLOR_PAIRS;

int    wattroff(WINDOW *, int);
int    wattron(WINDOW *, int);

int getcurx(WINDOW *win);
int getcury(WINDOW *win);

int curs_set(int visibility);
int set_escdelay(int size);
int use_default_colors(void);

int color_content(short color, short *r, short *g, short *b);
int pair_content(short pair, short *f, short *b);
]]

local stdscr = {
   move      =  function(self,x,y) return dll.wmove(     self.window, math.round(y), math.round(x) ) end,
   keypad    =  function(self,a)   return dll.keypad(    self.window, a    ) end,
   meta      =  function(self,a)   return dll.meta(      self.window, a    ) end,
   intrflush =  function(self,a)   return dll.intrflush( self.window, a    ) end,
   addch     =  function(self,c)   return dll.waddch(    self.window, c    ) end,
   getch     =  function(self)     return dll.wgetch(    self.window       ) end,
   clear     =  function(self)     return dll.wclear(    self.window       ) end,
   refresh   =  function(self)     return dll.wrefresh(  self.window       ) end,
   attrset   =  function(self,a)   return dll.wattrset(  self.window, a    ) end,
   clrtoeol  =  function(self)     return dll.wclrtoeol( self.window       ) end,
   timeout   =  function(self,a)          dll.wtimeout(  self.window, a    ) end,
   printw    =  function(self, ...) return dll.wprintw(self.window, ...) end,
   nodelay    =  function(self, a) return dll.nodelay(self.window, a) end,
   attron    =  function(self, ...)
                    return dll.wattron(  self.window, bit.bor(...))
                end,
   attroff   =  function(self, ...)
                    return dll.wattroff(  self.window, bit.bor(...))
                end,
}
setmetatable(stdscr, {
    __index = function(self, k)
        if k == 'x' then
            return dll.getcurx(self.window)
        elseif k == 'y' then
            return dll.getcury(self.window)
        end
    end,
    __newindex = function(self, k, v)
        if k == 'x' then
            self:move(v, self.y)
        elseif k == 'y' then
            self:move(self.x, v)
        else
            rawset(self, k, v)
        end
    end
})

local result = {
   dll          = dll,
   beep         = dll.beep,
   endwin       = dll.endwin,
   initscr      = function() stdscr.window = dll.initscr() end,
   stdscr       = function() return stdscr end,
   cols         = function() return dll.COLS end,
   lines        = function() return dll.LINES end,
   echo         = function(on) if on then dll.echo() else dll.noecho() end end,
   nl           = function(on) if on then dll.nl()   else dll.nonl()   end end,
   raw          = function(on) if on then dll.raw()  else dll.noraw()  end end,

   ERR = -(1),
   OK = 0,
   _SUBWIN = 0x01,
   _ENDLINE = 0x02,
   _FULLWIN = 0x04,
   _SCROLLWIN = 0x08,
   _ISPAD = 0x10,
   _HASMOVED = 0x20,
   _WRAPPED = 0x40,
   _NOCHANGE = -(1),
   _NEWINDEX = -(1),

   COLOR_BLACK = 0,
   COLOR_RED = 1,
   COLOR_GREEN = 2,
   COLOR_YELLOW = 3,
   COLOR_BLUE = 4,
   COLOR_MAGENTA = 5,
   COLOR_CYAN = 6,
   COLOR_WHITE = 7,

   A_NORMAL     = 0,
   A_ATTRIBUTES = 0xFFFFFF00,
   A_CHARTEXT   = shl( 1,  0 + 8) - 1,
   A_COLOR      = shl( shl( 1,  8 ) - 1, 8 ),
   A_STANDOUT   = shl( 1,  8 + 8 ),
   A_UNDERLINE  = shl( 1,  9 + 8 ),
   A_REVERSE    = shl( 1, 10 + 8 ),
   A_BLINK      = shl( 1, 11 + 8 ),
   A_DIM        = shl( 1, 12 + 8 ),
   A_BOLD       = shl( 1, 13 + 8 ),
   A_ALTCHARSET = shl( 1, 14 + 8 ),
   A_INVIS      = shl( 1, 15 + 8 ),
   A_PROTECT    = shl( 1, 16 + 8 ),
   A_HORIZONTAL = shl( 1, 17 + 8 ),
   A_LEFT       = shl( 1, 18 + 8 ),
   A_LOW        = shl( 1, 19 + 8 ),
   A_RIGHT      = shl( 1, 20 + 8 ),
   A_TOP        = shl( 1, 21 + 8 ),
   A_VERTICAL   = shl( 1, 22 + 8 ),

   KEY = {
       ESC = 27,
       CODE_YES = 256,
       MIN = 257,     
       BREAK = 257,   
       DOWN = 258,    
       UP = 259,      
       LEFT = 260,    
       RIGHT = 261,   
       HOME = 262,    
       BACKSPACE = 263,
       F0 = 264,      
       F1 = 265,
       F2 = 266,
       F3 = 267,
       F4 = 268,
       F5 = 269,
       F6 = 270,
       F7 = 271,
       F8 = 272,
       F9 = 273,
       F10 = 274,
       F11 = 275,
       F12 = 276,
       DL = 328,        
       IL = 329,        
       DC = 330,        
       IC = 331,            
       EIC = 332,           
       CLEAR = 333,         
       EOS = 334,           
       EOL = 335,           
       SF = 336,            
       SR = 337,            
       NPAGE = 338,         
       PPAGE = 339,         
       STAB = 340,          
       CTAB = 341,          
       CATAB = 342,         
       ENTER = 343,         
       SRESET = 344,        
       RESET = 345,         
       PRINT = 346,         
       LL = 347,            
       A1 = 348,            
       A3 = 349,            
       B2 = 350,            
       C1 = 351,            
       C3 = 352,            
       BTAB = 353,          
       BEG = 354,           
       CANCEL = 355,        
       CLOSE = 356,         
       COMMAND = 357,       
       COPY = 358,          
       CREATE = 359,        
       END = 360,           
       EXIT = 361,          
       FIND = 362,          
       HELP = 363,          
       MARK = 364,          
       MESSAGE = 365,       
       MOVE = 366,          
       NEXT = 367,          
       OPEN = 368,          
       OPTIONS = 369,       
       PREVIOUS = 370,      
       REDO = 371,          
       REFERENCE = 372,     
       REFRESH = 373,       
       REPLACE = 374,       
       RESTART = 375,       
       RESUME = 376,        
       SAVE = 377,          
       SBEG = 378,          
       SCANCEL = 379,       
       SCOMMAND = 380,      
       SCOPY = 381,         
       SCREATE = 382,       
       SDC = 383,           
       SDL = 384,           
       SELECT = 385,        
       SEND = 386,          
       SEOL = 387,          
       SEXIT = 388,         
       SFIND = 389,         
       SHELP = 390,         
       SHOME = 391,         
       SIC = 392,           
       SLEFT = 393,         
       SMESSAGE = 394,      
       SMOVE = 395,         
       SNEXT = 396,         
       SOPTIONS = 397,      
       SPREVIOUS = 398,     
       SPRINT = 399,        
       SREDO = 400,         
       SREPLACE = 401,      
       SRIGHT = 402,        
       SRSUME = 403,        
       SSAVE = 404,         
       SSUSPEND = 405,      
       SUNDO = 406,         
       SUSPEND = 407,       
       UNDO = 408,          
       MOUSE = 409,         
       RESIZE = 410,        
       MAX = 511,           
   },
}

-- ctrl keys
for i=1, 26 do
    local letter = string.char(string.byte('a') + i - 1)
    result.KEY['ctrl-'..letter] = i
end

-- ctrl i is tab so yeah
result.KEY['tab'] = result.KEY['ctrl-i']
result.KEY['ctrl-i'] = nil
-- ctrl j is enter so yeah
result.KEY['enter'] = result.KEY['ctrl-j']
result.KEY['ctrl-j'] = nil

-- key code mapping
result.KEY_CODE = {}
for k, v in pairs(result.KEY) do
    result.KEY_CODE[v] = string.lower(k)
end
result.KEY_CODE[127] = 'backspace'

-- key code to string
function result.convert_key(key)
    for i=32,126 do
        if i == key then
            return string.char(key)
        end
    end
    if key == 127 then
        return 'backspace'
    end
    local name = result.KEY_CODE[key]
    if name then
        return name
    end
    return key
end

return result
