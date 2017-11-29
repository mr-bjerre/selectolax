from libc.stdlib cimport free

cdef class Node:
    """A class that represents HTML node (element)."""
    cdef myhtml_tree_node_t *node
    cdef HTMLParser parser

    cdef _init(self, myhtml_tree_node_t *node, HTMLParser parser):
        # custom init, because __cinit__ doesn't accept C types
        self.node = node
        # Keep reference to the selector object, so myhtml structures will not be garbage collected prematurely
        self.parser = parser

    @property
    def attributes(self):
        """Get all attributes that belong to the current node.

        Note that the value of empty attributes is None.

        Returns
        -------
        attributes : dictionary of all attributes.
        """
        cdef myhtml_tree_attr_t *attr = myhtml_node_attribute_first(self.node)
        attributes = dict()

        while attr:
            key = attr.key.data.decode('UTF-8')
            if attr.value.data:
                value = attr.value.data.decode('UTF-8')
            else:
                value = None
            attributes[key] = value

            attr = attr.next

        return attributes

    @property
    def text(self):
        """Returns the text of the node including the text of child nodes.

        Returns
        -------
        text : str

        """
        text = None
        cdef const char*c_text
        cdef myhtml_tree_node_t*child = self.node.child

        while child != NULL:
            if child.tag_id == 1:
                c_text = myhtml_node_text(child, NULL)
                if c_text != NULL:
                    if text is None:
                        text = ""
                    text += c_text.decode('utf-8')

            child = child.child
        return text

    @property
    def tag(self):
        """Return the name of the current tag (e.g. div, p, img).

        Returns
        -------
        text : str
        """
        cdef const char *c_text
        c_text = myhtml_tag_name_by_id(self.node.tree, self.node.tag_id, NULL)
        text = None
        if c_text:
            text = c_text.decode("utf-8")
        return text

    @property
    def child(self):
        """Return the child of current node."""
        cdef Node node
        if self.node.child:
            node = Node()
            node._init(self.node.child, self.parser)
            return node
        return None

    @property
    def parent(self):
        """Return the parent of current node."""
        cdef Node node
        if self.node.parent:
            node = Node()
            node._init(self.node.parent, self.parser)
            return node
        return None

    @property
    def next(self):
        """Return next node."""
        cdef Node node
        if self.node.next:
            node = Node()
            node._init(self.node.next, self.parser)
            return node
        return None

    @property
    def prev(self):
        """Return previous node."""
        cdef Node node
        if self.node.prev:
            node = Node()
            node._init(self.node.prev, self.parser)
            return node
        return None

    @property
    def last_child(self):
        """Return last child node."""
        cdef Node node
        if self.node.last_child:
            node = Node()
            node._init(self.node.last_child, self.parser)
            return node
        return None

    @property
    def html(self):
        """Return html representation of current node including all its child nodes.

        Returns
        -------
        text : str
        """
        cdef mycore_string_raw_t c_str
        c_str.data = NULL
        c_str.length = 0
        c_str.size = 0

        cdef mystatus_t status
        status = myhtml_serialization(self.node, &c_str)

        if status == 0 and c_str.data:
            html = c_str.data.decode('utf-8')
            free(c_str.data)
            return html

        return None

    def css(self, str selector):
        """Perform CSS selector against current node and its child nodes."""
        return HTMLParser(self.html).css(selector)

    def __repr__(self):
        return '<Node %s>' % self.tag
