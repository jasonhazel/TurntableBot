# TurntableBot

[Alain Gilbert](https://github.com/alaingilbert) has done a lot of work developing the [Turntable-API](https://github.com/alaingilbert/Turntable-API) and has ported his node.js code [over to Ruby](https://github.com/alaingilbert/Turntable-API/tree/master/ruby_ttapi), which is great.  The problem that I found though is that the Ruby port doesn't feel like Ruby.  I took it upon myself to change this.

This is my first real Ruby project, so don't expect greatness. 

## Installation

[Download the most recent version](https://github.com/mrhazel/TurntableBot/downloads)
Install: `gem install TurnTableBot-VERSION.gem'

## Usage

This library creates a simple DSL that can be used for creating bots quickly.  Here is an example that allows members of the room to tell your bot to 'Awesome' a song.

```ruby
require "turntablebot"
require "yaml"
config = YAML::load(File.open('config.yml'))


TurntableBot.create do
  as_user         config['user']
  authorized_by   config['auth']
  in_room         config['room']

  on :speak do |message|
    if message.text =~ /\/bop/i
      vote :up
    end
  end
end
```

## Pivotal Tracker

I've set up a public [Pivotal Tracker](https://www.pivotaltracker.com/projects/685719) project.  It is integrated with GitHub, so stories will be updated with relevant information.