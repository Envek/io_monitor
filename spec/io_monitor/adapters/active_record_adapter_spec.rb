# frozen_string_literal: true

require_relative "../../support/helpers/async_helper"

RSpec.describe IoMonitor::ActiveRecordAdapter do
  include Helpers::AsyncHelper

  let(:aggregator) { IoMonitor.aggregator }

  with_model :Fake, scope: :all do
    table do |t|
      t.string :name
    end

    model {}
  end

  before(:all) do
    (1..10).each { |i| Fake.create!(name: "Fake #{i}") }
  end

  after(:all) do
    Fake.delete_all
  end

  before do
    aggregator.start!
  end

  after do
    aggregator.stop!
  end

  describe "without async queries" do
    context "when aggregator is inactive" do
      before do
        aggregator.stop!
      end

      it "does nothing" do
        expect(aggregator).not_to receive(:increment)

        Fake.all.to_a
      end
    end

    it "increments aggregator by query result's bytesize" do
      allow(aggregator).to receive(:increment)

      bytesize = Fake.pluck(:id, :name).flatten.join.bytesize

      expect(aggregator).to have_received(:increment).with(described_class.kind, bytesize)
    end
  end

  if Rails::VERSION::MAJOR >= 7
    context "when load_async is used" do
      let!(:bytesize) { Fake.pluck(:id, :name).flatten.join.bytesize }

      it "increments aggregator by query result's bytesize", skip_transaction: true do
        allow(aggregator).to receive(:increment)

        relation = Fake.all.load_async
        wait_for_async_query(relation)
        relation.to_a

        expect(aggregator).to have_received(:increment).with(described_class.kind, bytesize)
      end
    end
  end
end
