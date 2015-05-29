from itertools import chain
import re
import collections
import sys
import os.path

class GlobalFnsMeta(type):

    def __call__(cls, fn):
        if callable(fn):
            return fn
        elif isinstance(fn, basestring):
            return getattr(GlobalFns, '_' + fn)



class GlobalFns(object):
    __metaclass__ = GlobalFnsMeta

    @classmethod
    def _union(cls, s1, s2):
        return s1.union(s2)

    @classmethod
    def _with_underscore(cls, key):
        try:
            return key.replace("-", "_")
        except AttributeError:
            return key

    @classmethod
    def _take_other(cls, arg1, arg2):
        return arg2

    @classmethod
    def _or(cls, arg1, arg2):
        return arg1 or arg2

    @classmethod
    def _and(cls, arg1, arg2):
        return arg1 and arg2



def do_get_in(d, ks, **kwargs):
    """Get a nested element from d using a sequence of ks.

    ks: key or sequence of keys
    specify a default argument for safe look-ups"""

    if type(ks) == str:
        ks = ks.split(".")
    elif type(ks) not in (list, tuple):
        ks = (ks, )
    if "default" in kwargs:
        default = kwargs["default"]
        return reduce(lambda d, k: d.get(k, default), chain([d], ks))
    else:
        return reduce(lambda d, k: d[k], chain([d], ks))

def _with_key(d, ks):
    """Do a nested look-up of ks in d."""
    try:
        do_get_in(d, ks)
    except KeyError:
        return False
    else:
        return True

def do_with_key(li, ks):
    """Return those list elements that have keys from ks.

    ks: key or sequence of keys
    for a sequence of keys do a nested look-up"""
    li_type = type(li)
    if li_type in (list, tuple):
        return filter(lambda d: _with_key(d, ks), li)
    elif li_type == dict:
        if _with_key(li, ks):
            return li
        else:
            return {}

def _byval(d, ks, val):
    try:
        ret = do_get_in(d, ks)
    except KeyError:
        return False
    else:
        if val is None:
            return ret is None
        else:
            return ret == val

def do_rejectval(li, ks, val):
    li_type = type(li)
    if li_type in (list, tuple):
        return filter(lambda d: not _byval(d, ks, val), li)
    elif li_type == dict:
        if _byval(li, ks, val):
            return {}
        else:
            return li

def do_has_cmd(li, name):
    return do_byval(do_byval(li, "rc", 0),
                        "item.name", name)

def do_byval(li, ks, val):
    # function has to be chainable
    # thus return same type as li
    li_type = type(li)
    if li_type in (list, tuple):
        return filter(lambda d: _byval(d, ks, val), li)
    elif li_type == dict:
        if _byval(li, ks, val):
            return li
        else:
            return {}

def do_camel(string):
    return re.sub('(^|_+)([a-z])', lambda m: m.group(2).upper(), string)


def do_list_merge(li1, li2=None, attr=None, unique_fn=None):
    """Merge two lists by applying a comparator function to all elements.

    The lists each have to be unique wrt. the comparator function.
    If the output of the comparator function exists in both list, then li2's
    element is chosen, else li1's.
    If no comparator function is given, concat li1 and li2."""

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
        if len(set(comparables_1)) < len(comparables_1):
            raise ValueError("li1 is not unique wrt. unique_fn")

        comparables_2 = [unique_fn(el) for el in li2]
        if len(set(comparables_2)) < len(comparables_2):
            raise ValueError("li2 is not unique wrt. unique_fn")

        for idx2, cmp_2 in enumerate(comparables_2):
            eli2 = li2[idx2]
            if cmp_2 in comparables_1:
                idx1 = comparables_1[cmp_2]
                new_list[idx1] = eli2
            else:
                new_list.append(eli2)

    return new_list


def do_merge(d, other_d=None, mod_fn=None, merge_fn=None):
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


def do_attrs(d, kws, **kwargs):
    """Map keywords onto a dictionary.

    If kws is not iterable, return a list of length 1.
    If kws is iterable, return a list of len(kws).

    If "default" is set as kwarg, use safe lookup with default as fallback."""

    if not isinstance(d, dict):
        raise TypeError("expected dict as first argument, "
                        "got {}".format(type(d)))
    if not isinstance(kws, collections.Iterable):
        kws = (kws, )
    if "default" in kwargs:
        default = kwargs['default']
        ret_val =  map(lambda kw: d.get(kw, default), kws)
    else:
        try:
            ret_val = map(lambda kw: d[kw], kws)
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
    return os.path.join("..", "..", role, dir, file)


def do_reduce(iterable, fn, initial=None):
    if initial:
        return reduce(GlobalFns(fn), iterable, initial)
    else:
        return reduce(GlobalFns(fn), iterable)


def _dict_join(d, k_sep, v_sep):
    res = []
    for k, v in d.iteritems():
        if isinstance(v, dict):
            new_res = map(lambda el: "{}{}{}".format(k, k_sep, el),
                          _dict_join(v, k_sep, v_sep))

            res.extend(new_res)
        else:
            res.append("{}{}{}".format(k, v_sep, v))
    return res


def do_dict_join(d, k_sep=".", v_sep="=", arg_sep=";"):
    return arg_sep.join(_dict_join(d, k_sep, v_sep))


class FilterModule(object):

    def filters(self):
        return {
            'dict_merge': do_merge,
            'list_merge': do_list_merge,
            'attrs': do_attrs,
            'merge_mysql_privs': do_merge_mysql_privs,
            'role': do_role,
            'reduce': do_reduce,
            'dict_join': do_dict_join,
            'get_in': do_get_in,
            'byval': do_byval,
            'rejectval': do_rejectval,
            'has_cmd': do_has_cmd,
            'with_key': do_with_key,
            'camel': do_camel,
        }
