class Openrct2Cli < Formula
  desc "Open source re-implementation of RollerCoaster Tycoon 2"
  homepage "https://openrct2.io/"
  url "https://github.com/OpenRCT2/OpenRCT2.git",
      tag:      "v0.4.24",
      revision: "8592e6b87708f9082662bb14c3a308e4a338b0c7"
  license "GPL-3.0-only"
  head "https://github.com/OpenRCT2/OpenRCT2.git", branch: "develop"

  bottle do
    root_url "https://ghcr.io/v2/ericfromcanada/adjuncts"
    sha256 cellar: :any, arm64_sequoia: "6f4f5c09bc944cc07512d06057d4c1e1fc312287eac9a2003e8fd1fdc6604abe"
    sha256 cellar: :any, arm64_sonoma:  "eb7feabd6b4fd838db60d992b7c1689f4be7fbedcb4717e67805ad08d6549431"
    sha256               x86_64_linux:  "6f7d730a696a1537e1e089e846a1e43cd94fa8ade9faba8bf0f78a8c7b53887b"
  end

  depends_on "cmake" => :build
  depends_on "nlohmann-json" => :build
  depends_on "pkgconf" => :build

  depends_on "duktape"
  depends_on "flac"
  depends_on "freetype"
  depends_on "icu4c@77"
  depends_on "libogg"
  depends_on "libpng"
  depends_on "libvorbis"
  depends_on "libzip"
  depends_on macos: :sonoma # Needs C++20 features not in Ventura
  depends_on "openssl@3"
  depends_on "sdl2"
  depends_on "speexdsp"

  uses_from_macos "zlib"

  on_linux do
    depends_on "curl"
    depends_on "fontconfig"
    depends_on "mesa"
  end

  resource "title-sequences" do
    url "https://github.com/OpenRCT2/title-sequences/releases/download/v0.4.14/title-sequences.zip"
    sha256 "140df714e806fed411cc49763e7f16b0fcf2a487a57001d1e50fce8f9148a9f3"
  end

  resource "objects" do
    url "https://github.com/OpenRCT2/objects/releases/download/v1.7.1/objects.zip"
    sha256 "679bacb320e0106f4cacfc6619a4b2e322936f55bda8c1447446bc26dbfea193"

    # avoid 1.10 tag in `brew livecheck --formula --autobump -r openrct2` output
    livecheck do
      strategy :github_latest
    end
  end

  resource "openmusic" do
    url "https://github.com/OpenRCT2/OpenMusic/releases/download/v1.6/openmusic.zip"
    sha256 "f097d3a4ccd39f7546f97db3ecb1b8be73648f53b7a7595b86cccbdc1a7557e4"
  end

  resource "opensound" do
    url "https://github.com/OpenRCT2/OpenSoundEffects/releases/download/v1.0.5/opensound.zip"
    sha256 "a952148be164c128e4fd3aea96822e5f051edd9a0b1f2c84de7f7628ce3b2e18"
  end

  def install
    # Avoid letting CMake download things during the build process.
    (buildpath/"data/sequence").install resource("title-sequences")
    (buildpath/"data/object").install resource("objects")
    resource("openmusic").stage do
      (buildpath/"data/assetpack").install Dir["assetpack/*"]
      (buildpath/"data/object/official").install "object/official/music"
    end
    resource("opensound").stage do
      (buildpath/"data/assetpack").install Dir["assetpack/*"]
      (buildpath/"data/object/official").install "object/official/audio"
    end

    args = %w[
      -DWITH_TESTS=OFF
      -DDOWNLOAD_TITLE_SEQUENCES=OFF
      -DDOWNLOAD_OBJECTS=OFF
      -DDOWNLOAD_OPENMSX=OFF
      -DDOWNLOAD_OPENSFX=OFF
      -DMACOS_USE_DEPENDENCIES=OFF
      -DDISABLE_DISCORD_RPC=ON
    ]
    args << "-DCMAKE_OSX_DEPLOYMENT_TARGET=#{MacOS.version}" if OS.mac?

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # By default, the macOS build only looks for data in app bundle Resources.
    libexec.install bin/"openrct2"
    (bin/"openrct2").write_env_script "#{libexec}/openrct2", "--openrct2-data-path=#{pkgshare}", {}
  end

  test do
    assert_match "OpenRCT2, v#{version}", shell_output("#{bin}/openrct2 -v")
  end
end
