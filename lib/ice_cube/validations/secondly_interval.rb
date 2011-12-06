module IceCube

  module Validations::SecondlyInterval

    def interval(interval)
      validations_for(:interval) << Validation.new(interval)
      clobber_base_validations(:sec)
      self
    end

    class Validation

      attr_reader :interval

      def type
        :sec
      end

      def initialize(interval)
        @interval = interval
      end

      def validate(time, schedule)
        seconds = time.to_i - schedule.start_time.to_i
        unless seconds % interval == 0
          interval - (seconds % interval)
        end
      end

    end

  end

end
