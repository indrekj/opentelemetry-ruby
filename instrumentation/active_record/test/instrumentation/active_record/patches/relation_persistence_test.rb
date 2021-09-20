# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/relation_persistence'

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::RelationPersistence do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before { exporter.reset }

  describe '.update_all' do
    it 'traces' do
      User.update_all(name: 'new name')

      _(spans.count).must_equal(1)
      _(spans[0].name).must_equal('User.update_all(...)')
    end

    it 'traces scoped calls' do
      User.recently_created.update_all(name: 'new name')

      _(spans.count).must_equal(1)
      _(spans[0].name).must_equal('User.where(...).update_all(...)')
    end
  end

  describe '.delete_all' do
    it 'traces' do
      User.delete_all

      _(spans.count).must_equal(1)
      _(spans[0].name).must_equal('User.delete_all')
    end

    it 'traces scoped calls' do
      User.recently_created.delete_all

      _(spans.count).must_equal(1)
      _(spans[0].name).must_equal('User.where(...).delete_all')
    end
  end
end
