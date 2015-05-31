from itertools import chain
import re

def do_get_in(d, ks, **kwargs):
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
    try:
        val = do_get_in(d, ks)
    except KeyError:
        return False
    else:
        return True

def do_with_key(li, ks):
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

class FilterModule(object):
    def filters(self):
        return {
            'get_in': do_get_in,
            'byval': do_byval,
            'rejectval': do_rejectval,
            'has_cmd': do_has_cmd,
            'with_key': do_with_key,
            'camel': do_camel
        }

