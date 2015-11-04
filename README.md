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
Every op can set his personal settings:
* `notify` - `true/false` - whether to notify op about events comming from event checking service
* `notify_recoveries` - `true/false` - whether to notify op about event recoveries comming from event checking service
* `primary_channel` - can be chosen from channels bot operates on. Specifies channel where bot will notify op about events
* `events_priority` - specifies priority of events that op is interested in. Uses zabbix trigger's priority setting.
  * 0 - (default) not_classified
  * 1 - information
  * 2 - warning
  * 3 - average
  * 4 - high
  * 5 - disaster

this will turn off notifications off:
```
!settings set notify false
```

## Host Group specific settings
It is also possible to set settings per host group. If an op doesn't want to be notified by by events from hosts in `Staging` an `Development` groups he can set the setting:
```
!settings set notify false hostgroups Staging, Development
```

If you want to set setting in all host groups use `hostgroups-all` literal:
```
!settings set notify true hostgroups-all
```

Every host can be in more host groups. When a bot is deciding whether to notify an op, it is checking if any of the host groups associated to the event's host satisfies the conditions.

### Bot methods
* `!events` - prints last events of whole system
* `!latest host <number-of-events>` - prints last `number-of-events` (default 8) events of specific
* `!status host` - prints status of the host. OK or prints triggers with problem
* `!ack <event-id> <ack-message>` - acknowledges specified event with message


Help
----
You can always ask bot what commans it supports and how to use them
```
!help
!help settings
!help settings set

!help status
!help latest
!help ack
...
```


