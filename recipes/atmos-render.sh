# atmos-render (services/atmos-render in AIOStreams) as a static library, for FFmpeg's libatmos
# decoders: on Windows its Atmos objects, which mpv sends to Windows' spatial audio; on Android its
# render for built-in speakers (libatmos_speakers_*), which plays as plain stereo.
cd services/atmos-render
case $platform-$arch in
	windows-x86_64) target=x86_64-pc-windows-gnullvm ;;
	windows-aarch64) target=aarch64-pc-windows-gnullvm ;;
	android-armv7l) target=armv7-linux-androideabi ;;
	android-arm64) target=aarch64-linux-android ;;
	android-x86) target=i686-linux-android ;;
	android-x86_64) target=x86_64-linux-android ;;
	*) echo "atmos-render has no target for $platform $arch" >&2; exit 1 ;;
esac
rustup target add $target
# Rust's own system libraries, which a static library leaves to whoever links it.
native=$(cargo rustc --release --locked --lib --target $target --crate-type staticlib -- \
	-C panic=abort --print native-static-libs 2>&1 | ${SED:-sed} -n 's/.*native-static-libs: //p' | tail -1)
# The unwinder links in: llvm-mingw's libunwind.dll isn't shipped. -static-libgcc has clang link it
# statically (a plain -lunwind, even inside -Bstatic, leaves its driver's own import in place).
[ $platform = windows ] && native=$(echo "$native" | ${SED:-sed} 's/-lunwind/-static-libgcc/')
mkdir -p "$dest/lib/pkgconfig" "$dest/include"
cp target/$target/release/libatmos_render.a "$dest/lib/"
cp include/atmos_objects.h include/atmos_render.h "$dest/include/"
cat >"$dest/lib/pkgconfig/atmos-render.pc" <<PC
prefix=/usr/local
Name: atmos-render
Description: Dolby Atmos objects for spatial audio, and its render for built-in speakers
Version: 0.1.0
Cflags: -I\${prefix}/include
Libs: -L\${prefix}/lib -latmos_render
Libs.private: $native
PC
