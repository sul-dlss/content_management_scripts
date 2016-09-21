require 'spec_helper'
require 'roo'
require 'roo-xls'
require_relative '../../lib/vo_manifest_from_sequence/manifest_sheet'

describe ManifestSheet do
  before(:all) do
    @xlsx_filename = File.join(FIXTURES_DIR, 'test_data_xlsx.xlsx')
    @xls_filename = File.join(FIXTURES_DIR, 'test_data_xls.xls')
    @csv_filename = File.join(FIXTURES_DIR, 'test_data_csv.csv')
    @xlsx_file = ManifestSheet.new(@xlsx_filename)
    @xls_file = ManifestSheet.new(@xls_filename)
    @csv_file = ManifestSheet.new(@csv_filename)
    @xlsx_sheet = @xlsx_file.spreadsheet
    @xls_sheet = @xls_file.spreadsheet
    @csv_sheet = @csv_file.spreadsheet
  end
  describe 'instantiate' do
    describe 'initialize' do
      it 'should initialize .xlsx' do
        expect(@xlsx_file).to be_a(ManifestSheet)
      end
      it 'should initialize .xls' do
        expect(@xls_file).to be_a(ManifestSheet)
      end
      it 'should initialize .csv' do
        expect(@csv_file).to be_a(ManifestSheet)
      end
    end
    describe 'filename attribute matches input filename' do
      it 'should have a filename .xlsx' do
        expect(@xlsx_file.filename).to eq(@xlsx_filename)
      end
      it 'should have a filename .xls' do
        expect(@xls_file.filename).to eq(@xls_filename)
      end
      it 'should have a filename.csv' do
        expect(@csv_file.filename).to eq(@csv_filename)
      end
    end
  end
  describe 'generating Roo object' do
    it 'should return a Excelx object for .xlsx input' do
      expect(@xlsx_sheet).to be_a(Roo::Excelx)
    end
    it 'should return a Excel object for .xls input' do
      expect(@xls_sheet).to be_a(Roo::Excel)
    end
    it 'should return a CSV object for .csv input' do
      expect(@csv_sheet).to be_a(Roo::CSV)
    end
    it 'should raise an error for other file extensions' do
      expect { ManifestSheet.new('test_data_txt.txt').spreadsheet }.to raise_error(RuntimeError)
    end
  end
  describe 'validating input data structure' do
    describe 'validation input matches output if sucessful' do
      it 'should return original Excelx input after validation' do
        expect(@xlsx_sheet).to eq(@xlsx_file.validate)
      end
      it 'should return original Excel input after validation' do
        expect(@xls_sheet).to eq(@xls_file.validate)
      end
      it 'should return original CSV input after validation' do
        expect(@csv_sheet).to eq(@csv_file.validate)
      end
    end
    describe 'input data problems raise errors' do
      it 'should identify header errors' do
        header_error_file = File.join(FIXTURES_DIR, 'test_data_header_error.xlsx')
        header_error_sheet = ManifestSheet.new(header_error_file)
        expect { header_error_sheet.validate }.to raise_error(RuntimeError)
      end
      it 'should identify sequence values that cannot be converted to integers' do
        sequence_integer_error_file = File.join(FIXTURES_DIR, 'test_data_sequence_integer_error.csv')
        sequence_integer_error_sheet = ManifestSheet.new(sequence_integer_error_file)
        expect { sequence_integer_error_sheet.validate }.to raise_error(RuntimeError)
      end
      it 'should identify missing values' do
        missing_value_file = File.join(FIXTURES_DIR, 'test_data_missing_value.xlsx')
        missing_value_sheet = ManifestSheet.new(missing_value_file)
        expect { missing_value_sheet.validate }.to raise_error(RuntimeError)
      end
      it 'should identify a missing parent' do
        missing_parent_file = File.join(FIXTURES_DIR, 'test_data_missing_parent.xlsx')
        missing_parent_sheet = ManifestSheet.new(missing_parent_file)
        expect { missing_parent_sheet.validate }.to raise_error(RuntimeError)
      end
      it 'should identify an out-of-order sequence' do
        sequence_order_error_file = File.join(FIXTURES_DIR, 'test_data_sequence_order_error.xlsx')
        sequence_order_error_sheet = ManifestSheet.new(sequence_order_error_file)
        expect { sequence_order_error_sheet.validate }.to raise_error(RuntimeError)
      end
    end
  end
end
