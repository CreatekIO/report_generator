require 'spec_helper'

RSpec.describe ReportGenerator::Abstract do
  describe '.registers' do
    let(:dummy_klass) { Class.new(described_class) }

    it 'registers itself with the Factory' do
      dummy_klass.registers :foo_bar

      expect(ReportGenerator::Factory.registered_report_types).to include(
        foo_bar: dummy_klass
      )
    end
  end
end
