RSpec.describe(MODSFile) do
  describe "process_mods_file" do
    mods_file = MODSFile.new(File.join(FIXTURES_DIR, "bg730rr6720.xml"), Nokogiri::XML(File.open(TEMPLATE_FILE)), "xmlns")
    it "returns a hash" do
      expect(mods_file.process_mods_file.is_a?(Hash)).to be
    end
    it "extracts attributes" do
      expect(mods_file.process_mods_file).to include("na1:type" => "personal", "na1:usage" => "primary", "na1:authority" => "naf", "na1:valueURI" => "http://id.loc.gov/authorities/names/n79113135")
    end
  end
end
