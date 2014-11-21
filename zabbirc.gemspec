Gem::Specification.new do |s|
  s.name        = 'zabbirc'
  s.license     = 'MIT'
  s.version     = '0.0.2'

  s.authors     = ["Filip Zachar"]
  s.email       = 'tulak45@gmail.com'
  s.homepage    = 'http://rubygems.org/gems/zabbirc'
  s.summary     = "IRC Bot for Zabbix monitoring"
  s.description = "IRC Bot for Zabbix monitoring"

  s.files       =  Dir["**/*.rb"]
  s.executables = ["zabbirc", "zabbirc-install"]

  s.add_dependency 'activesupport', '~> 4.1.6', '>= 4.1.6'
  s.add_dependency 'dotenv', '~> 1.0', '>= 1.0.2'
  s.add_dependency 'cinch', '~> 2.1'
  s.add_dependency 'zabbix-client', '~> 0.1', '>= 0.1.0'
  s.add_dependency 'pry', '~> 0.10', '>= 0.10.0'
  s.required_ruby_version = '~> 2.0'
end