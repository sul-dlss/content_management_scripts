RSpec.describe(MODSFile) do
  describe "process_mods_file" do
    mods_file = MODSFile.new(File.join(FIXTURES_DIR, "bg730rr6720.xml"))
    it "returns a hash" do
      expect(mods_file.process_mods_file.is_a?(Hash)).to be
    end
  end
end
