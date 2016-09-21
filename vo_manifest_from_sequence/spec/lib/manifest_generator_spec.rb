require 'spec_helper'
require 'roo'
require 'roo-xls'
require_relative '../../lib/vo_manifest_from_sequence/manifest_generator'
require_relative '../../lib/vo_manifest_from_sequence/manifest_sheet'

describe ManifestGenerator do
  before(:all) do
    @xlsx_filename = File.join(FIXTURES_DIR, 'test_data_xlsx.xlsx')
    @xls_filename = File.join(FIXTURES_DIR, 'test_data_xls.xls')
    @csv_filename = File.join(FIXTURES_DIR, 'test_data_csv.csv')
    @xlsx_generator = ManifestGenerator.new(@xlsx_filename)
    @xls_generator = ManifestGenerator.new(@xls_filename)
    @csv_generator = ManifestGenerator.new(@csv_filename)
    @xlsx_file = ManifestSheet.new(@xlsx_filename)
    @xls_file = ManifestSheet.new(@xls_filename)
    @csv_file = ManifestSheet.new(@csv_filename)
  end
  describe 'instantiate' do
    describe 'initialize' do
      it 'should initialize .xlsx' do
        expect(@xlsx_generator).to be_a(ManifestGenerator)
      end
      it 'should initialize .xls' do
        expect(@xls_generator).to be_a(ManifestGenerator)
      end
      it 'should initialize .csv' do
        expect(@csv_generator).to be_a(ManifestGenerator)
      end
    end
    describe 'filename attribute matches input filename' do
      it 'should have a filename .xlsx' do
        expect(@xlsx_generator.filename).to eq(@xlsx_filename)
      end
      it 'should have a filename .xls' do
        expect(@xls_generator.filename).to eq(@xls_filename)
      end
      it 'should have a filename.csv' do
        expect(@csv_generator.filename).to eq(@csv_filename)
      end
    end
  end
  describe 'generate data hash' do
    before(:all) do
      @xlsx_hash = @xlsx_generator.generate_data_hash(@xlsx_file.spreadsheet)
      @xls_hash = @xls_generator.generate_data_hash(@xls_file.spreadsheet)
      @csv_hash = @csv_generator.generate_data_hash(@csv_file.spreadsheet)
    end
    describe 'data hash keys have content' do
      it 'should generate hash keys .xlsx' do
        @xlsx_hash.each_key do |key|
          expect(key.length).not_to eq(0)
        end
      end
      it 'should generate hash keys .xls' do
        @xls_hash.each_key do |key|
          expect(key.length).not_to eq(0)
        end
      end
      it 'should generate hash keys .csv' do
        @csv_hash.each_key do |key|
          expect(key.length).not_to eq(0)
        end
      end
    end
    describe 'data hash values are druids' do
      it 'should generate druid hash values .xlsx' do
        @xlsx_hash.each_value do |value|
          value.each do |druid|
            expect(druid).to match(/^druid:[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}$/)
          end
        end
      end
      it 'should generate druid hash values .xls' do
        @xls_hash.each_value do |value|
          value.each do |druid|
            expect(druid).to match(/^druid:[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}$/)
          end
        end
      end
      it 'should generate druid hash values .csv' do
        @csv_hash.each_value do |value|
          value.each do |druid|
            expect(druid).to match(/^druid:[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}$/)
          end
        end
      end
    end
  end
end
