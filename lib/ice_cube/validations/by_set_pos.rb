require "active_support/core_ext/date/calculations"
require "active_support/core_ext/date_time/calculations"
require "active_support/core_ext/time/calculations"

require "active_support/core_ext/hash/except"

module IceCube

  module Validations::BySetPos

    def by_set_pos(*bysplist)
      bysplist.flatten.each do |set_pos_day|
        unless set_pos_day.is_a?(Integer) && (-366..366).include?(set_pos_day) && set_pos_day != 0
          raise ArgumentError, "expecting Integer value in [-366, -1] or [1, 366] for setposday, got #{set_pos_day} (#{bysplist})"
        end

        validations_for(:by_set_pos) << Validation.new(set_pos_day, self)
      end

      self
    end

    class Validation

      attr_reader :source_rule, :set_pos_day

      def initialize(set_pos_day, source_rule)
        @set_pos_day = set_pos_day
        @source_rule = source_rule
      end

      def type
        :day
      end

      def dst_adjust?
        true
      end

      def validate(step_time, _start_time)
        @step_time = step_time

        if step_time == occurrences_this_period[zero_indexed_position]
          0
        else
          1
        end
      end

      def build_s(builder)
        builder.piece(:by_set_pos) << set_pos_day
      end

      def build_hash(builder)
        builder.validations_array(:by_set_pos) << set_pos_day
      end

      def build_ical(builder)
        builder['BYSETPOS'] << set_pos_day
      end

      private

        attr_reader :step_time

        def zero_indexed_position
          if set_pos_day > 0
            set_pos_day - 1
          else
            set_pos_day
          end
        end

        def occurrences_this_period
          schedule_for_rule.occurrences_between(
            beginning_of_period,
            end_of_period
          )
        end

        def period_type
          case source_rule
          when SecondlyRule
            :second
          when MinutelyRule
            :minute
          when HourlyRule
            :hour
          when DailyRule
            :day
          when WeeklyRule
            :week
          when MonthlyRule
            :month
          when YearlyRule
            :year
          end
        end

        def beginning_of_period
          step_time.public_send("beginning_of_#{period_type}")
        end

        def end_of_period
          step_time.public_send("end_of_#{period_type}")
        end

        def last_period
          step_time.public_send("last_#{period_type}")
        end

        def schedule_for_rule
          IceCube::Schedule.new(last_period) do |s|
            s.add_recurrence_rule Rule.from_hash(rule_hash_for_all_occurrences)
          end
        end

        def rule_hash_for_all_occurrences
          source_rule.to_hash.except(:count, :until).tap do |hash|
            if hash[:validations]
              hash[:validations].delete(:by_set_pos)
            end
          end
        end

    end

  end

end
