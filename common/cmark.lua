local ffi = require 'ffi'
local C = ffi.C
ffi.cdef[[
typedef enum {
  // Error status
  CMARK_NODE_NONE,

  // Block
  CMARK_NODE_DOCUMENT,
  CMARK_NODE_BLOCK_QUOTE,
  CMARK_NODE_LIST,
  CMARK_NODE_ITEM,
  CMARK_NODE_CODE_BLOCK,
  CMARK_NODE_HTML_BLOCK,
  CMARK_NODE_CUSTOM_BLOCK,
  CMARK_NODE_PARAGRAPH,
  CMARK_NODE_HEADING,
  CMARK_NODE_THEMATIC_BREAK,

  CMARK_NODE_FIRST_BLOCK = CMARK_NODE_DOCUMENT,
  CMARK_NODE_LAST_BLOCK = CMARK_NODE_THEMATIC_BREAK,

  // Inline
  CMARK_NODE_TEXT,
  CMARK_NODE_SOFTBREAK,
  CMARK_NODE_LINEBREAK,
  CMARK_NODE_CODE,
  CMARK_NODE_HTML_INLINE,
  CMARK_NODE_CUSTOM_INLINE,
  CMARK_NODE_EMPH,
  CMARK_NODE_STRONG,
  CMARK_NODE_LINK,
  CMARK_NODE_IMAGE,

  CMARK_NODE_FIRST_INLINE = CMARK_NODE_TEXT,
  CMARK_NODE_LAST_INLINE = CMARK_NODE_IMAGE,
} cmark_node_type;

typedef enum {
  CMARK_NO_LIST,
  CMARK_BULLET_LIST,
  CMARK_ORDERED_LIST
} cmark_list_type;

typedef enum {
  CMARK_NO_DELIM,
  CMARK_PERIOD_DELIM,
  CMARK_PAREN_DELIM
} cmark_delim_type;

typedef enum {
  CMARK_EVENT_NONE,
  CMARK_EVENT_DONE,
  CMARK_EVENT_ENTER,
  CMARK_EVENT_EXIT
} cmark_event_type;

typedef struct cmark_mem {
  void *(*calloc)(size_t, size_t);
  void *(*realloc)(void *, size_t);
  void (*free)(void *);
} cmark_mem;

typedef struct cmark_node cmark_node;
typedef struct cmark_parser cmark_parser;
typedef struct cmark_iter cmark_iter;

// Creating and Destroying Nodes
cmark_node *cmark_node_new(cmark_node_type type);
cmark_node *cmark_node_new_with_mem(cmark_node_type type,
                                    cmark_mem *mem);
void cmark_node_free(cmark_node *node);

// Tree Traversal
cmark_node *cmark_node_next(cmark_node *node);
cmark_node *cmark_node_previous(cmark_node *node);
cmark_node *cmark_node_parent(cmark_node *node);
cmark_node *cmark_node_first_child(cmark_node *node);
cmark_node *cmark_node_last_child(cmark_node *node);

// Iterator
cmark_iter *cmark_iter_new(cmark_node *root);
void cmark_iter_free(cmark_iter *iter);
cmark_event_type cmark_iter_next(cmark_iter *iter);
cmark_node *cmark_iter_get_node(cmark_iter *iter);
cmark_event_type cmark_iter_get_event_type(cmark_iter *iter);
cmark_node *cmark_iter_get_root(cmark_iter *iter);
void cmark_iter_reset(cmark_iter *iter, cmark_node *current,
                      cmark_event_type event_type);

// Accessors
void *cmark_node_get_user_data(cmark_node *node);
int cmark_node_set_user_data(cmark_node *node, void *user_data);
cmark_node_type cmark_node_get_type(cmark_node *node);
const char *cmark_node_get_type_string(cmark_node *node);
const char *cmark_node_get_literal(cmark_node *node);
int cmark_node_set_literal(cmark_node *node, const char *content);
int cmark_node_get_heading_level(cmark_node *node);
int cmark_node_set_heading_level(cmark_node *node, int level);
cmark_list_type cmark_node_get_list_type(cmark_node *node);
int cmark_node_set_list_type(cmark_node *node,
                             cmark_list_type type);
cmark_delim_type cmark_node_get_list_delim(cmark_node *node);
int cmark_node_set_list_delim(cmark_node *node,
                              cmark_delim_type delim);
int cmark_node_get_list_start(cmark_node *node);
int cmark_node_set_list_start(cmark_node *node, int start);
int cmark_node_get_list_tight(cmark_node *node);
int cmark_node_set_list_tight(cmark_node *node, int tight);
const char *cmark_node_get_fence_info(cmark_node *node);
int cmark_node_set_fence_info(cmark_node *node, const char *info);
const char *cmark_node_get_url(cmark_node *node);
int cmark_node_set_url(cmark_node *node, const char *url);
const char *cmark_node_get_title(cmark_node *node);
int cmark_node_set_title(cmark_node *node, const char *title);
const char *cmark_node_get_on_enter(cmark_node *node);
int cmark_node_set_on_enter(cmark_node *node,
                            const char *on_enter);
const char *cmark_node_get_on_exit(cmark_node *node);
int cmark_node_set_on_exit(cmark_node *node, const char *on_exit);
int cmark_node_get_start_line(cmark_node *node);
int cmark_node_get_start_column(cmark_node *node);
int cmark_node_get_end_line(cmark_node *node);
int cmark_node_get_end_column(cmark_node *node);

// Tree Manipulation
void cmark_node_unlink(cmark_node *node);
int cmark_node_insert_before(cmark_node *node,
                             cmark_node *sibling);
int cmark_node_insert_after(cmark_node *node, cmark_node *sibling);
int cmark_node_replace(cmark_node *oldnode, cmark_node *newnode);
int cmark_node_prepend_child(cmark_node *node, cmark_node *child);
int cmark_node_append_child(cmark_node *node, cmark_node *child);
void cmark_consolidate_text_nodes(cmark_node *root);

// Parsing
cmark_parser *cmark_parser_new(int options);
cmark_parser *cmark_parser_new_with_mem(int options, cmark_mem *mem);
void cmark_parser_free(cmark_parser *parser);
void cmark_parser_feed(cmark_parser *parser, const char *buffer, size_t len);
cmark_node *cmark_parser_finish(cmark_parser *parser);
cmark_node *cmark_parse_document(const char *buffer, size_t len, int options);
////////////cmark_node *cmark_parse_file(FILE *f, int options);

// Rendering
char *cmark_render_xml(cmark_node *root, int options);
char *cmark_render_html(cmark_node *root, int options);
char *cmark_render_man(cmark_node *root, int options, int width);
char *cmark_render_commonmark(cmark_node *root, int options, int width);
char *cmark_render_latex(cmark_node *root, int options, int width);
]]

-- stdlib
ffi.cdef[[
void free(void *);
]]


local cmark = {}
local lib = ffi.load('/var/tweak/com.r333d.eqe/lib/libcmark.dylib')
cmark.lib = lib
cmark.ct = {
    node = ffi.typeof('struct cmark_node'),
    const_char_ptr = ffi.typeof('const char *'),
    char_ptr = ffi.typeof('char *'),
}

function cmark.new(s)
    return ffi.gc(lib.cmark_parse_document(s, #s, 0), lib.cmark_node_free)
end

local function test_symbol(symbol)
    -- helper function that errors if the symbol
    -- doesn't exist. always pcall this function
    local test = lib[symbol]
end

local cmark_mt = {
    __index = function(t, k)
        local v
        if string.upper(k) == k then
            v = lib['CMARK_'..k] -- enum
        else
            local symbol = 'cmark_'..k
            if not pcall(test_symbol, symbol) then return nil end
            v = function(...)
                local result = lib[symbol](...)
                local cdata_type = type(result) == 'cdata' and ffi.typeof(result)
                if result == ffi.NULL then
                    return nil
                elseif cdata_type == cmark.ct.const_char_ptr then
                    return ffi.string(result)
                elseif cdata_type == cmark.ct.char_ptr then
                    local s = ffi.string(result)
                    C.free(result)
                    return s
                else
                    return result
                end
            end
        end
        cmark[k] = v
        return v
    end,
}

local node = {}
function node:len()
    local num_children = 0
    local child = self:first_child()
    while child do
        child = child:next()
        num_children = num_children + 1
    end
    return num_children
end

function node:child(idx)
    idx = idx or 1
    if idx < 1 then return nil end

    local child = self:first_child()
    for i=2,idx do
        if not child then break end
        child = child:next()
    end
    return child
end

function node:children()
    local t = {}
    local child = self:first_child()
    while child do
        table.insert(t, child)
        child = child:next()
    end
    return t
end

function node:loopchildren()
    local child = self:first_child()
    return function()
        local r = child
        child = child and child:next()
        return r
    end
end

ffi.metatype(cmark.ct.node, {
    __index = function(t, k)
        return node[k] or cmark['node_'..k]
    end,
    __len = function(t)
        return t:len()
    end,
    __tostring = function(t)
        local addr = string.format('0x%x', tonumber(ffi.cast('uintptr_t', t)))
        local info
        if t:get_type() == cmark.NODE_TEXT then
            info = '"'..t:get_literal()..'"'
        else
            info = t:len()..' children'
        end
        return 'cmark_node ('..t:get_type_string()..', '..info..'): '..addr
    end,
})

return setmetatable(cmark, cmark_mt)
