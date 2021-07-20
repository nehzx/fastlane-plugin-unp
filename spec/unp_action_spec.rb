describe Fastlane::Actions::UnpAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The unp plugin is working!")

      Fastlane::Actions::UnpAction.run(nil)
    end
  end
end
