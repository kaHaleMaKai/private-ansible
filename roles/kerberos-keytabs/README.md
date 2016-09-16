kerberos-keytabs
================

About
-----
---
Create or remove keytabs for individual users. keytabs are created using a password.

Usage
-----
---
* `principal`: name to be used by kinit
* `password`: active directory/kerberos password
* `used_by`: owner and group that may read the keytab.
  If only one entry or value is given, take it for both owner and group
* `state`: present or absent. *default*: present
* `servers`: list of servers on which keytabs will be created

```python

vars:
# kerberos_keytabs must be specified
  kerberos_keytabs:
    - principal: name-of-principle
      password: your-password-here
      used_by: [owner, group] 
      state: present
      # used_by: owner
      # used_by: [owner]
      servers:
        - first-fqdn
        - ...
    - ...
# keytab_realm must be specified
  - keytab_realm: EXAMPLE.COM
# default values
  - keytab_path: /etc/security/keytabs
  - keytab_file_ending: keytab
  - keytab_mode: '0400'
  - keytab_version: 1
  - keytab_encryption: aes-256-cts

```

