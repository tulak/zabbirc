module Zabbirc
  module Zabbix
    module Resource
      module Associations
        def has_many name, *options
          options = options.extract_options!.reverse_merge({
            zabbix_attribute: name,
            class_name: name.to_s.singularize.camelize
          })

          extend_key = :"select#{options[:zabbix_attribute].to_s.camelize.pluralize || name.to_s.camelize}"
          define_method name do
            @associations ||= ActiveSupport::HashWithIndifferentAccess.new
            @associations[name] ||= begin
              assoc_class = Zabbix.const_get(options[:class_name])
              hash_data = @attrs[options[:zabbix_attribute]]
              if hash_data.blank?
                this = self.class.find id, extend_key => :extend
                raise StandardError, "zabbix response does not contain #{options[:zabbix_attribute]}" if this[options[:zabbix_attribute]].nil?
                hash_data = this[options[:zabbix_attribute]]
              end

              hash_data.collect do |obj|
                assoc_class.new obj
              end
            end
          end
        end

        def has_one name

        end
      end
    end
  end
end