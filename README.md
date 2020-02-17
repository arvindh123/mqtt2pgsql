mqtt2pgsql
========

An EMQ X plugin

##### mqtt2pgsql.conf

```properties
mqtt2pgsql.rule.client.connected.1     = {"action": "on_client_connected"}
mqtt2pgsql.rule.client.disconnected.1  = {"action": "on_client_disconnected"}
mqtt2pgsql.rule.client.subscribe.1     = {"action": "on_client_subscribe"}
mqtt2pgsql.rule.client.unsubscribe.1   = {"action": "on_client_unsubscribe"}
mqtt2pgsql.rule.session.subscribed.1   = {"action": "on_session_subscribed"}
mqtt2pgsql.rule.session.unsubscribed.1 = {"action": "on_session_unsubscribed"}
mqtt2pgsql.rule.message.publish.1      = {"action": "on_message_publish"}
mqtt2pgsql.rule.message.delivered.1    = {"action": "on_message_delivered"}
mqtt2pgsql.rule.message.acked.1        = {"action": "on_message_acked"}
```

License
-------

Apache License Version 2.0

Author
------

Contributors
------------

