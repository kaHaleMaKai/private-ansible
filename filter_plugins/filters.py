import collections
import sys
import re
import os.path


class GlobalFnsMeta(type):
    """Let a class act as function lookup dictionary.

    When __call__ is passed a callable fn, return fn directly.
    Else if fn is a string, look the function up in the class dict.
    Allow for calling functions by name as string for usage in jinja templates.
    """

    def __call__(cls, callable_or_string):
        if callable(callable_or_string):
            return callable_or_string
        elif isinstance(callable_or_string, basestring):
            try:
                fn = getattr(GlobalFns, '_' + callable_or_string)
            except AttributeError:
                raise AttributeError("no filter named '{}'".format(callable_or_string))
            return fn

class GlobalFns(object):
    """Contain all auxiliary functions for jinja templates.

    The functions can be accessed as
      GlobalFns(callable_or_string)
    Methods should be prefixed with an underscore as a means of visibility.
    The underscore gets removed by the __call__ method, thus
      GlobalFns('my_fn')
    calls function
      GlobalFns._my_fn.
    """

    __metaclass__ = GlobalFnsMeta

    @classmethod
    def _union(cls, s1, s2):
        """Call union on first argument and apply it to the second one."""
        return s1.union(s2)

    @classmethod
    def _merge_lists(cls, li1, li2):
        """Add items from second to first list, but ignore duplicates."""
        if not li1:
            return li2[:]
        elif not li2:
            return li1[:]
        else:
            li = li1[:]
            for el in li2:
                if el not in li:
                    li.append(el)
            return li

    @classmethod
    def _extend(cls, li1, li2):
        """Append first list with second list."""
        return li1 + li2

    @classmethod
    def _with_underscore(cls, key):
        """Replace hyphens with underscores."""
        try:
            return key.replace("-", "_")
        except AttributeError:
            return key

    @classmethod
    def _take_other(cls, arg1, arg2):
        """Ignore the first argument and return the second one."""
        return arg2

    @classmethod
    def _or(cls, arg1, arg2):
        """Calculate boolean or of both arguments."""
        return arg1 or arg2

    @classmethod
    def _and(cls, arg1, arg2):
        """Calculate boolean and of both arguments."""
        return arg1 and arg2


def _naive_unique(li):
    """Make list unique without using list(set(li)) idiom."""
    tmp = []
    for el in li:
        if el not in tmp:
            tmp.append(el)
    return tmp


def _unique(li):
    """Make list unique using list(set(li)) idiom."""
    return list(set(li))


def do_list_merge(li1, li2=None, attr=None, unique_fn=None, set_fn=set):
    """Merge two lists by applying a comparator function to all elements.

    arguments:
    if attr is given, unique_fn is ignored.
    if neither attr nor unique_fn are given, concat both lists.
    attr -- constrain uniqueness on key of a dicionary-like list element.
    unique_fn -- check for uniqueness of entries from both lists.
               in case of duplicates take the element from second list.
               default: concat both lists.
    set_fn -- used for conversion to set-like; use e.g. _naive_unique if
              elements are non-hashable.
              default: set

    >>> do_list_merge([1, 2], [3, 4])
    [1, 2, 3, 4]

    >>> do_list_merge([1, 2], [2, 2])
    [1, 2, 2, 2]

    >>> do_list_merge([1, 2], [2, 3], unique_fn=lambda x: x)
    [1, 2, 3]

    >>> do_list_merge([1, 2], [3, 3], unique_fn=lambda x: x)
    Traceback (most recent call last):
      File "filters.py", line ?, in do_list_merge
        raise ValueError("li2 is not unique wrt. unique_fn")
    ValueError: li2 is not unique wrt. unique_fn

    >>> do_list_merge([1, 2], [2, 2])
    [1, 2, 2, 2]

    >>> do_list_merge([{'a': 1, 'b': 2}], [{'a': 1, 'b': 3}], attr='a')
    [{'a': 1, 'b': 3}]
    """
    if not li1 and not li2:
        return []
    elif li2 and not li1:
        li1, li2 = li2, li1

    new_list = li1[:]

    if li2 is None:
        pass

    elif attr is None and unique_fn is None:
        new_list.extend(li2)

    else:
        if attr is not None:
            if isinstance(attr, basestring):
                def unique_fn(d):
                    return d[attr]

        if unique_fn is not None:
            unique_fn = GlobalFns(unique_fn)

        comparables_1 = {unique_fn(el): idx for idx, el in enumerate(li1)}
        if len(set_fn(comparables_1)) < len(comparables_1):
            raise ValueError("li1 is not unique wrt. unique_fn")

        comparables_2 = [unique_fn(el) for el in li2]
        if len(set_fn(comparables_2)) < len(comparables_2):
            raise ValueError("li2 is not unique wrt. unique_fn")

        for idx2, cmp_2 in enumerate(comparables_2):
            el2 = li2[idx2]
            if cmp_2 in comparables_1:
                idx1 = comparables_1[cmp_2]
                new_list[idx1] = el2
            else:
                new_list.append(el2)

    return new_list


def do_merge(d, other_d=None, mod_fn=None, merge_fn=None):
    """Merge arbitrarily nestes dictionaries.

    arguments:
    d -- dictionary
    other_d -- dictionary
    mod_fn -- modify keys in dictionaries by this function
              default: no modification
    merge_fn -- function or string (passed to GlobalFns)
                new dictionary entry of most deeply nested entries
                becomes merge_fn(entry1, entry2)
    >>> do_merge({'a': 'b', 'c': {'d': 'e'}}, {'A': 'f', 'c': {'g': 'h'}},
    ...          mod_fn=str.upper)
    {'A': 'f', 'C': {'D': 'e', 'G': 'h'}}
    """
    if other_d is None:
        other_d = {}
    if mod_fn:
        mod_fn = GlobalFns(mod_fn)
        new_d = {mod_fn(k): v for k, v in d.iteritems()}
    else:
        new_d = d.copy()

    if not merge_fn:
        merge_fn = 'take_other'

    merge_values = GlobalFns(merge_fn)

    for k, v in other_d.iteritems():
        mod_k = mod_fn(k) if mod_fn else k
        if hasattr(v, 'iteritems') and hasattr(d.get(k), 'iteritems'):
            new_d[mod_k] = do_merge(d[k], v, mod_fn, merge_fn)
        else:
            try:
                old_v = d[k]
            except KeyError:
                new_d[mod_k] = v
            else:
                new_d[mod_k] = merge_values(old_v, v)
    return new_d


def do_attrs(d, *ks, **kwargs):
    """Extract values from dictionary into a list.

    arguments:
    d -- dictionary
    ks -- keyword or list of keywords to be extracted
    kwargs["default"] -- if set, use as fallback value for safe lookups.

    >>> do_attrs({1: 2, 3: 4}, 1)
    [2]

    >>> do_attrs({1: 2, 3: 4}, 1, 3)
    [2, 4]

    >>> do_attrs({1: 2, 3: 4}, [1, 3])
    [2, 4]

    >>> do_attrs({1: 2, 3: 4}, 5)
    Traceback (most recent call last):
      File "filters.py", line ?, in <lambda>
        ret_val = map(lambda kw: d[kw], ks)
    KeyError: '5 not found in [1, 3]'
    """
    if not isinstance(d, dict):
        raise TypeError("expected dict as first argument, "
                        "got {}".format(type(d)))
    if len(ks) == 1 and isinstance(ks[0], collections.Iterable):
        ks = ks[0]
    if "default" in kwargs:
        default = kwargs['default']
        ret_val = map(lambda kw: d.get(kw, default), ks)
    else:
        try:
            ret_val = map(lambda kw: d[kw], ks)
        except KeyError:
            t, v, tb = sys.exc_info()
            msg = "{} not found in {}".format(v, d.keys())
            raise t, msg, tb
    return ret_val


def _split_mysql_priv(pattern, priv_string):
    match = pattern.match(priv_string)
    if match:
        this_schema = match.group('schema')
        this_table = match.group('table')
        this_privs = match.group('privs')
        further_privs = match.group('further_privs')

        privs = {this_schema:
                    {this_table:
                        set(re.split("\s*,\s*", this_privs))}}

        if further_privs:
            d = _split_mysql_priv(pattern, further_privs)
            new_privs = do_merge(privs, d, merge_fn="union")
        else:
            new_privs = privs
            # for schema, tables in d.iteritems():
                # if schema == this_schema:
                    # for table, new_privs in tables.iteritems():
                        # if table == this_table:
                            # privs[this_schema][this_table].update(new_privs)
                        # else:
                            # privs[this_schema][table] = new_privs
                # else:
                    # privs[schema] = tables
    else:
        new_privs = {}

    return new_privs


def do_merge_mysql_privs(li):
    """Return per user a single string of privileges.

    The privileges are condensed as far as possible, e.g.
        tmp.*:SELECT and tmp.*:SELECT,INSERT -> tmp.*:SELECT,INSERT
    Wildcards such as '*' are not expanded, but treated 'as is'.
    """
    pattern = re.compile(r"""
        (/?\s*)                  # ignore initial slash and leading ws

        (?P<schema_btick>`)?     # get initial backtick if present
        (?P<schema>              # extract the schema
            (?(schema_btick)
                [^`]*            # case initial backtick
                |
                [^.]*))          # case no initial backtick
        (?(schema_btick)`)       # match closing backtick

        [.]                      # ignore dot separating schema and table

        (?P<table_btick>`)?      # get initial backtick if present
        (?P<table>               # extract the table
            (?(table_btick)
                [^`]*            # case initial backtick
                |
                [^:]*))          # case no initial backtick
        (?(table_btick)`)        # match closing backtick

        [:]                      # ignore colon separator between table and privs

        (?P<privs>[^/]*)         # extract all privileges

        [\s]*                    # ignore trailing whitespace

        (?P<further_privs>.*$)   # catch further privileges
    """, re.VERBOSE)

    merged_dict = reduce(lambda priv1, priv2: do_merge(priv1, priv2,
                                                       merge_fn="union"),
                         map(lambda el: _split_mysql_priv(pattern, el), li))
    ret_list = []
    for schema, tables in merged_dict.iteritems():
        for table, privs in tables.iteritems():
            ret_list.append("{}.{}:{}".format(schema, table,
                                                  ",".join(str(el) for el in privs)))
    return ret_list


def do_role(role, file="main.yml", dir="tasks"):
    """Return path of file relative to current role directory.

    arguments:
    role -- name of role from which to include a file
    dir -- subdir of role, default: "tasks"
    file -- file to include, default: "main.yml"

    >>> do_role('lvm')
    '../../lvm/tasks/main.yml'

    >>> do_role('mysql', file='install.yml', dir='vars')
    '../../mysql/vars/install.yml'
    """
    return os.path.join("..", "..", role, dir, file)


def do_reduce(iterable, fn, initial=None):
    """Reduce iterable by fn.

    initial value is only passed to reduce if it is not None.
    >>> do_reduce([True, True, False], 'or')
    True

    >>> do_reduce([1, 2, 3, 1, 2, 3], lambda x, y: x.union({y}), initial=set())
    set([1, 2, 3])
    """
    if initial is not None:
        return reduce(GlobalFns(fn), iterable, initial)
    else:
        return reduce(GlobalFns(fn), iterable)


def do_dict_join(d, k_sep=".", v_sep="="):
    """Join entries of a nested dictionary into a string.

    >>> sorted(
    ... do_dict_join({'my': {'key1': 'value1', 'key2': 'value2'}, 'other_key': 'other_value'})
    ... )
    ['my.key1=value1', 'my.key2=value2', 'other_key=other_value']

    arguments:
    d -- dictionary
    k_sep -- separator between keys, default: "."
    v_sep -- separator between values, default: "="
    """
    """Helper function for function do_dict_join"""
    res = []
    for k, v in d.iteritems():
        if isinstance(v, dict):
            new_res = map(lambda el: "{}{}{}".format(k, k_sep, el),
                          do_dict_join(v, k_sep, v_sep))

            res.extend(new_res)
        else:
            res.append("{}{}{}".format(k, v_sep, v))
    return res


def do_get(d, *ks, **kwargs):
    """Get a value from a nested dict.

    arguments:
    d -- dictionary
    *ks -- keys to lookup
    **kwargs -- accepts "default" key for safe lookups

    >>> do_get({1: {2: {3: 4}}}, 1, 2, 3)
    4

    >>> do_get({1: {2: {3: 4}}}, 5)
    Traceback (most recent call last):
      File "filters.py", line ?, in <lambda>
        res = reduce (lambda acc, k: acc[k], ks, d)
    KeyError: 'nested keys (5,) not found in {1: {2: {3: 4}}}'

    >>> do_get({1: {2: {3: 4}}}, 5, default=42)
    42

    >>> do_get({1: {2: {3: 4}}}, 1, 2, 3, 4)
    Traceback (most recent call last):
      File "filters.py", line ?, in <lambda>
        res = reduce (lambda acc, k: acc[k], ks, d)
    KeyError: 'nesting of keys (1, 2, 3, 4) too is too deep for {1: {2: {3: 4}}}'
    """
    try:
        res = reduce (lambda acc, k: acc[k], ks, d)
    except (KeyError, TypeError):
        if "default" in kwargs:
            return kwargs["default"]
        else:
            t, v, tb = sys.exc_info()
            if t == KeyError:
                msg = "nested keys {} not found in {}".format(ks, d)
            else:
                msg = "nesting of keys {} too is too deep for {}".format(ks, d)
            raise KeyError, msg, tb
    else:
        return res


def do_contains(d, *ks):
    """Test if keys are in nested dict.

    arguments:
    d -- dict
    *ks -- keys to lookup

    >>> do_contains({1: {2: {3: 4}}}, 1, 2)
    True

    >>> do_contains({1: {2: {3: 4}}}, 1, 2, 3)
    True

    >>> do_contains({1: {2: {3: 4}}}, None, "hello")
    False
    """
    try:
        _ = do_get(d, *ks)
    except KeyError:
        return False
    else:
        return True


def do_selectattrs(li, *ks, **kwargs):
    """Filter elements that contain the key sequence ks.

    arguments:
    li -- list of dicts
    *ks -- keys to lookup
    **kwargs -- accepts "result" key if checking result of filter is desired

    >>> do_selectattrs([{1: 2}, {3: 4}], 1)
    [{1: 2}]

    >>> do_selectattrs([{1: 2, 11: {12: 13}}, {3: 4, 21: {22: 23}}], 11, 12)
    [{1: 2, 11: {12: 13}}]

    >>> do_selectattrs([{1: 2, 11: {12: 13}}, {3: 4, 21: {22: 23}}], "hello")
    []

    >>> do_selectattrs([{1: 2}, {3: 4}], 1, result=5)
    []

    >>> do_selectattrs([{1: 2}, {3: 4}], 1, result=True)
    []

    >>> do_selectattrs([{1: 2}, {3: 4}], 1, result=2)
    [{1: 2}]
    """
    if 'result' in kwargs:
        cmp_val = kwargs['result']
        default = None if cmp_val is not None else False
        ret = filter(lambda d: do_get(d, *ks, default=default) == cmp_val, li)
    else:
        ret = filter(lambda d: do_contains(d, *ks), li)
    return ret

def do_convert_integer(text, pos=1):
    """Convert the first positive number inside of a string to an integer.

    arguments:
    text -- text to be matched against

    >>> do_convert_integer("hello5world")
    5

    >>> do_convert_integer("a123b4556n789")
    123

    >>> do_convert_integer("a-123b4556n789")
    123

    >>> do_convert_integer("a1b2c3", 2)
    2

    >>> do_convert_integer("a1b", 2)
    Traceback (most recent call last):
        File "filters.py", line ?, in do_convert_integer
        raise IndexError("could not find 2 numbers in string 'a1b'")
    IndexError: could not find 2 numbers in string 'a1b'

    >>> do_convert_integer("a1b2c3", "hello")
    Traceback (most recent call last):
      File "filters.py", line ?, in do_convert_integer
      raise TypeError("expected: position argument is of type int, got: type <type 'str'>")
    TypeError: expected: position argument is of type int, got: type <type 'str'>

    >>> do_convert_integer("hello, world")
    Traceback (most recent call last):
      File "filters.py", line ?, in do_convert_integer
        raise ValueError("could not find a number in string 'hello, world'")
    ValueError: could not find a number in string 'hello, world'

    >>> do_convert_integer("a1", 0)
    Traceback (most recent call last):
      File "filters.py", line ?, in do_convert_integer
        raise ValueError("expected: pos >= 1, got: pos = 0")
    ValueError: expected: pos >= 1, got: pos = 0
    """
    if not isinstance(text, basestring):
        text = str(text)
    if not isinstance(pos, int):
        raise TypeError("expected: position argument is of type int, got: type {}".format(type(pos)))
    if pos < 1:
        raise ValueError("expected: pos >= 1, got: pos = {}".format(pos))
    match = re.findall("[0-9]+", text)
    if match:
        try:
            number = int(match[pos - 1])
        except IndexError:
            raise IndexError("could not find {} numbers in string '{}'".format(pos, text))
        return number
    else:
        raise ValueError("could not find a number in string '{}'".format(text))

def do_camel(text):
    if type(text) == basestring:
        if not text:
            return text
        return text[0].upper() + text[1:]
    else:
        raise TypeError("camel got wrong type. expected: basestring, got {}".format(type(text)))

class FilterModule(object):
    """Entry point for ansible jinja filters."""

    def filters(self):
        """Return mapping of filter names to global functions.

        Naming convention is taken from ansible:
        'fn_name' maps to do_fn_name.
        """
        return {
            'dict_merge': do_merge,
            'list_merge': do_list_merge,
            'attrs': do_attrs,
            'merge_mysql_privs': do_merge_mysql_privs,
            'role': do_role,
            'reduce': do_reduce,
            'dict_join': do_dict_join,
            'get': do_get,
            'contains': do_contains,
            'selectattrs': do_selectattrs,
            'convert_integer': do_convert_integer,
            'camel': do_camel
        }

if __name__ == "__main__":
    import doctest
    doctest.testmod()
