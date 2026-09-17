cask "ai-usage" do
  version "1.0.0"
  sha256 "69de420b610b0beb0126c2471df03f52d4f0ee4a32c3ce14e941665a8a93144e"

  url "https://github.com/sebastian-suarez/ai-usage/releases/download/v#{version}/AI-usage-#{version}.dmg"
  name "AI Usage"
  desc "Menu bar app that shows how much of your Claude and ChatGPT usage limits you've used"
  homepage "https://github.com/sebastian-suarez/ai-usage"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "AI usage.app"

  zap trash: [
    "~/Library/Preferences/dev.sebastiansuarez.AI-usage.plist",
  ]
end
