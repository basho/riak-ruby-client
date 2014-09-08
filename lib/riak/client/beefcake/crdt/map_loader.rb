module Riak
  class Client
    class BeefcakeProtobuffsBackend
      class CrdtLoader
        class MapLoader
          def initialize(map_value)
            @value = map_value
          end

          def rubyfy
            accum = { 
              counters: {},
              flags: {},
              maps: {},
              registers: {},
              sets: {}
            }

            contents_loop @value, accum
          end

          private

          def rubyfy_inner(accum, map_value)
            destination = accum[:maps][map_value.field.name]
            if destination.nil?
              destination = accum[:maps][map_value.field.name] = {
                counters: {},
                flags: {},
                maps: {},
                registers: {},
                sets: {}
              }
            end
            
            contents_loop map_value.map_value, destination
          end

          def contents_loop(rolling_value, destination)
            return destination if rolling_value.nil?

            rolling_value.each do |inner|
              case inner.field.type
              when MapField::MapFieldType::COUNTER
                destination[:counters][inner.field.name] = inner.counter_value
              when MapField::MapFieldType::FLAG
                destination[:flags][inner.field.name] = inner.flag_value
              when MapField::MapFieldType::MAP
                rubyfy_inner destination, inner
              when MapField::MapFieldType::REGISTER
                destination[:registers][inner.field.name] = inner.register_value
              when MapField::MapFieldType::SET
                destination[:sets][inner.field.name] = ::Set.new inner.set_value
              end
            end

            return destination
          end
        end
      end
    end
  end
end
