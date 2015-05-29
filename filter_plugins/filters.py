from itertools import chain

def _get_in(d, ks, **kwargs):
    if type(ks) == str:
        ks = ks.split(".")
    elif type(ks) not in (list, tuple):
        ks = (ks, )
    if "default" in kwargs:
        default = kwargs["default"]
        return reduce(lambda d, k: d.get(k, default), chain([d], ks))
    else:
        return reduce(lambda d, k: d[k], chain([d], ks))

def _key_exists(d, ks):
    try:
        val = _get_in(d, ks)
    except KeyError:
        return False
    else:
        return True

def _byval(d, ks, val):
    try:
        ret = _get_in(d, ks)
    except KeyError:
        return False
    else:
        if val is None:
            return ret is None
        else:
            return ret == val

def _has_cmd(li, name):
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

class FilterModule(object):
    def filters(self):
        return {
            'get_in': _get_in,
            'byval': do_byval,
            'has_cmd': _has_cmd
        }

