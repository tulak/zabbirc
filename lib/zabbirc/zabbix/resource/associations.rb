module Zabbirc
  module Zabbix
    module Resource
      module Associations
        def has_many name
          define_method name do
            @associations ||= ActiveSupport::HashWithIndifferentAccess.new
            @associations[name] ||= begin
              assoc_class = Zabbix.const_get(name.to_s.singularize.camelize)
              hash_data = @attrs[name]
              if hash_data.blank?
                this = self.class.find id, :"select#{name.to_s.camelize}" => :extend
                raise StandardError, "zabbix response does not contain #{name}" if this[name].blank?
                hash_data = this[name]
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