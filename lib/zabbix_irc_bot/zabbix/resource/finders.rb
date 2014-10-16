module ZabbixIrcBot
  module Zabbix
    module Resource
      module Finders
        def find id, *options
          options = options.extract_options!
          options = options.reverse_merge({
                                              :"#{model_name}ids" => id
                                          })
          res = api.send(model_name).get options
          binding.pry if $catch
          if res.size == 0
            nil
          elsif res.size > 1
            raise StandardError, "#{model_name.camelize} ID is not unique"
          else
            self.new res.first
          end
        end

        def get *options
          options = options.extract_options!
          res = api.send(model_name).get options
          res.collect do |obj|
            self.new obj
          end
        end

      end
    end
  end
end
