class Mupen64plus < Formula
  desc "Cross-platform plugin-based N64 emulator"
  homepage "https://www.mupen64plus.org/"
  url "https://github.com/mupen64plus/mupen64plus-core/releases/download/2.5/mupen64plus-bundle-src-2.5.tar.gz"
  sha256 "9c75b9d826f2d24666175f723a97369b3a6ee159b307f7cc876bbb4facdbba66"
  license "GPL-2.0-or-later"
  revision 6

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any,                 ventura:      "01f78075888dd30e0afdbeddfd2f88c850ff9bb2b1d3b74a229be82983e1a8d0"
    sha256 cellar: :any,                 monterey:     "a60342d95f8e8636dce8a13eb726c699794ca05e128c9fe851be589773bbe0bb"
    sha256 cellar: :any,                 big_sur:      "688ec0ca8dbeb03395ce9d5059149acd26675274a58f881af48555a264cef8cf"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "9c422712d19f6e8e3a366a9b02e192dda239fc895089184ab884683b3c228aae"
  end

  depends_on "pkg-config" => :build
  depends_on arch: :x86_64
  depends_on "boost"
  depends_on "freetype"
  depends_on "libpng"
  depends_on "sdl2"

  on_linux do
    depends_on "mesa"
    depends_on "mesa-glu"
  end

  resource "rom" do
    url "https://github.com/mupen64plus/mupen64plus-rom/raw/76ef14c876ed036284154444c7bdc29d19381acc/m64p_test_rom.v64"
    sha256 "b5fe9d650a67091c97838386f5102ad94c79232240f9c5bcc72334097d76224c"
  end

  def install
    # Prevent different C++ standard library warning
    inreplace Dir["source/mupen64plus-**/projects/unix/Makefile"],
              /(-mmacosx-version-min)=\d+\.\d+/,
              "\\1=#{MacOS.version}"

    # Fix build with Xcode 9 using upstream commit:
    # https://github.com/mupen64plus/mupen64plus-video-glide64mk2/commit/5ac11270
    # Remove in next version
    inreplace "source/mupen64plus-video-glide64mk2/src/Glide64/3dmath.cpp",
              "__builtin_ia32_storeups", "_mm_storeu_ps"

    if OS.linux?
      ENV.append "CFLAGS", "-fcommon"
      ENV.append "CFLAGS", "-fpie"
    end

    args = ["install", "PREFIX=#{prefix}"]
    args << if OS.mac?
      "INSTALL_STRIP_FLAG=-S"
    else
      "USE_GLES=1"
    end

    cd "source/mupen64plus-core/projects/unix" do
      system "make", *args
    end

    cd "source/mupen64plus-audio-sdl/projects/unix" do
      system "make", *args, "NO_SRC=1", "NO_SPEEX=1"
    end

    cd "source/mupen64plus-input-sdl/projects/unix" do
      system "make", *args
    end

    cd "source/mupen64plus-rsp-hle/projects/unix" do
      system "make", *args
    end

    cd "source/mupen64plus-video-glide64mk2/projects/unix" do
      system "make", *args
    end

    cd "source/mupen64plus-video-rice/projects/unix" do
      system "make", *args
    end

    cd "source/mupen64plus-ui-console/projects/unix" do
      system "make", *args, "PIE=1"
    end
  end

  test do
    # Disable test in Linux CI because it hangs because a display is not available.
    return if OS.linux? && ENV["HOMEBREW_GITHUB_ACTIONS"]

    resource("rom").stage do
      system bin/"mupen64plus", "--testshots", "1",
             "m64p_test_rom.v64"
    end
  end
end
