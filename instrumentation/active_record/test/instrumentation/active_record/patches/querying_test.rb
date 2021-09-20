# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'

describe OpenTelemetry::Instrumentation::ActiveRecord do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span_names) { spans.map(&:name) }

  before { exporter.reset }

  it 'adds "order" and "limit" to span name when using "first"' do
    User.first

    # TODO: duplicate spans
    _(span_names).must_equal([
                               'User.order(...).limit(...)',
                               'User.first'
                             ])
  end

  it 'adds "where" to span name' do
    User
      .where(name: 'john')
      .where(counter: 3)
      .to_a

    _(span_names).must_equal(['User.where(...).where(...)'])
  end

  it 'allows reusing relations' do
    relation = User.where(name: 'john')

    # First call
    relation.order(:id).to_a

    # Second call
    relation.where(counter: 3).to_a

    _(span_names).must_equal([
                               'User.where(...).order(...)',
                               'User.where(...).where(...)'
                             ])
  end

  it 'adds "eager_load" to span name' do
    users = 3.times.map { User.create! }
    users.each do |user|
      user.articles.create!(title: 'test article1')
      user.articles.create!(title: 'test article2')
    end
    exporter.reset

    User
      .eager_load(:articles)
      .map { |u| [u.id, u.articles.length] }

    _(span_names).must_equal(['User.eager_load(:articles)'])
  end
end
