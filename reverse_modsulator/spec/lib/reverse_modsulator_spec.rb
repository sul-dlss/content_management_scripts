
RSpec.describe ReverseModsulator do
  describe "use_correct_namespace" do
    describe "use_default_namespace" do
      subject = ReverseModsulator.new(FIXTURES_DIR, File.join(FIXTURES_DIR, "test.txt"))
      it "uses the default namespace" do
        expect(subject.namespace).to eq("xmlns")
      end
    end
    describe "use_optional_namespace" do
      subject = ReverseModsulator.new(FIXTURES_DIR, File.join(FIXTURES_DIR, "test.txt"), {:namespace => "mods"})
      it "uses the provided namespace" do
        expect(subject.namespace).to eq("mods")
      end
    end
  end
end
