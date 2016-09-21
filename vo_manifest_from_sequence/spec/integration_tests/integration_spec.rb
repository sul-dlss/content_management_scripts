require 'spec_helper'
require 'roo'
require 'roo-xls'
require_relative '../../lib/vo_manifest_from_sequence/manifest_sheet'
require_relative '../../lib/vo_manifest_from_sequence/manifest_generator'

describe ManifestGenerator do
  # Checks fixture object output against key
  # Creates test output files in fixtures directory; these will be overwritten
  # each time the test is run
  describe 'generates expected output' do
    key_file_content = File.read(File.join(FIXTURES_DIR, 'test_data_key_manifest.csv'))
    {
      'test_data_xlsx.xlsx' => 'test_data_xlsx_manifest.csv',
      'test_data_xls.xls' => 'test_data_xls_manifest.csv',
      'test_data_csv.csv' => 'test_data_csv_manifest.csv'
    }.each do |test_file, manifest|
      it "should generate correct CSV output for #{test_file}" do
        ManifestGenerator.new(File.join(FIXTURES_DIR, test_file)).generate_manifest
        manifest_content = File.read(File.join(FIXTURES_DIR, manifest))
        expect(manifest_content).to eq(key_file_content)
      end
    end
  end
end
