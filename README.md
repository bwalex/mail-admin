#### dovecot-sql.conf.ext

```
# passdb query to retrieve the password. It can return fields:
#   password - The user's password. This field must be returned.
#   user - user@domain from the database. Needed with case-insensitive lookups.
#   username and domain - An alternative way to represent the "user" field.
#   fail: If set, explicitly fails the passdb lookup. (v2.2.22+)
#   nologin: User isn't actually allowed to log in even if the password matches, with optionally a different reason given as the authentication failure message.
#   allow_nets: Allow user to log in from only specified IPs.
password_query = \
  SELECT \
    mailboxes.password AS password, \
    CONCAT(mailboxes.local_part, '@', domains.fqdn) AS user \
    FROM mailboxes \
    INNER JOIN domains ON mailboxes.domain_id=domains.id \
    WHERE \
    mailboxes.local_part = '%Ln' AND domains.fqdn = '%Ld' AND \
    mailboxes.auth_allowed='1' AND \
    mailboxes.active='1' AND \
    domains.active='1'

# userdb query to retrieve the user information. It can return fields:
#   uid - System UID (overrides mail_uid setting)
#   gid - System GID (overrides mail_gid setting)
#   home - Home directory
#   mail - Mail location (overrides mail_location setting)
user_query = \
  SELECT \
    mailboxes.uid AS uid, \
    domains.gid AS gid, \
    CONCAT(mailboxes.mailbox_format, ':~/mail') AS mail, \
    CONCAT('*:bytes=', mailboxes.quota_limit_bytes) AS quota_rule \
    FROM mailboxes \
    INNER JOIN domains ON mailboxes.domain_id=domains.id \
    WHERE \
    mailboxes.local_part = '%Ln' AND domains.fqdn = '%Ld' AND \
    mailboxes.active='1' AND \
    domains.active='1'

iterate_query = \
  SELECT \
    mailboxes.local_part AS username, \
    domains.fqdn AS domain, \
    FROM mailboxes \
    INNER JOIN domains ON mailboxes.domain_id=domains.id \
    WHERE \
    mailboxes.active='1' AND \
    domains.active='1'
```


#### exim.conf

```
domainlist local_domains = @:localhost:${lookup pgsql { \
  SELECT fqdn \
    FROM domains \
    WHERE \
    fqdn='${quote_pgsql:$domain}' \
  }}

db_aliases:
  driver = redirect
  allow_fail
  allow_defer
  data = ${lookup pgsql { \
    SELECT aliases.destination \
      FROM aliases \
      INNER JOIN domains ON aliases.domain_id=domains.id \
      WHERE \
      aliases.local_part='${quote_pgsql:$local_part}' AND \
      domains.fqdn='${quote_pgsql:$domain}' AND \
      aliases.active='1' AND \
      domains.active='1' \
  }}

db_user:
  driver = accept

  condition = ${lookup pgsql { \
    SELECT CONCAT(mailboxes.local_part,'@',domains.fqdn) AS goto \
      FROM mailboxes \
      INNER JOIN domains ON mailboxes.domain_id=domains.id \
      WHERE \
      mailboxes.local_part='${quote_pgsql:$local_part}' AND \
      domains.fqdn='${quote_pgsql:$domain}' AND \
      mailboxes.active='1' AND \
      domains.active='1' \
  }{yes}{no}}

  transport = ${lookup pgsql { \
    SELECT transports.transport \
      FROM mailboxes \
      INNER JOIN domains ON mailboxes.domain_id=domains.id \
      INNER JOIN transports on mailboxes.transport_id=transports.id \
      WHERE \
      mailboxes.local_part='${quote_pgsql:$local_part}' AND \
      domains.fqdn='${quote_pgsql:$domain}' \
  }}

begin authenticators

PLAIN:
  driver                     = plaintext
  public_name                = PLAIN
  server_set_id              = $auth2
  server_condition           = ${if crypteq{$auth3}{${lookup pgsql{ \
    SELECT mailboxes.password \
      FROM mailboxes \
      INNER JOIN domains ON mailboxes.domain_id=domains.id \
      WHERE \
      CONCAT(mailboxes.local_part,'@',domains.fqdn) = '${quote_pgsql:$auth2}' AND \
      mailboxes.auth_allowed='1' AND \
      mailboxes.active='1' AND \
      domains.active='1' \
  }}}{1}{0}}
  server_advertise_condition = ${if def:tls_in_cipher}
```

#### postfix_transport_maps.cf

```
query = SELECT transports.transport
    FROM mailboxes
    INNER JOIN domains ON mailboxes.domain_id=domains.id
    INNER JOIN transports on mailboxes.transport_id=transports.id
    WHERE
    mailboxes.local_part='%u' AND
    domains.fqdn='%d' AND
    mailboxes.active='1' AND
    domains.active='1'
```

#### postfix_virtual_alias_maps.cf

```
query = SELECT aliases.destination
    FROM aliases
    INNER JOIN domains ON aliases.domain_id=domains.id
    WHERE
    aliases.local_part='%u' AND
    domains.fqdn='%d' AND
    aliases.active='1' AND
    domains.active='1'
```

#### postfix_virtual_mailbox_domains.cf

```
query = SELECT fqdn FROM domains WHERE fqdn='%s'
```

#### postfix_virtual_mailbox_maps.cf

```
query = SELECT CONCAT(mailboxes.local_part,'@',domains.fqdn)
    FROM mailboxes
    INNER JOIN domains ON mailboxes.domain_id=domains.id
    WHERE
    mailboxes.local_part='%u' AND
    domains.fqdn='%d' AND
    mailboxes.active='1' AND
    domains.active='1'
```
