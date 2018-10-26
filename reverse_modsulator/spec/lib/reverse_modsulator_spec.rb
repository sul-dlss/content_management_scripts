
RSpec.describe ReverseModsulator do
  describe "use_correct_namespace" do
    default = ReverseModsulator.new(FIXTURES_DIR, File.join(FIXTURES_DIR, "test.txt"))
    it "uses the default namespace" do
      expect(default.namespace).to eq("xmlns")
    end
    optional = ReverseModsulator.new(FIXTURES_DIR, File.join(FIXTURES_DIR, "test.txt"), {:namespace => "mods"})
    it "uses the provided namespace" do
      expect(optional.namespace).to eq("mods")
    end
  end
end
