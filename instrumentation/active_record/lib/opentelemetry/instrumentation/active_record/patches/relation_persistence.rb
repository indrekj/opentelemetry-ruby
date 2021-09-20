# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Patches
        # Module to prepend to ActiveRecord::Relation for instrumentation
        module RelationPersistence
          def initialize(*)
            super
            @__opentelemetry_span_name__ = model.name
          end

          (::ActiveRecord::Querying::QUERYING_METHODS + [:exec_queries]).each do |query_method|
            define_method(query_method) do |*args|
              start_time = Time.now

              result = super(*args)

              if result.is_a?(::ActiveRecord::Relation)
                result.__opentelemetry_add_to_span_name__!(query_method, *args)
              else
                span_name = __opentelemetry_add_to_span_name__(query_method, *args)
                tracer.in_span(span_name, start_timestamp: start_time) do
                  result
                end
              end

              result
            end
          end

          def __opentelemetry_add_to_span_name__!(query_method, *args)
            @__opentelemetry_span_name__ = __opentelemetry_add_to_span_name__(query_method, *args)
          end

          def __opentelemetry_add_to_span_name__(query_method, *args)
            return @__opentelemetry_span_name__ if query_method == :exec_queries

            suffix = '(...)' if args.count.positive?
            "#{@__opentelemetry_span_name__}.#{query_method}#{suffix}"
          end

          def eager_load(*args)
            if args.first.is_a?(Symbol)
              @__opentelemetry_span_name__ += ".eager_load(:#{args.first})"
            else
              @__opentelemetry_span_name__ << '.eager_load(...)'
            end

            super
          end

          private

          def tracer
            ActiveRecord::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
