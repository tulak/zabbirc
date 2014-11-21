Zabbirc
=======

IRC bot for Zabbix monitoring

Installation
------------
Install the gem
```
gem install zabbirc
```
Generate config file
```
zabbirc-install your/config/directory/
```
Start the bot
```
zabbirc config/directory/zabbirc_config.rb
```

Features
--------
Bot runs service, which checks Zabbix for new events, and notifies ops on the channel about them.
Ops are authenticated by matching nickname in IRC to Zabbix user's alias.
Not authenticated IRC users cannot use bot features.
### Op settings
Every bot can set his personal settings:
* `notify` - `true/false` - whether to notify op about events comming from event checking service
* `primary_channel` - can be chosen from channels bot operates on. Specifies channel where bot will notify op about events
* `events_priority` - specifies priority of events that op is interested in. Uses zabbix trigger's priority setting.
  * 0 - (default) not_classified
  * 1 - information
  * 2 - warning
  * 3 - average
  * 4 - high
  * 5 - disaster

### Bot methods
* `!events` - prints last events of whole system
* `!latest host <number-of-events>` - prints last `number-of-events` (default 8) events of specific
* `!status host` - prints status of the host. OK or prints triggers with problem
* `!ack <event-id> <ack-message>` - acknowledges specified event with message



